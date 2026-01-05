import uniffi.bark.*
import java.nio.file.Paths
import kotlin.system.exitProcess

/**
 * Simple CLI example for Bark JVM bindings.
 *
 * This demonstrates basic wallet operations on desktop/server JVM environments.
 */
fun main() {
    println("🐕 Bark Wallet - JVM CLI Example")
    println("=================================\n")

    try {
        // Generate a new mnemonic
        println("📝 Generating new mnemonic...")
        val mnemonic = generateMnemonic()
        println("Mnemonic: $mnemonic")
        println("⚠️  Save this mnemonic securely! It's needed to recover your wallet.\n")

        // Validate the mnemonic
        val isValid = validateMnemonic(mnemonic)
        println("✅ Mnemonic validation: ${if (isValid) "VALID" else "INVALID"}\n")

        // Configure wallet for Signet testnet
        println("🔧 Configuring wallet for Signet testnet...")
        val config = Config(
            serverAddress = "https://ark.signet.2nd.dev",
            esploraAddress = "https://esplora.signet.2nd.dev",
            bitcoindAddress = null,
            bitcoindCookiefile = null,
            bitcoindUser = null,
            bitcoindPass = null,
            network = Network.SIGNET,
            vtxoRefreshExpiryThreshold = null,
            vtxoExitMargin = null,
            htlcRecvClaimDelta = null,
            fallbackFeeRate = null,
            roundTxRequiredConfirmations = null
        )

        // Set wallet data directory
        val dataDir = Paths.get(
            System.getProperty("user.home"),
            ".bark",
            "jvm_example_${System.currentTimeMillis()}"
        )

        // Create the directory
        java.io.File(dataDir.toString()).mkdirs()
        println("📁 Wallet data directory: $dataDir\n")

        // Create wallet
        println("🔨 Creating wallet...")
        val wallet = Wallet.create(
            mnemonic = mnemonic,
            config = config,
            datadir = dataDir.toString(),
            forceRescan = false
        )
        println("✅ Wallet created successfully!\n")

        // Get wallet properties
        val properties = wallet.properties()
        println("📋 Wallet Properties:")
        println("   Network: ${properties.network}")
        println("   Fingerprint: ${properties.fingerprint}\n")

        // Generate receiving addresses
        println("🏠 Generating 5 receiving addresses:")
        repeat(5) { index ->
            val address = wallet.newAddress()
            println("   ${index + 1}. $address")
        }

        println("\n💡 Tips:")
        println("   - Send Signet testnet BTC to any of the addresses above")
        println("   - Use a bark-supporting Signet faucet: https://signet.2nd.dev/")
        println("   - After receiving funds, you can use wallet.sync() and wallet.balance()")
        println("   - See the Bark documentation for more examples: https://docs.second.tech\n")

        println("✅ Example completed successfully!")

    } catch (e: BarkException) {
        System.err.println("\n❌ Bark Error occurred:")
        when (e) {
            is BarkException.Network -> System.err.println("   Network error: ${e.errorMessage}")
            is BarkException.Database -> System.err.println("   Database error: ${e.errorMessage}")
            is BarkException.InvalidMnemonic -> System.err.println("   Invalid mnemonic: ${e.errorMessage}")
            is BarkException.InvalidAddress -> System.err.println("   Invalid address: ${e.errorMessage}")
            is BarkException.InvalidInvoice -> System.err.println("   Invalid invoice: ${e.errorMessage}")
            is BarkException.InsufficientFunds -> System.err.println("   Insufficient funds: ${e.errorMessage}")
            is BarkException.NotFound -> System.err.println("   Not found: ${e.errorMessage}")
            is BarkException.ServerConnection -> System.err.println("   Server connection: ${e.errorMessage}")
            is BarkException.Internal -> System.err.println("   Internal error: ${e.errorMessage}")
            is BarkException.OnchainWalletRequired -> System.err.println("   Onchain wallet required: ${e.errorMessage}")
        }
        exitProcess(1)
    } catch (e: Exception) {
        System.err.println("\n❌ Unexpected error: ${e.message}")
        e.printStackTrace()
        exitProcess(1)
    }
}
