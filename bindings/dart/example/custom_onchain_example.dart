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
      0,
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
    throw Exception("TODO: Implement CPFP");
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

  if (balance.totalSats > 0) {
    print("\nBoarding ${balance.totalSats} sats...");
    try {
      final pendingBoard = await wallet.boardAll(onchainWallet);
      print("Board initiated:");
      print("  VTXO ID: ${pendingBoard.vtxoId}");
      print("  Amount: ${pendingBoard.amountSats} sats");
      print("  Txid: ${pendingBoard.txid}");
    } catch (e) {
      print("Board failed: $e");
    }
  } else {
    print("\nNo onchain funds. Send sats to: $address");
  }
}
