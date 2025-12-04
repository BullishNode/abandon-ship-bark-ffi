# Bark Swift Bindings

Swift Package Manager bindings for Bark - an Ark wallet for Bitcoin.

## Overview

Bark is a Bitcoin wallet implementing the Ark protocol, enabling instant, low-fee Bitcoin transactions. These Swift bindings provide native iOS and macOS support through UniFFI-generated interfaces.

## Installation

### Swift Package Manager

Add Bark to your project using Xcode or by editing your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://gitlab.com/ark-bitcoin/bark-ffi.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Bark"]
    )
]
```

### Requirements

- iOS 13.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Example App

A command-line example app is included for quick testing and as a playground:

```bash
cd bindings/swift/BarkExample
swift run
```

This example demonstrates:

- Creating a wallet
- Generating addresses
- Connecting to Signet network
- Error handling

See [BarkExample/Sources/main.swift](BarkExample/Sources/main.swift) for the full code.

## Quick Start

```swift
import Bark

// Configure the wallet
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

// Create or open a wallet
let mnemonic = "your twelve word mnemonic phrase goes here today tomorrow yesterday"
let dataDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("bark").path

do {
    // Create a new wallet (first time)
    let wallet = try Wallet.create(
        mnemonic: mnemonic,
        config: config,
        datadir: dataDir,
        forceRescan: false
    )

    // Or open an existing wallet
    // let wallet = try Wallet.open(mnemonic: mnemonic, config: config, datadir: dataDir)

    // Sync with the network
    try wallet.sync()

    // Get balance
    let balance = try wallet.balance()
    print("Spendable: \(balance.spendableSats) sats")

    // Generate a new receiving address
    let address = try wallet.newAddress()
    print("Address: \(address)")

} catch let error as BarkError {
    print("Wallet error: \(error)")
}
```

## Building from Source

### Prerequisites

- Rust toolchain (install from [rustup.rs](https://rustup.rs))
- Xcode 15.0+
- Xcode Command Line Tools

### Build Steps

```bash
cd bindings/swift
./build-swift.sh
```

This will:

1. Build the Rust library for iOS (device + simulator) and macOS
2. Generate Swift bindings using UniFFI
3. Create an XCFramework with all platforms
4. Copy Swift source files to `Sources/Bark/`
5. Generate a checksum for Package.swift

Update `Package.swift` with the new checksum and release the package.

## Architecture

The Swift bindings use [UniFFI](https://mozilla.github.io/uniffi-rs/) to automatically generate safe Swift interfaces from the Rust implementation:

```
┌─────────────────┐
│   Swift App     │
├─────────────────┤
│  Bark Package   │  ← Swift bindings (generated)
├─────────────────┤
│  XCFramework    │  ← Rust library (compiled)
│  (libbark_ffi)  │
└─────────────────┘
```

## License

This project is licensed under CC0-1.0 - see the [LICENSE](../../LICENSE) file for details.

## Support

- [Community Forum](https://chat.second.tech)
- [GitLab Issues](https://gitlab.com/ark-bitcoin/bark/-/issues)
- [Website](https://second.tech)

## For Maintainers

If you're a maintainer looking to publish new releases of the Swift bindings, see [PUBLISHING.md](./PUBLISHING.md) for detailed instructions on:

- Building and publishing XCFrameworks
- Updating Package.swift
- Registering on Swift Package Index
- CI/CD setup and troubleshooting

## Contributing

Contributions are welcome! Please see our [contributing guidelines](../../CONTRIBUTING.md) for details.

### Development Workflow

1. Make changes to Rust code in `src/`
2. Update `src/bark.udl` if adding new APIs
3. Run `./bindings/swift/build-swift.sh` to regenerate bindings
4. Test with an example app
5. Submit a merge request

## Resources

- [Bark Documentation](https://docs.second.tech)
- [Getting Started on Signet](https://docs.second.tech/getting-started/barking-on-signet/)
- [Ark Protocol](https://docs.second.tech/ark-protocol)
- [Bark Wallet (original Rust code)](https://gitlab.com/ark-bitcoin/bark)
- [UniFFI Documentation](https://mozilla.github.io/uniffi-rs/)
- [Swift Package Manager](https://swift.org/package-manager/)
