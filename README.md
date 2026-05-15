![bark: Ark on bitcoin](assets/bark-ffi-header-white.jpg)

<div align="center">
<h1>bark-ffi: FFI bindings for Bark</h1>
<p>Built with uniffi-rs to generate native bindings for multiple languages from a single Rust codebase.</p>
</div>

<p align="center">
  <br />
  <a href="https://docs.second.tech">Docs</a> ·
  <a href="https://gitlab.com/ark-bitcoin/bark-ffi/issues">Issues</a> ·
  <a href="https://second.tech">Website</a> ·
  <a href="https://blog.second.tech">Blog</a> ·
  <a href="https://www.youtube.com/@2ndbtc">YouTube</a>
</p>

<br />

This repo is a language-agnostic Rust FFI implementation with support for different versions of uniffi.
For the actual bindings, go to [bark-ffi-bindings](https://gitlab.com/ark-bitcoin/bark-ffi-bindings).

## Structure

This repo can maintain different branches with different versions of uniffi, for example:

```
v0.1.0-beta.8-uniffi-v0.30.0
v0.1.0-beta.7-uniffi-v0.30.0
v0.1.0-beta.7-uniffi-v0.29.3
```

Bindings from [bark-ffi-bindings](https://gitlab.com/ark-bitcoin/bark-ffi-bindings) can tap into these branches to generate their own bindings:

```toml
# react-native/rust/Cargo.toml

[dependencies]
bark-ffi = { git = "https://gitlab.com/ark-bitcoin/bark-ffi", branch = "v0.1.0-beta.8-uniffi-v0.30.0" }
uniffi = { version = "=0.30.0", features = ["cli"] }
```

## Build flavors

Two mutually-exclusive feature flags select the binding layer:

| Feature             | Target                       | Persister              |
| ------------------- | ---------------------------- | ---------------------- |
| `uniffi-bindings`   | native (Dart/Swift/Kotlin/…) | SQLite                 |
| `wasm-web`          | `wasm32-unknown-unknown`     | IndexedDB              |

`uniffi-bindings` is the default.

### Native (uniffi)

```sh
cargo build --no-default-features --features uniffi-bindings
```

### WASM

`secp256k1-sys` compiles a `wasm32` C object. Apple's stock clang has no
wasm32 backend; on macOS install LLVM clang first:

```sh
brew install llvm
rustup target add wasm32-unknown-unknown
```

On Linux the distro `clang` usually has wasm32 support built-in
(`apt install clang llvm`).

Use the helper script — it sets the right `CC`/`AR` for each OS:

```sh
scripts/wasm.sh check
scripts/wasm.sh build --release
```

Or set the env vars yourself:

```sh
export CC_wasm32_unknown_unknown=/opt/homebrew/opt/llvm/bin/clang  # macOS
export AR_wasm32_unknown_unknown=/opt/homebrew/opt/llvm/bin/llvm-ar
cargo check --no-default-features --features wasm-web --target wasm32-unknown-unknown
```
