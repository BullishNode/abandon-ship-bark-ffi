# Bark JVM CLI Example

A simple command-line example demonstrating the Bark JVM bindings for desktop and server applications.

## What This Example Does

1. Generates a new BIP39 mnemonic
2. Validates the mnemonic
3. Creates a new Bark wallet on Signet testnet
4. Displays wallet properties (network, fingerprint)
5. Generates 5 receiving addresses

## Prerequisites

- JDK 17 or later
- Rust toolchain (for building native library)
- Internet connection (connects to Signet testnet)

## Building

From the `bindings/kotlin` directory:

```bash
# Build the native library and Kotlin bindings
./build-kotlin.sh

# The example will automatically use the local bark-jvm module
```

## Running

```bash
cd example-jvm
../gradlew run
```

Expected output:

```
🐕 Bark Wallet - JVM CLI Example
=================================

📝 Generating new mnemonic...
Mnemonic: abandon abandon abandon ...
⚠️  Save this mnemonic securely! It's needed to recover your wallet.

✅ Mnemonic validation: VALID

🔧 Configuring wallet for Signet testnet...
📁 Wallet data directory: /home/user/.bark/jvm_example_1234567890

🔨 Creating wallet...
✅ Wallet created successfully!

📋 Wallet Properties:
   Network: Signet
   Fingerprint: abcd1234

🏠 Generating 5 receiving addresses:
   1. ark1...
   2. ark1...
   3. ark1...
   4. ark1...
   5. ark1...

💡 Tips:
   - Send Signet testnet BTC to any of the addresses above
   - Use a bark-supporting Signet faucet: https://signet.2nd.dev/
   - After receiving funds, you can use wallet.sync() and wallet.balance()
   - See the Bark documentation for more examples: https://docs.second.tech

✅ Example completed successfully!
```

## What's Next

Try modifying the example to:

- Open an existing wallet using `Wallet.open()`
- Sync the wallet and check balance: `wallet.sync()` and `wallet.balance()`
- Generate a Lightning invoice: `wallet.bolt11Invoice(amountSats)`
- Send a payment (after receiving funds)

See the [main README](../README.md) for full API documentation.

## Troubleshooting

**Error: Native library not found**

Make sure you've run the build script first:

```bash
cd ..
./build-kotlin.sh
```

**Error: JVM version**

Ensure you're using JDK 17 or later:

```bash
java -version
```

**Error: Server connection**

Check your internet connection. The example connects to:

- Ark server: https://ark.signet.2nd.dev
- Esplora: https://esplora.signet.2nd.dev
