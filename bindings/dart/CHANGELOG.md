# Changelog

All notable changes to the bark_ffi Dart package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release of bark_ffi Dart bindings
- Wallet creation and opening with BIP39 mnemonic support
- Ark address generation for receiving payments
- Lightning invoice generation for receiving
- BOLT11 Lightning invoice payments
- Lightning Address payments (LNURL)
- Ark address (arkoor) instant payments
- Balance inquiry with detailed breakdown
- VTXO listing and inspection
- Offboarding (collaborative exit to on-chain)
- Lightning receive claiming
- Sync and maintenance operations
- Comprehensive error handling with typed errors
- Native Assets support for automatic native library building
- Cross-platform support (iOS, Android, macOS, Linux, Windows)

### Documentation

- Comprehensive README with usage examples
- Inline code documentation
- Example Flutter app

## [0.1.0] - TBD

Initial release.

### Notes

- Requires Dart SDK ≥ 3.10.0 for Native Assets support
- Requires Rust toolchain for building native library
- bark-wallet v0.1.0-beta.4 or later required

[Unreleased]: https://gitlab.com/ark-bitcoin/bark-ffi/-/tree/master/bindings/dart
