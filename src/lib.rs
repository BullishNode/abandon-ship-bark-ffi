//! # Bark FFI
//!
//! FFI bindings for the Bark wallet library.
//!
//! Two mutually exclusive bindings layers:
//! - `uniffi` (default): UniFFI scaffolding for Dart/Swift/Kotlin/Python.
//! - `wasm-web`: `wasm-bindgen` bindings for browsers (IndexedDB persister).

#[cfg(all(feature = "uniffi", feature = "wasm-web"))]
compile_error!("features `uniffi` and `wasm-web` are mutually exclusive");

#[cfg(not(any(feature = "uniffi", feature = "wasm-web")))]
compile_error!("enable exactly one of `uniffi` or `wasm-web`");

mod config;
mod core;
mod error;
mod functions;
mod types;

pub use config::Config;
pub use error::Error;
pub use functions::*;
pub use types::*;

#[cfg(feature = "uniffi")]
mod muniffi; // nb can't clash with uniffi crate name
#[cfg(feature = "uniffi")]
pub use muniffi::*;

#[cfg(feature = "wasm-web")]
mod wasm;
#[cfg(feature = "wasm-web")]
pub use wasm::*;

#[cfg(feature = "uniffi")]
uniffi::setup_scaffolding!("bark");
