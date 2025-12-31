//! Namespace-level functions for Bark FFI

use bark::ark;
use bip39::Mnemonic;

use crate::error::BarkError;

/// Generate a new 12-word BIP39 mnemonic
pub fn generate_mnemonic() -> Result<String, BarkError> {
    let mnemonic = Mnemonic::generate(12).map_err(|e| BarkError::Internal {
        error_message: format!("Failed to generate mnemonic: {}", e),
    })?;
    Ok(mnemonic.to_string())
}

/// Validate a BIP39 mnemonic phrase
pub fn validate_mnemonic(mnemonic: String) -> Result<bool, BarkError> {
    match Mnemonic::parse(mnemonic.trim()) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

/// Validate an Ark address (basic format check only)
///
/// This only validates the format of the address, not whether it belongs
/// to a specific Ark server. For full validation against a connected server,
/// use Wallet::validate_arkoor_address() instead.
pub fn validate_ark_address(address: String) -> Result<bool, BarkError> {
    match address.parse::<ark::Address>() {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}
