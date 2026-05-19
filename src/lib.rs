//! # Bark FFI
//!
//! FFI bindings for the Bark wallet library.
//!
//! Two mutually exclusive bindings layers:
//! - `uniffi-bindings` (default): UniFFI scaffolding for Dart/Swift/Kotlin/Python.
//! - `wasm-web`: `wasm-bindgen` bindings for browsers (IndexedDB persister).

#[cfg(all(feature = "uniffi-bindings", feature = "wasm-web"))]
compile_error!("features `uniffi-bindings` and `wasm-web` are mutually exclusive");

#[cfg(not(any(feature = "uniffi-bindings", feature = "wasm-web")))]
compile_error!("enable exactly one of `uniffi-bindings` or `wasm-web`");

mod config;
mod core;
mod error;
mod functions;
mod types;

pub use config::Config;
pub use error::BarkError;
pub use functions::*;
pub use types::*;

#[cfg(feature = "uniffi-bindings")]
mod uniffi_bindings;
#[cfg(feature = "uniffi-bindings")]
pub use uniffi_bindings::*;

#[cfg(feature = "wasm-web")]
mod wasm_bindings;
#[cfg(feature = "wasm-web")]
pub use wasm_bindings::*;

#[cfg(feature = "uniffi-bindings")]
uniffi::setup_scaffolding!("bark");
