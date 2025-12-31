import 'dart:io';
import 'package:bark/bark.dart';
import 'package:path/path.dart' as path;

Future<void> defaultOnchainExample() async {
  print("\n=== Default Onchain Wallet Example (Taproot/BIP86) ===\n");

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

  final onchainWallet = OnchainWallet.default_(mnemonic, config, dataDir.path);

  print("Syncing onchain wallet...");
  await onchainWallet.sync();

  final balance = onchainWallet.balance();
  print("Onchain balance: ${balance.totalSats} sats");
  print("  Confirmed: ${balance.confirmedSats} sats");

  final address = await onchainWallet.newAddress();
  print("Onchain address: $address");

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
