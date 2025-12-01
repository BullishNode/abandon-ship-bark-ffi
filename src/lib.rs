//! # Bark FFI
//!
//! Foreign Function Interface bindings for the Bark wallet library.
//!
//! This crate provides UniFFI-generated bindings that allow using Bark
//! from other languages like Dart, Swift, Kotlin, and Python.

mod error;
mod runtime;
mod types;
mod wallet;

pub use error::BarkError;
pub use types::*;
pub use wallet::Wallet;

// Include the UniFFI scaffolding code
uniffi::include_scaffolding!("bark_ffi");
