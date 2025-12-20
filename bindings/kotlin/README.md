# Bark Kotlin Bindings

Kotlin bindings for Bark - an Ark wallet for Bitcoin.

Available for both **Android** and **JVM** (desktop/server) platforms.

## Overview

Bark is a Bitcoin wallet implementing the Ark protocol, enabling instant, low-fee Bitcoin transactions. These Kotlin bindings provide native support for Android and JVM platforms through UniFFI-generated interfaces.

Bark enables:

- 🏃‍♂️ **Instant onboarding**: No channels to open, start transacting immediately
- 🤌 **Simplified UX**: Send and receive without managing channels or liquidity
- 🌐 **Universal payments**: Send Ark, Lightning, and on-chain payments
- 💸 **Lower costs**: Instant payments at a fraction of on-chain fees
- 🔒 **Self-custodial**: Full control of your funds at all times

## Installation

> **Note:** The Kotlin bindings are not yet published to JitPack. To use them, you'll need to build from source (see [Building from Source](#building-from-source)) and include the locally built modules in your project.

### For Android Apps (Future - JitPack)

Once published, add JitPack repository to your project's `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

Add the Android dependency to your app's `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.gitlab.ark-bitcoin.bark-ffi:bark-android:kotlin-0.1.0-beta.4")
}
```

**Requirements:**

- Android API 24+ (Android 7.0 Nougat)
- Kotlin 1.9+

### For JVM Apps (Future - JitPack)

Once published, add JitPack repository to your `build.gradle.kts`:

```kotlin
repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}
```

Add the JVM dependency:

```kotlin
dependencies {
    implementation("com.gitlab.ark-bitcoin.bark-ffi:bark-jvm:kotlin-0.1.0-beta.4")
}
```

**Requirements:**

- JVM 17+
- Kotlin 1.9+

### Using Local Builds

Until the modules are published, clone the repository and build locally:

```bash
git clone https://gitlab.com/ark-bitcoin/bark-ffi.git
cd bark-ffi/bindings/kotlin
./build-kotlin.sh
```

Then reference the built modules in your project's `settings.gradle.kts`:

```kotlin
includeBuild("/path/to/bark-ffi/bindings/kotlin")
```

Or copy the built artifacts:
- Android: `bark-android/build/outputs/aar/bark-android-release.aar`
- JVM: `bark-jvm/build/libs/bark-jvm-*.jar`

## Quick Start

### Android Example

```kotlin
import android.content.Context
import uniffi.bark.*
import java.io.File

fun createWallet(context: Context) {
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

    val mnemonic = generateMnemonic()
    val dataDir = File(context.filesDir, "bark")

    try {
        val wallet = Wallet.create(
            mnemonic = mnemonic,
            config = config,
            datadir = dataDir.absolutePath,
            forceRescan = false
        )

        wallet.sync()
        val balance = wallet.balance()
        println("Balance: ${balance.spendableSats} sats")

        val address = wallet.newAddress()
        println("Address: $address")
    } catch (e: BarkException) {
        when (e) {
            is BarkException.Network -> println("Network error: ${e.errorMessage}")
            is BarkException.InvalidMnemonic -> println("Invalid mnemonic: ${e.errorMessage}")
            else -> println("Error: ${e.errorMessage}")
        }
    }
}
```

### JVM Example

```kotlin
import uniffi.bark.*
import java.nio.file.Paths

