import 'dart:io';
import 'package:bark/bark.dart';
import 'package:path/path.dart' as path;

Future<void> basicExample() async {
  print("\n=== Basic Bark Wallet Example ===\n");

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

  late final Wallet wallet;
  if (!dataDir.existsSync()) {
    print('Creating new wallet...');
    dataDir.createSync(recursive: true);
    wallet = await Wallet.create(mnemonic, config, dataDir.path, false);
  } else {
    print('Loading existing wallet...');
    wallet = await Wallet.open(mnemonic, config, dataDir.path);
  }

  final address = await wallet.newAddress();
  print("Address: $address");

  final props = wallet.properties();
  print("Fingerprint: ${props.fingerprint}");
  print("Network: ${props.network}");

  print("\nSyncing...");
  await wallet.sync();
  await wallet.maintenance();

  final balance = wallet.balance();
  print("\nBalance:");
  print("  Spendable: ${balance.spendableSats} sats");
  print("  Pending board: ${balance.pendingBoardSats} sats");

  final uVtxos = wallet.vtxos();
  print("\n Unspent VTXOs: ${uVtxos.length}");
  for (var vtxo in uVtxos) {
    print("  ${vtxo.id}: ${vtxo.amountSats} sats (${vtxo.state})");
  }

  final allVtxos = wallet.allVtxos();
  print("\n All VTXOs: ${allVtxos.length}");
  for (final vtxo in allVtxos) {
    print("VTXO ${vtxo.id}:");
    print("  Amount: ${vtxo.amountSats} sats");
    print("  Expiry: block ${vtxo.expiryHeight}");
    print("  Kind: ${vtxo.kind}");
    print("  State: ${vtxo.state}");
  }

  try {
    final invoice = await wallet.bolt11Invoice(10000);
    print("\nBOLT11 invoice (10k sats):");
    print("  ${invoice.invoice}");
  } catch (e) {
    print("\nCould not generate invoice: $e");
  }
}
