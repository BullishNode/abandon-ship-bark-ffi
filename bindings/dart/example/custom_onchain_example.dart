import 'dart:io';
import 'dart:typed_data';
import 'package:bark/bark.dart';
import 'package:bdk_dart/bdk.dart' as bdk;
import 'package:path/path.dart' as path;

// Implementation of the Callbacks interface needed to use an own custom onchain
// wallet with Bark. This one uses bdk_dart to implement the required methods.
class BdkCustomWallet implements CustomOnchainWalletCallbacks {
  final bdk.Wallet _wallet;
  final bdk.EsploraClient _esploraClient;

  BdkCustomWallet._(this._wallet, this._esploraClient);

  static Future<BdkCustomWallet> create(
    String mnemonic,
    Network network,
    String esploraUrl,
    String dataDir,
  ) async {
    final bdkNetwork = switch (network) {
      Network.bitcoin => bdk.Network.bitcoin,
      Network.testnet => bdk.Network.testnet,
      Network.signet => bdk.Network.signet,
      Network.regtest => bdk.Network.regtest,
    };

    final mnemonicObj = await bdk.Mnemonic.fromString(mnemonic);
    final descriptorSecretKey = await bdk.DescriptorSecretKey(
      bdkNetwork,
      mnemonicObj,
      null,
    );

    final descriptor = await bdk.Descriptor.newBip84(
      descriptorSecretKey,
      bdk.KeychainKind.external_,
      bdkNetwork,
    );

    final changeDescriptor = await bdk.Descriptor.newBip84(
      descriptorSecretKey,
      bdk.KeychainKind.internal,
      bdkNetwork,
    );

    final wallet = await bdk.Wallet(
      descriptor,
      changeDescriptor,
      bdkNetwork,
      bdk.Persister.newInMemory(),
      25,
    );

    final esploraClient = bdk.EsploraClient(esploraUrl, null);

    return BdkCustomWallet._(wallet, esploraClient);
  }

  @override
  int getBalance() {
    final balance = _wallet.balance();
    return balance.total.toSat();
  }

  @override
  String prepareTx(List<Destination> destinations, int feeRateSatPerVb) {
    final txBuilder = bdk.TxBuilder();

    for (final dest in destinations) {
      txBuilder.addRecipient(
        bdk.Address(dest.address, _wallet.network()).scriptPubkey(),
        bdk.Amount.fromSat(dest.amountSats),
      );
    }

    txBuilder.feeRate(bdk.FeeRate.fromSatPerVb(feeRateSatPerVb));

    final psbt = txBuilder.finish(_wallet);

    return psbt.toString();
  }

  @override
  String prepareDrainTx(String address, int feeRateSatPerVb) {
    final addr = bdk.Address(address, _wallet.network());
    final scriptPubkey = addr.scriptPubkey();

    final psbt = bdk.TxBuilder()
        .feeRate(bdk.FeeRate.fromSatPerVb(feeRateSatPerVb))
        .drainWallet()
        .drainTo(scriptPubkey)
        .finish(_wallet);

    return psbt.serialize();
  }