fun main() {
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

    val mnemonic = generateMnemonic()
    val dataDir = Paths.get(System.getProperty("user.home"), ".bark").toString()

    try {
        val wallet = Wallet.create(
            mnemonic = mnemonic,
            config = config,
            datadir = dataDir,
            forceRescan = false
        )

        wallet.sync()

        val balance = wallet.balance()
        println("Spendable balance: ${balance.spendableSats} sats")

        // Generate 5 addresses
        repeat(5) {
            val address = wallet.newAddress()
            println("Address ${it + 1}: $address")
        }
    } catch (e: BarkException) {
        println("Error: ${e.errorMessage}")
    }
}
```

## Example Apps

### Android Example

A complete Android example app demonstrating wallet creation, address generation, and network connectivity:

```bash
cd bindings/kotlin/example
./gradlew installDebug
```

See [example/app/src/main/kotlin/tech/second/bark/example/MainActivity.kt](example/app/src/main/kotlin/tech/second/bark/example/MainActivity.kt)

### JVM CLI Example

A simple command-line example for desktop/server use:

```bash
cd bindings/kotlin/example-jvm
./gradlew run
```

See [example-jvm/src/main/kotlin/Main.kt](example-jvm/src/main/kotlin/Main.kt)

## Building from Source

### Prerequisites

- Rust toolchain (install from [rustup.rs](https://rustup.rs))
- For Android: Android NDK (install via Android Studio SDK Manager)
- For JVM: Native build works on Linux and macOS
- JDK 17+
- Gradle 8.7+

### Build Steps

```bash
cd bindings/kotlin
./build-kotlin.sh
```

This will:

1. Build Rust library for Android (4 architectures) and JVM (host platform)
2. Generate Kotlin bindings using UniFFI
3. Copy native libraries to appropriate modules
4. Build both Android AAR and JVM JAR

**Outputs:**

- Android: `bark-android/build/outputs/aar/bark-android-release.aar`
- JVM: `bark-jvm/build/libs/bark-jvm-*.jar`

## Testing

### Run Android Instrumented Tests

Requires an Android emulator or physical device:

```bash
./gradlew :bark-android:connectedAndroidTest
```

### Run JVM Unit Tests

```bash
./gradlew :bark-jvm:test
```

### Run All Tests

```bash
./gradlew test connectedAndroidTest
```

## Code Style

### Check Code Style

```bash
./gradlew ktlintCheck
```

### Auto-fix Code Style

```bash
./gradlew ktlintFormat
```

## Architecture

The Kotlin bindings use [UniFFI](https://mozilla.github.io/uniffi-rs/) to automatically generate safe Kotlin interfaces from the Rust implementation:

```
┌─────────────────────────────────────────┐
│           Your Application              │
├─────────────────────────────────────────┤
│  Android Module          JVM Module     │
│  (bark-android)          (bark-jvm)     │
│  ↓                       ↓              │
│  Kotlin Bindings (generated by UniFFI)  │
├─────────────────────────────────────────┤
│  Native Libraries (.so / .dylib)        │
│  (libbark_ffi - compiled from Rust)     │
└─────────────────────────────────────────┘
```

**Module Comparison:**

| Feature            | bark-android                        | bark-jvm               |
| ------------------ | ----------------------------------- | ---------------------- |
| **Target**         | Android apps                        | Desktop/server apps    |
| **Package**        | AAR                                 | JAR                    |
| **Native libs**    | jniLibs (.so)                       | resources (.so/.dylib) |
| **Min version**    | Android API 24                      | JVM 17                 |
| **Architectures**  | arm64-v8a, armeabi-v7a, x86_64, x86 | Host platform          |
| **JNA dependency** | `@aar` variant                      | Standard JAR           |

## API Overview

### Wallet Management

```kotlin
// Generate mnemonic
val mnemonic = generateMnemonic()

// Validate mnemonic
val isValid = validateMnemonic(mnemonic)

// Create wallet
val wallet = Wallet.create(mnemonic, config, dataDir, forceRescan = false)

// Open existing wallet
val wallet = Wallet.open(mnemonic, config, dataDir)

// Get wallet properties
val props = wallet.properties()
println("Network: ${props.network}")
println("Fingerprint: ${props.fingerprint}")
```

### Receiving Payments

```kotlin
// Generate Ark address
val arkAddress = wallet.newAddress()

