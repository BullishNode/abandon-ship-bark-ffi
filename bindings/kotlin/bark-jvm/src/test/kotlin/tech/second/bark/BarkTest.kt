package tech.second.bark

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import uniffi.bark.Config
import uniffi.bark.Network
import uniffi.bark.Wallet
import uniffi.bark.generateMnemonic
import uniffi.bark.validateArkAddress
import uniffi.bark.validateMnemonic
import java.nio.file.Path

/**
 * Unit tests for Bark JVM bindings.
 *
 * These tests verify that the native library loads correctly on JVM
 * and basic wallet operations work.
 */
class BarkTest {
    @Test
    fun `test generate mnemonic`() {
        val mnemonic = generateMnemonic()
        assertNotNull(mnemonic, "Generated mnemonic should not be null")
        assertTrue(validateMnemonic(mnemonic), "Generated mnemonic should be valid")
    }

    @Test
    fun `test validate mnemonic with valid phrase`() {
        val validMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        assertTrue(validateMnemonic(validMnemonic), "Standard test mnemonic should be valid")
    }

    @Test
    fun `test validate mnemonic with invalid phrase`() {
        val invalidMnemonic = "invalid mnemonic phrase"
        assertFalse(validateMnemonic(invalidMnemonic), "Invalid mnemonic should fail validation")
    }

    @Test
    fun `test validate mnemonic with empty string`() {
        assertFalse(validateMnemonic(""), "Empty mnemonic should fail validation")
    }

    @Test
    fun `test validate ark address with invalid address`() {
        assertFalse(validateArkAddress("invalid"), "Invalid address should fail validation")
        assertFalse(validateArkAddress(""), "Empty address should fail validation")
        assertFalse(validateArkAddress("bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"), "Bitcoin address should fail Ark validation")
    }

    @Test
    fun `test create wallet`(
        @TempDir tempDir: Path,
    ) {
        val dataDir = tempDir.resolve("wallet_${System.currentTimeMillis()}")
        dataDir.toFile().mkdirs()

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
                datadir = dataDir.toString(),
                forceRescan = false,
            )

        assertNotNull(wallet, "Wallet should be created successfully")

        // Test wallet properties
        val properties = wallet.properties()
        assertNotNull(properties, "Wallet properties should not be null")
        assertTrue(properties.fingerprint.isNotEmpty(), "Wallet fingerprint should not be empty")

        // Test address generation
        val address = wallet.newAddress()
        assertNotNull(address, "Generated address should not be null")
        assertTrue(address.isNotEmpty(), "Generated address should not be empty")
        assertTrue(address.startsWith("tark1"), "Generated address should start with 'tark1' for Signet")
    }

    @Test
    fun `test open existing wallet`(
        @TempDir tempDir: Path,
    ) {
        val dataDir = tempDir.resolve("wallet_open_${System.currentTimeMillis()}")
        dataDir.toFile().mkdirs()
        val mnemonic = generateMnemonic()

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
                datadir = dataDir.toString(),
                forceRescan = false,
            )
        assertNotNull(wallet1, "First wallet should be created")

        // Open existing wallet
        val wallet2 =
            Wallet.open(
                mnemonic = mnemonic,
                config = config,
                datadir = dataDir.toString(),
            )
        assertNotNull(wallet2, "Wallet should be opened successfully")

        // Both wallets should have same fingerprint
        val props1 = wallet1.properties()
        val props2 = wallet2.properties()
        assertTrue(
            props1.fingerprint == props2.fingerprint,
            "Opened wallet should have same fingerprint as created wallet",
        )
    }

    @Test
    fun `test generate multiple addresses`(
        @TempDir tempDir: Path,
    ) {
        val dataDir = tempDir.resolve("wallet_addresses_${System.currentTimeMillis()}")
        dataDir.toFile().mkdirs()

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
                datadir = dataDir.toString(),
                forceRescan = false,
            )

        // Generate multiple addresses and ensure they're all different
        val addresses = mutableSetOf<String>()
        repeat(5) {
            val address = wallet.newAddress()
            addresses.add(address)
        }

        assertTrue(addresses.size == 5, "Should generate 5 unique addresses")
        addresses.forEach { address ->
            assertTrue(address.startsWith("tark1"), "All addresses should start with 'tark1' for Signet")
        }
    }
}
