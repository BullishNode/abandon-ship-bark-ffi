package tech.second.bark.example

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.second.bark.example.databinding.ActivityMainBinding
import uniffi.bark.*
import java.io.File

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Run wallet example in coroutine
        lifecycleScope.launch {
            val output = runWalletExample()
            binding.outputText.text = output
        }
    }

    private suspend fun runWalletExample(): String = withContext(Dispatchers.IO) {
        val output = StringBuilder()

        try {
            output.appendLine("🐕 Bark Wallet Example")
            output.appendLine("======================\n")

            // Use standard test mnemonic
            val mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

            // Create a temporary directory for wallet data
            val walletDir = File(applicationContext.filesDir, "bark_wallet_${System.currentTimeMillis()}")
            walletDir.mkdirs()

            output.appendLine("📁 Wallet directory: ${walletDir.absolutePath}\n")

            // Configure for Signet (testnet)
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

            output.appendLine("🔨 Creating wallet...")
            val wallet = Wallet.create(
                mnemonic = mnemonic,
                config = config,
                datadir = walletDir.absolutePath,
                forceRescan = false
            )

            output.appendLine("✅ Wallet created successfully!\n")

            // Get wallet properties
            val properties = wallet.properties()
            output.appendLine("📋 Wallet Properties:")
            output.appendLine("   Network: ${properties.network}")
            output.appendLine("   Fingerprint: ${properties.fingerprint}\n")

            // Generate 5 addresses
            output.appendLine("🏠 Generating addresses:")
            for (i in 1..5) {
                val address = wallet.newAddress()
                output.appendLine("   $i. $address")
            }

            output.appendLine("\n✅ Example completed successfully!")

        } catch (e: BarkException) {
            output.appendLine("❌ Bark Error:")
            when (e) {
                is BarkException.Network -> output.appendLine("   Network: ${e.errorMessage}")
                is BarkException.Database -> output.appendLine("   Database: ${e.errorMessage}")
                is BarkException.InvalidMnemonic -> output.appendLine("   Invalid mnemonic: ${e.errorMessage}")
                is BarkException.InvalidAddress -> output.appendLine("   Invalid address: ${e.errorMessage}")
                is BarkException.InvalidInvoice -> output.appendLine("   Invalid invoice: ${e.errorMessage}")
                is BarkException.InsufficientFunds -> output.appendLine("   Insufficient funds: ${e.errorMessage}")
                is BarkException.NotFound -> output.appendLine("   Not found: ${e.errorMessage}")
                is BarkException.ServerConnection -> output.appendLine("   Server connection: ${e.errorMessage}")
                is BarkException.Internal -> output.appendLine("   Internal: ${e.errorMessage}")
            }
        } catch (e: Exception) {
            output.appendLine("❌ Error: ${e.message}")
            e.printStackTrace()
        }

        return@withContext output.toString()
    }
}
