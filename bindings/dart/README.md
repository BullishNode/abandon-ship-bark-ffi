# bark Dart Bindings

Dart bindings for bark - Ark wallet for Bitcoin.

## Overview

This package provides Dart bindings for [bark](https://gitlab.com/ark-bitcoin/bark), an implementation of the Ark protocol on Bitcoin led by [Second](https://second.tech). These bindings allow Dart and Flutter applications to integrate Ark wallet functionality, enabling instant, low-cost Bitcoin payments via the Ark protocol without losing custody of funds.

Bark enables:

- 🏃‍♂️ **Instant onboarding**: No channels to open, start transacting immediately
- 🤌 **Simplified UX**: Send and receive without managing channels or liquidity
- 🌐 **Universal payments**: Send Ark, Lightning, and on-chain payments
- 💸 **Lower costs**: Instant payments at a fraction of on-chain fees
- 🔒 **Self-custodial**: Full control of your funds at all times

## Installation

### Requirements

- Dart SDK ≥ 3.10.0 (for Native Assets support)
- Rust toolchain (cargo, rustc) for building native library
- Flutter 3.x+ (for Flutter apps)

### Add to your project

**Via git (recommended during development):**

```yaml
dependencies:
  bark:
    git:
      url: https://gitlab.com/ark-bitcoin/bark-ffi
      path: bindings/dart/
      ref: master # or specific tag
```

**Via pub.dev (when published):**

```yaml
dependencies:
  bark: ^0.1.0-beta.4
```

Then run:

```bash
dart pub get  # or flutter pub get
```

The native library will be automatically built by Dart's Native Assets system.

## Usage

### Create a new wallet

```dart
import 'package:bark/bark.dart';

// Configure for signet
final config = Config(
  'https://ark.signet.2nd.dev',
  'https://esplora.signet.2nd.dev',
  Network.signet,
  null,  // vtxoRefreshExpiryThreshold - use defaults
  null,  // vtxoExitMargin - use defaults
  null,  // htlcRecvClaimDelta - use defaults
);

// Create wallet with BIP39 mnemonic
final wallet = await Wallet.create(
  'your twelve word mnemonic phrase goes here today',
  config,
  '/path/to/wallet/data',
  false,  // forceRescan
);

print('Wallet fingerprint: ${wallet.properties().fingerprint}');
```

### Open existing wallet

```dart
final wallet = await Wallet.open(
  'your twelve word mnemonic phrase goes here today',
  config,
  '/path/to/wallet/data',
);
```

### Sync and check balance

```dart
// Lightweight sync
wallet.sync();

// Get balance
final balance = wallet.balance();
print('Spendable: ${balance.spendableSats} sats');
print('Pending in round: ${balance.pendingInRoundSats} sats');
print('Pending exit: ${balance.pendingExitSats} sats');
```

### Receive payments

```dart
// Generate Ark address
final arkAddress = await wallet.newAddress();
print('Send funds to: $arkAddress');

// Or create a Lightning invoice
final invoice = wallet.bolt11Invoice(10000);
print('Lightning invoice: ${invoice.invoice}');
```

### Send payments

```dart
// Pay Lightning invoice
try {
  final result = wallet.payLightningInvoice('lnbc...', null);
  print('Payment successful! Preimage: ${result.preimage}');
} on BarkError catch (e) {
  print('Payment failed: $e');
}

// Pay to Lightning Address
final result = wallet.payLightningAddress(
  'user@domain.com',
  5000,
  'Coffee payment',
);

// Send to Ark address (instant, out-of-round)
wallet.sendArkoorPayment('ark1...', 1000);
```

### Claim Lightning receives

```dart
// Claim all pending Lightning receives
wallet.tryClaimAllLightningReceives(true);
```

### Offboard to on-chain

```dart
// Offboard all funds to Bitcoin address
final result = wallet.offboardAll('bc1q...');
print('Offboarded in round: ${result.roundId}');
```

### Maintenance

```dart
// Full maintenance (recommended periodic operation)
wallet.maintenance();
```

## Error Handling

The package uses typed errors via `BarkError`:

```dart
try {
  wallet.payLightningInvoice('lnbc...', null);
} on BarkError catch (e) {
  switch (e) {
    case BarkError_InsufficientFunds():
      print('Not enough balance');
    case BarkError_InvalidInvoice():
      print('Invalid invoice format');
    case BarkError_ServerConnection():
      print('Cannot connect to server');
    default:
      print('Error: $e');
  }
}
```

## Example

See [example/main.dart](example/main.dart) for a pure Dart example demonstrating basic wallet operations.

To run the example:

```bash
dart run example/main.dart
```

## Development

### For Package Maintainers

⚠️ **The following instructions are for bark package maintainers only.**
End users of the bark package do not need to build from source or run the generator script.

#### Generating bindings after changes

When you modify the bark-ffi Rust code or UDL interface:

1. Clone the bark repository:

   ```bash
   git clone https://gitlab.com/ark-bitcoin/bark-ffi
   cd bark-ffi
   ```

2. Run the bindings generator script:

   ```bash
   cd bindings/dart/scripts
   bash ./generate_bindings.sh
   ```

   This script:

   - Builds bark-ffi from the workspace
   - Generates Dart bindings to `lib/src/generated/`
   - Copies bark-ffi to `native/` with pub.dev-compatible dependencies

3. Test the generated bindings:

   ```bash
   cd ..
   dart pub get  # Builds native library via Native Assets
   dart test
   ```

4. Commit the changes and generated files:
   ```bash
   git add .
   git commit -m "chore: update Dart bindings"
   ```

### For End Users

End users installing bark **do not** need to run `generate_bindings.sh`.

When you add bark as a dependency and run `dart pub get`, Dart's Native Assets system automatically:

1. Finds the Rust source in the `native/` directory
2. Compiles it for your platform
3. Links it to your Dart/Flutter application

You only need:

- Dart SDK ≥ 3.10.0
- Rust toolchain (cargo, rustc) installed on your system

## Documentation

- [Bark Documentation](https://docs.second.tech)
- [Getting Started on Signet](https://docs.second.tech/getting-started/barking-on-signet/)
- [Ark Protocol](https://docs.second.tech/ark-protocol)
- [Dart Native Assets Hooks](https://dart.dev/tools/hooks)

## License

CC0-1.0 - See [LICENSE](../../LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

## Support

- [Community Forum](https://chat.second.tech)
- [GitLab Issues](https://gitlab.com/ark-bitcoin/bark/-/issues)
- [Website](https://second.tech)
