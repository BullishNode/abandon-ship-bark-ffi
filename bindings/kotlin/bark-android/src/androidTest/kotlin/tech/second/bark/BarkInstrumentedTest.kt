package tech.second.bark

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import uniffi.bark.Config
import uniffi.bark.Network
import uniffi.bark.Wallet
import uniffi.bark.generateMnemonic
import uniffi.bark.validateMnemonic
import java.io.File

/**
 * Instrumented tests for Bark Android bindings.
 *
 * These tests run on an Android device or emulator and verify that the
 * native library loads correctly and basic wallet operations work.
 */
@RunWith(AndroidJUnit4::class)
class BarkInstrumentedTest {
    @Test
    fun testGenerateMnemonic() {
        val mnemonic = generateMnemonic()
        assertNotNull("Generated mnemonic should not be null", mnemonic)
        assertTrue("Generated mnemonic should be valid", validateMnemonic(mnemonic))
    }

    @Test
    fun testValidateMnemonic() {
        val validMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        assertTrue("Standard test mnemonic should be valid", validateMnemonic(validMnemonic))

        val invalidMnemonic = "invalid mnemonic phrase"
        assertFalse("Invalid mnemonic should fail validation", validateMnemonic(invalidMnemonic))
    }

    @Test
    fun testCreateWallet() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val dataDir = File(context.cacheDir, "test_wallet_${System.currentTimeMillis()}")
        dataDir.mkdirs()

        try {
            val config =
                Config(
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
                    roundTxRequiredConfirmations = null,
                )

            val wallet =
                Wallet.create(
                    mnemonic = generateMnemonic(),
                    config = config,
                    datadir = dataDir.absolutePath,
                    forceRescan = false,
                )

            assertNotNull("Wallet should be created successfully", wallet)

            // Test wallet properties
            val properties = wallet.properties()
            assertNotNull("Wallet properties should not be null", properties)
            assertTrue("Wallet fingerprint should not be empty", properties.fingerprint.isNotEmpty())

            // Test address generation
            val address = wallet.newAddress()
            assertNotNull("Generated address should not be null", address)
            assertTrue("Generated address should not be empty", address.isNotEmpty())
        } finally {
            // Clean up test data
            dataDir.deleteRecursively()
        }
    }

    @Test
    fun testOpenWallet() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val dataDir = File(context.cacheDir, "test_wallet_open_${System.currentTimeMillis()}")
        dataDir.mkdirs()
        val mnemonic = generateMnemonic()

        try {
            val config =
                Config(
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
                    roundTxRequiredConfirmations = null,
                )

            // Create wallet first
            val wallet1 =
                Wallet.create(
                    mnemonic = mnemonic,
                    config = config,
                    datadir = dataDir.absolutePath,
                    forceRescan = false,
                )
            assertNotNull("First wallet should be created", wallet1)

            // Open existing wallet
            val wallet2 =
                Wallet.open(
                    mnemonic = mnemonic,
                    config = config,
                    datadir = dataDir.absolutePath,
                )
            assertNotNull("Wallet should be opened successfully", wallet2)

            // Both wallets should have same fingerprint
            val props1 = wallet1.properties()
            val props2 = wallet2.properties()
            assertTrue(
                "Opened wallet should have same fingerprint as created wallet",
                props1.fingerprint == props2.fingerprint,
            )
        } finally {
            // Clean up test data
            dataDir.deleteRecursively()
        }
    }
}
