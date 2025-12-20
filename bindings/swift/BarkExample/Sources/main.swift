import Bark
import Foundation

print("🐕 Bark Wallet Example")
print("======================\n")

let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

do {
    // Create a temporary directory for the wallet data
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("bark_wallet_\(UUID().uuidString)")

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    print("📁 Wallet directory: \(tempDir.path)\n")

    // Configure for Signet (testnet)
    let config = Config(
        serverAddress: "https://ark.signet.2nd.dev",
        esploraAddress: "https://esplora.signet.2nd.dev",
        bitcoindAddress: nil,
        bitcoindCookiefile: nil,
        bitcoindUser: nil,
        bitcoindPass: nil,
        network: .signet,
        vtxoRefreshExpiryThreshold: nil,
        vtxoExitMargin: nil,
        htlcRecvClaimDelta: nil,
        fallbackFeeRate: nil,
        roundTxRequiredConfirmations: nil
    )

    print("🔨 Creating wallet...")
    let wallet = try Wallet.create(
        mnemonic: mnemonic,
        config: config,
        datadir: tempDir.path,
        forceRescan: false
    )

    print("✅ Wallet created successfully!\n")

    // Get wallet properties
    let properties = try wallet.properties()
    print("📋 Wallet Properties:")
    print("   Network: \(properties.network)")
    print("   Fingerprint: \(properties.fingerprint)\n")

    // Generate 5 addresses
    print("🏠 Generating addresses:")
    for i in 1...5 {
        let address = try wallet.newAddress()
        print("   \(i). \(address)")
    }

    print("\n✅ Example completed successfully!")

} catch let error as BarkError {
    print("❌ Bark Error:")
    switch error {
    case .Network(let errorMessage): print("   Network: \(errorMessage)")
    case .Database(let errorMessage): print("   Database: \(errorMessage)")
    case .InvalidMnemonic(let errorMessage): print("   Invalid mnemonic: \(errorMessage)")
    case .InvalidAddress(let errorMessage): print("   Invalid address: \(errorMessage)")
    case .InvalidInvoice(let errorMessage): print("   Invalid invoice: \(errorMessage)")
    case .InsufficientFunds(let errorMessage): print("   Insufficient funds: \(errorMessage)")
    case .NotFound(let errorMessage): print("   Not found: \(errorMessage)")
    case .ServerConnection(let errorMessage): print("   Server connection: \(errorMessage)")
    case .Internal(let errorMessage): print("   Internal: \(errorMessage)")
    }
} catch {
    print("❌ Error: \(error)")
}