  @override
  String finishTx(String psbtBase64) {
    final psbt = bdk.Psbt(psbtBase64);

    final finalized = _wallet.sign(psbt, null);

    if (!finalized) {
      throw Exception("Failed to finalize PSBT");
    }

    final tx = psbt.extractTx();
    final txBytes = tx.serialize();

    return txBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  String? getWalletTx(String txid) {
    try {
      final tx = _wallet.getTx(bdk.Txid.fromString(txid));
      if (tx == null) return null;

      final txBytes = tx.transaction.serialize();
      return txBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      return null;
    }
  }

  @override
  BlockRef? getWalletTxConfirmedBlock(String txid) {
    try {
      final tx = _wallet.getTx(bdk.Txid.fromString(txid));
      if (tx == null) {
        return null;
      }

      final chainPosition = tx.chainPosition;
      if (chainPosition is bdk.ConfirmedChainPosition) {
        final blockTime = chainPosition.confirmationBlockTime;
        return BlockRef(
          blockTime.blockId.height,
          blockTime.blockId.hash.toString(),
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  String? getSpendingTx(OutPoint outpoint) {
    try {
      final transactions = _wallet.transactions();
      final targetOutpoint = bdk.OutPoint(
        bdk.Txid.fromString(outpoint.txid),
        outpoint.vout,
      );

      for (final txDetails in transactions) {
        final tx = txDetails.transaction;

        final inputs = tx.input();
        for (final input in inputs) {
          final prevOut = input.previousOutput;
          if (prevOut.txid.toString() == targetOutpoint.txid.toString() &&
              prevOut.vout == targetOutpoint.vout) {
            final txBytes = tx.serialize();
            return txBytes
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join();
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  String makeSignedP2aCpfp(CpfpParams params) {
    // Parse the P2A transaction from hex
    final txBytes = Uint8List.fromList([
      for (var i = 0; i < params.txHex.length; i += 2)
        int.parse(params.txHex.substring(i, i + 2), radix: 16),
    ]);
    final p2aTx = bdk.Transaction(txBytes);

    // Extract the fee anchor output (P2A output)
    final feeAnchor = _extractFeeAnchor(p2aTx);
    if (feeAnchor == null) {
      throw Exception("No fee anchor found in transaction");
    }

    // Get change address for drain output
    final changeAddr = _wallet.revealNextAddress(bdk.KeychainKind.external_);

    // Calculate P2A transaction weight
    final p2aWeight = p2aTx.weight();

    // Iterative loop to calculate correct fees (matching Rust implementation)
    var spendWeight = 0;
    var feeNeeded = p2aWeight * params.effectiveFeeRateSatPerVb;

    const maxIterations = 100;
    for (var i = 0; i < maxIterations; i++) {
      try {
        final txBuilder = bdk.TxBuilder()
            .onlyWitnessUtxo()
            .excludeUnconfirmed()
            .version(3) // For 1p1c package relay
            .addForeignUtxo(
              feeAnchor.outpoint,
              feeAnchor.input,
              1, // FEE_ANCHOR_SPEND_WEIGHT = 1 WU
            )
            .drainTo(changeAddr.address.scriptPubkey())
            .feeAbsolute(bdk.Amount.fromSat(feeNeeded));

        var psbt = txBuilder.finish(_wallet);

        // Sign the PSBT with witness-only signing (required for P2A foreign UTXO)
        final signOptions = bdk.SignOptions(
          true, // trustWitnessUtxo
          null, // assumeHeight
          false, // allowAllSighashes
          true, // tryFinalize
          true, // signWithTapInternalKey
          false, // allowGrinding
        );
        final finalized = _wallet.sign(psbt, signOptions);
        if (!finalized) {
          throw Exception("Failed to finalize PSBT");
        }

        final tx = psbt.extractTx();
        final txWeight = tx.weight();
        final totalWeight = txWeight + p2aWeight;

        // Check if weight changed - if so, recalculate fees
        if (txWeight != spendWeight) {
          _wallet.cancelTx(tx);
          spendWeight = txWeight;

          // Recalculate fee based on total package weight
          if (params.feesType == "Effective") {
            feeNeeded = totalWeight * params.effectiveFeeRateSatPerVb;
          } else if (params.feesType == "Rbf") {
            // RBF fee calculation
            final minTxRelayFee = 1; // 1 sat/vb
            final currentPackageFee = params.currentPackageFeeSats ?? 0;

            final minPackageFee =
                currentPackageFee +
                (p2aWeight * minTxRelayFee) +
                (txWeight * minTxRelayFee);

            final desiredFee = totalWeight * params.effectiveFeeRateSatPerVb;

            feeNeeded = desiredFee < minPackageFee ? minPackageFee : desiredFee;
          }
          continue; // Try again with new fee
        }

        // Success! Return hex-encoded transaction
        final txBytes = tx.serialize();
        return txBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      } catch (e) {
        // Don't retry on insufficient funds - it won't get better
        if (e.toString().contains("Insufficient funds") ||
            e.toString().contains("CoinSelection")) {
          rethrow;
        }

        if (i == maxIterations - 1) {
          rethrow;
        }
        // Continue loop on other errors (like weight mismatches)
      }
    }

    throw Exception("Reached max iterations (100) in CPFP calculation");
  }

  ({bdk.OutPoint outpoint, bdk.Input input})? _extractFeeAnchor(
    bdk.Transaction tx,
  ) {
    // P2A script is OP_1 followed by 0x4e73 (Bitcoin's standard P2A script)
    final p2aScriptBytes = Uint8List.fromList([0x51, 0x02, 0x4e, 0x73]);

    final outputs = tx.output();
    for (var i = 0; i < outputs.length; i++) {
      final output = outputs[i];
      final scriptBytes = output.scriptPubkey.toBytes();

      // Check if this is the P2A fee anchor
      if (scriptBytes.length == p2aScriptBytes.length) {
        var isP2A = true;
        for (var j = 0; j < scriptBytes.length; j++) {
          if (scriptBytes[j] != p2aScriptBytes[j]) {
            isP2A = false;
            break;
          }
        }

        if (isP2A) {
          // Found the P2A fee anchor
          final outpoint = bdk.OutPoint(tx.computeTxid(), i);

          // Create PSBT input for the fee anchor (matching Rust implementation)
          // witness_utxo = Some(output), final_script_witness = Some(Witness::new())
          final input = bdk.Input(
            null, // nonWitnessUtxo
            output, // witnessUtxo
            {}, // partialSigs
            null, // sighashType
            null, // redeemScript
            null, // witnessScript
            {}, // bip32Derivation
            null, // finalScriptSig
            [], // finalScriptWitness (empty witness)
            {}, // ripemd160Preimages
            {}, // sha256Preimages
            {}, // hash160Preimages
            {}, // hash256Preimages
            null, // tapKeySig
            {}, // tapScriptSigs
            {}, // tapScripts
            {}, // tapKeyOrigins
            null, // tapInternalKey
            null, // tapMerkleRoot
            {}, // proprietary
            {}, // unknown
          );

          return (outpoint: outpoint, input: input);
        }
      }
    }

    return null;
  }

  @override
  void storeSignedP2aCpfp(String txHex) {
    try {
      final txBytes = Uint8List.fromList([
        for (var i = 0; i < txHex.length; i += 2)
          int.parse(txHex.substring(i, i + 2), radix: 16),
      ]);

      final tx = bdk.Transaction(txBytes);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _wallet.applyUnconfirmedTxs([bdk.UnconfirmedTx(tx, now)]);
    } catch (e) {
      print("Failed to store CPFP transaction: $e");
    }
  }

  // Not needed for Bark integration but required for the example code.
  Future<void> sync() async {
    final fullScanRequest = await _wallet.startFullScan();
    final update = await _esploraClient.fullScan(
      fullScanRequest.build(),
      20,
      1,
    );
    _wallet.applyUpdate(update);
  }

  // Not needed for Bark integration but required for the example code.
  String get newAddress {
    final address = _wallet.nextUnusedAddress(bdk.KeychainKind.external_);
    return address.address.toString();
  }

  String broadcastPsbt(String psbtBase64) {
    final psbt = bdk.Psbt(psbtBase64);
    final tx = psbt.extractTx();

    _esploraClient.broadcast(tx);

    return tx.computeTxid().toString();
  }
}

Future<void> customOnchainExample() async {
  print("\n=== Custom Onchain Wallet Example (Segwit/BIP84) ===\n");

  final mnemonic =
      "input define cigar dizzy void east height sunny orient clean favorite cram";

  final config = Config(
    "https://ark.signet.2nd.dev",
    "https://esplora.signet.2nd.dev",
    null,
    null,
    null,
    null,
    Network.signet,
    null,
    null,
    null,
    null,
    null,
  );

  final scriptPath = path.dirname(Platform.script.toFilePath());
  final dataDir = Directory(path.join(scriptPath, 'bark_db'));

  final customWallet = await BdkCustomWallet.create(
    mnemonic,
    config.network,
    config.esploraAddress ?? "https://esplora.signet.2nd.dev",
    dataDir.path,
  );

  final onchainWallet = OnchainWallet.custom(customWallet);

  print("Syncing custom wallet...");
  await customWallet.sync();

  final balance = onchainWallet.balance();
  print("Onchain balance: ${balance.totalSats} sats");

  final address = customWallet.newAddress;
  print("Onchain address (BIP84): $address");

  final wallet = await Wallet.openWithOnchain(
    mnemonic,
    config,
    dataDir.path,
    onchainWallet,
  );

  final props = wallet.properties();
  print("Bark wallet fingerprint: ${props.fingerprint}");

  // Test unilateral exit with custom onchain wallet
  print("\n--- Testing Unilateral Exit ---");

  await wallet.sync();
  final barkBalance = wallet.balance();

  if (barkBalance.spendableSats > 0) {
    print("Spendable balance: ${barkBalance.spendableSats} sats");
    print("\nStarting unilateral exit for entire wallet...");

    try {
      await wallet.startExitForEntireWallet();
      print("Exit initiated successfully");

      final updatedBalance = wallet.balance();
      print("Pending exit: ${updatedBalance.pendingExitSats} sats");
    } catch (e) {
      print("Exit failed: $e");
    }
  }

  // Check if we have any pending exits
  if (barkBalance.pendingExitSats > 0 || wallet.hasPendingExits()) {
    print("\n--- Progressing Exits ---");

    final hasPending = wallet.hasPendingExits();
    final pendingTotal = wallet.pendingExitsTotalSats();
    print("Has pending exits: $hasPending");
    print("Pending exits total: $pendingTotal sats");

    // Get all exit VTXOs
    final exitVtxos = wallet.getExitVtxos();
    print("\nExit VTXOs (${exitVtxos.length}):");
    for (final exitVtxo in exitVtxos) {
      print("  • ${exitVtxo.vtxoId}");
      print("    Amount: ${exitVtxo.amountSats} sats");
      print("    State: ${exitVtxo.state}");
      print("    Claimable: ${exitVtxo.isClaimable}");
    }

    // Get detailed exit status for each exit BEFORE progressing
    print("\n--- Detailed Exit Status (Before Progress) ---");
    for (final exitVtxo in exitVtxos) {
      try {
        final exitStatus = await wallet.getExitStatus(
          exitVtxo.vtxoId,
          true, // include history
          true, // include transactions
        );

        if (exitStatus != null) {
          print("\nExit Status for ${exitStatus.vtxoId}:");
          print("   Current State: ${exitStatus.state}");
          print("   Transaction Count: ${exitStatus.transactionCount}");

          if (exitStatus.history != null && exitStatus.history!.isNotEmpty) {
            print("   State History:");
            for (final historyState in exitStatus.history!) {
              print("     - $historyState");
            }
          }
        }
      } catch (e) {
        print("Failed to get exit status for ${exitVtxo.vtxoId}: $e");
      }
    }

    // Progress the exits (broadcast txs, fee bump, advance state machine)
    print("\nProgressing exits...");
    try {
      final progressStatuses = await wallet.progressExits(onchainWallet, null);
      print("Exit progress completed (${progressStatuses.length} exits):");

      for (final status in progressStatuses) {
        print("  • ${status.vtxoId}");
        print("    State: ${status.state}");
        if (status.error != null) {
          print("    Error: ${status.error}");
        }
      }
    } catch (e) {
      print("Progress exits failed: $e");
    }

    // Check if any exits are claimable
    print("\n--- Checking Claimable Exits ---");
    final claimableExits = wallet.listClaimableExits();

    if (claimableExits.isNotEmpty) {
      print("Found ${claimableExits.length} claimable exit(s):");

      for (final exit in claimableExits) {
        print("  • ${exit.vtxoId}");
        print("    Amount: ${exit.amountSats} sats");
        print("    State: ${exit.state}");
      }

      // Get when all exits will be claimable
      final claimableAtHeight = wallet.allExitsClaimableAtHeight();
      if (claimableAtHeight != null) {
        print("\nAll exits claimable at block height: $claimableAtHeight");
      }

      // Drain the exits to onchain wallet
      print("\nDraining exits to onchain wallet...");
      try {
        final drainAddress = customWallet.newAddress;
        print("Drain address: $drainAddress");

        // Drain all claimable exits (empty list = drain all)
        final claimTx = await wallet.drainExits(
          [], // empty = drain all claimable
          drainAddress,
          null, // use automatic fee rate
        );

        print("Drain transaction created:");
        print("  Fee: ${claimTx.feeSats} sats");
        print("  PSBT (base64): ${claimTx.psbtBase64.substring(0, 64)}...");
        print("\nTo complete the exit, broadcast this PSBT");
        print("  The funds will be sent to: $drainAddress");
        final txId = customWallet.broadcastPsbt(claimTx.psbtBase64);
        print("  PSBT broadcasted successfully with txid: $txId");
      } catch (e) {
        print("Drain exits failed: $e");
      }
    } else {
      print("No exits are claimable yet");
      print(
        "Exits need to be confirmed onchain and wait for the exit delta period",
      );

      // Show when exits will be claimable
      final claimableAtHeight = wallet.allExitsClaimableAtHeight();
      if (claimableAtHeight != null) {
        print(
          "All exits will be claimable at block height: $claimableAtHeight",
        );
      }
    }

    // Sync exits one more time to update state
    print("\nSyncing exit state...");
    try {
      await wallet.syncExits(onchainWallet);
      print("Exit status synced");

      final finalBalance = wallet.balance();
      print("Final pending exit: ${finalBalance.pendingExitSats} sats");
    } catch (e) {
      print("Exit sync failed: $e");
    }
  } else {
    print("\nNo balance to exit and no pending exits");
  }
}
