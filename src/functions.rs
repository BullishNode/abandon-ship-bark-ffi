//! Namespace-level functions for Bark FFI

use bark::ark;
use bip39::Mnemonic;

use crate::error::BarkError;

/// Generate a new 12-word BIP39 mnemonic
#[cfg_attr(feature = "uniffi-bindings", uniffi::export)]
pub fn generate_mnemonic() -> Result<String, BarkError> {
    let mnemonic = Mnemonic::generate(12).map_err(|e| BarkError::Internal {
        error_message: format!("Failed to generate mnemonic: {}", e),
    })?;
    Ok(mnemonic.to_string())
}

/// Validate a BIP39 mnemonic phrase
#[cfg_attr(feature = "uniffi-bindings", uniffi::export)]
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
#[cfg_attr(feature = "uniffi-bindings", uniffi::export)]
pub fn validate_ark_address(address: String) -> Result<bool, BarkError> {
    match address.parse::<ark::Address>() {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

/// Extract a signed transaction from a PSBT
///
/// Takes a base64-encoded PSBT and extracts the final signed transaction.
/// This is useful after signing a PSBT (e.g., from drain_exits) before broadcasting.
///
/// # Arguments
///
/// * `psbt_base64` - Base64-encoded PSBT string
///
/// # Returns
///
/// Hex-encoded signed transaction ready for broadcasting
#[cfg_attr(feature = "uniffi-bindings", uniffi::export)]
pub fn extract_tx_from_psbt(psbt_base64: String) -> Result<String, BarkError> {
    use bitcoin::consensus::encode::serialize_hex;
    use bitcoin::psbt::Psbt;
    use std::str::FromStr;

    let psbt = Psbt::from_str(&psbt_base64).map_err(|e| BarkError::InvalidPsbt {
        error_message: format!("{}", e),
    })?;

    let tx = psbt.extract_tx().map_err(|e| BarkError::Internal {
        error_message: format!("Failed to extract transaction: {}", e),
    })?;

    Ok(serialize_hex(&tx))
}
