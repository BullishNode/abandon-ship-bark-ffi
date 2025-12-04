import 'dart:io';
import 'package:bark/bark.dart';
import 'package:path/path.dart' as path;

void main() async {
  try {
    await example();
  } catch (e, stackTrace) {
    print('=== ERROR ===');
    print('Error: $e');
    print('Type: ${e.runtimeType}');
    print('Stack trace: $stackTrace');
  }
}

Future<void> example() async {
  // DO NOT SEND REAL FUNDS TO THIS MNEMONIC
  final mnemonic =
      "input define cigar dizzy void east height sunny orient clean favorite cram";
  // To generate a new random mnemonic in a real application,
  // use the following line instead:
  // final mnemonic = BarkUtils.generateMnemonic();

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

  // Create db data directory in the example folder, relative to this script
  final scriptPath = path.dirname(Platform.script.toFilePath());
  final dataDir = Directory(path.join(scriptPath, 'bark_db'));
  late final Wallet wallet;
  if (!dataDir.existsSync()) {
    print('No existing data directory found. Creating new wallet...');
    dataDir.createSync(recursive: true);
    wallet = await Wallet.create(mnemonic, config, dataDir.path, false);
    print("✅ Wallet created successfully!");
  } else {
    print('Existing data directory found. Loading wallet...');
    wallet = await Wallet.open(mnemonic, config, dataDir.path);
  }

  final address = wallet.newAddress();
  print("📬 New Ark address: $address");

  final props = wallet.properties();
  print("🔑 Wallet fingerprint: ${props.fingerprint}");
  print("🌐 Network: ${props.network}");

  // Sync with the server to fetch latest transactions
  print("\n🔄 Syncing with server...");
  try {
    await wallet.sync();
    print("✅ Sync complete!");
  } catch (e) {
    print("⚠️  Sync failed: $e");
  }

  // Run maintenance (full refresh including VTXO refresh)
  print("\n🔧 Running maintenance...");
  try {
    await wallet.maintenance();
    print("✅ Maintenance complete!");
  } catch (e) {
    print("⚠️  Maintenance failed: $e");
  }

  final balance = wallet.balance();
  print("\n💰 Balance:");
  print("  Spendable: ${balance.spendableSats} sats");
  print("  Pending in round: ${balance.pendingInRoundSats} sats");
  print("  Pending exit: ${balance.pendingExitSats} sats");
  print("  Pending Lightning send: ${balance.pendingLightningSendSats} sats");
  print(
    "  Pending Lightning receive (total): ${balance.pendingLightningReceiveTotalSats} sats",
  );
  print(
    "  Pending Lightning receive (claimable): ${balance.pendingLightningReceiveClaimableSats} sats",
  );
  print("  Pending board: ${balance.pendingBoardSats} sats");

  // Check VTXOs
  final vtxos = wallet.vtxos();
  print("\n📦 VTXOs: ${vtxos.length}");
  for (var vtxo in vtxos) {
    print(
      "  - ${vtxo.id}: ${vtxo.amountSats} sats (${vtxo.state}, ${vtxo.kind}), expires at block ${vtxo.expiryHeight}",
    );
  }

  // Try to generate a Lightning invoice (requires server connection)
  try {
    final invoice = await wallet.bolt11Invoice(10000);
    print("\n🧾 Generated BOLT11 invoice for 10,000 sats:");
    print("   ${invoice.invoice}");
  } catch (e) {
    print("\n⚠️  Could not generate invoice: ${e}");
  }
}
