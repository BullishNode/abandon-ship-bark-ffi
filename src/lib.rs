//! # Bark FFI
//!
//! Foreign Function Interface bindings for the Bark wallet library.
//!
//! This crate provides UniFFI-generated bindings that allow using Bark
//! from other languages like Dart, Swift, Kotlin, and Python.

mod custom_onchain_wallet;
mod db;
mod error;
mod functions;
mod logger;
mod notification;
mod onchain_wallet;
mod runtime;
mod types;
mod wallet;

pub use custom_onchain_wallet::CustomOnchainWalletCallbacks;
pub use error::BarkError;
pub use functions::*;
pub use logger::{set_logger, BarkLogger, LogLevel};
pub use notification::NotificationHolder;
pub use onchain_wallet::OnchainWallet;
pub use types::*;
pub use wallet::Wallet;

// Include the UniFFI scaffolding code
uniffi::include_scaffolding!("bark");