// Create Lightning invoice
val invoice = wallet.bolt11Invoice(amountSats = 10000)
println("Invoice: ${invoice.invoice}")
```

### Sending Payments

```kotlin
// Pay Lightning invoice
try {
    val result = wallet.payLightningInvoice("lnbc...", feeRateSatsPerVb = null)
    println("Payment successful! Preimage: ${result.preimage}")
} catch (e: BarkException.InsufficientFunds) {
    println("Not enough balance")
}

// Pay to Lightning Address
val result = wallet.payLightningAddress(
    lightningAddress = "user@domain.com",
    amountSats = 5000,
    comment = "Coffee payment"
)

// Send to Ark address (instant, out-of-round)
wallet.sendArkoorPayment("ark1...", amountSats = 1000)
```

### Balance and Sync

```kotlin
// Sync wallet
wallet.sync()

// Get balance
val balance = wallet.balance()
println("Spendable: ${balance.spendableSats} sats")
println("Pending in round: ${balance.pendingInRoundSats} sats")
println("Pending exit: ${balance.pendingExitSats} sats")

// Get transaction history
val history = wallet.history()
for (tx in history) {
    println("Amount: ${tx.amount} sats")
}
```

### Maintenance

```kotlin
// Claim Lightning receives
wallet.tryClaimAllLightningReceives(requireConfirmed = true)

// Offboard to on-chain
val result = wallet.offboardAll("bc1q...")
println("Offboarded in round: ${result.roundId}")

// Full maintenance
wallet.maintenance()
```

## Error Handling

All errors are exposed as `BarkException` sealed class variants:

```kotlin
try {
    wallet.payLightningInvoice(invoice, null)
} catch (e: BarkException) {
    when (e) {
        is BarkException.Network -> println("Network error: ${e.errorMessage}")
        is BarkException.Database -> println("Database error: ${e.errorMessage}")
        is BarkException.InvalidMnemonic -> println("Invalid mnemonic: ${e.errorMessage}")
        is BarkException.InvalidAddress -> println("Invalid address: ${e.errorMessage}")
        is BarkException.InvalidInvoice -> println("Invalid invoice: ${e.errorMessage}")
        is BarkException.InsufficientFunds -> println("Insufficient funds: ${e.errorMessage}")
        is BarkException.NotFound -> println("Not found: ${e.errorMessage}")
        is BarkException.ServerConnection -> println("Server error: ${e.errorMessage}")
        is BarkException.Internal -> println("Internal error: ${e.errorMessage}")
    }
}
```

## License

This project is licensed under CC0-1.0 - see the [LICENSE](../../LICENSE) file for details.

## Support

- [Community Forum](https://chat.second.tech)
- [GitLab Issues](https://gitlab.com/ark-bitcoin/bark/-/issues)
- [Website](https://second.tech)

## For Maintainers

If you're a maintainer looking to publish new releases of the Kotlin bindings, see [PUBLISHING.md](./PUBLISHING.md) for detailed instructions on:

- Publishing both Android and JVM modules to JitPack
- Building AAR and JAR files
- Running tests and generating documentation
- CI/CD setup and troubleshooting
- Version management

## Contributing

Contributions are welcome! Please see our [contributing guidelines](../../CONTRIBUTING.md) for details.

### Development Workflow

1. Make changes to Rust code in `src/`
2. Update `src/bark.udl` if adding new APIs
3. Run `./bindings/kotlin/build-kotlin.sh` to regenerate bindings
4. Run tests: `./gradlew test connectedAndroidTest`
5. Check code style: `./gradlew ktlintCheck`
6. Submit a merge request

## Resources

- [Bark Documentation](https://docs.second.tech)
- [Getting Started on Signet](https://docs.second.tech/getting-started/barking-on-signet/)
- [Ark Protocol](https://docs.second.tech/ark-protocol)
- [Bark Wallet (original Rust code)](https://gitlab.com/ark-bitcoin/bark)
- [UniFFI Documentation](https://mozilla.github.io/uniffi-rs/)
- [Android Development](https://developer.android.com/)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
