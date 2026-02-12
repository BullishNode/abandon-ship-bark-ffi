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

Because [uniffi-bindgen-react-native](https://github.com/jhugman/uniffi-bindgen-react-native) only supports uniffi v0.29 for now, this repo maintains different branches, for example:

```
v0.1.0-beta.5-uniffi-v0.30.0
v0.1.0-beta.5-uniffi-v0.29.3
```

Bindings from [bark-ffi-bindings](https://gitlab.com/ark-bitcoin/bark-ffi-bindings) can tap into these branches to generate their own bindings:

```toml
# react-native/rust/Cargo.toml

[dependencies]
bark-ffi = { git = "https://gitlab.com/ark-bitcoin/bark-ffi", branch = "v0.1.0-beta.5-uniffi-v0.29.3" }
uniffi = { version = "=0.29.3", features = ["cli"] }
```
