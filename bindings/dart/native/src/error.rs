use thiserror::Error;

/// Error types that can occur when using the Bark wallet FFI
#[derive(Debug, Error)]
pub enum BarkError {
    #[error("Network error: {message}")]
    Network { message: String },

    #[error("Database error: {message}")]
    Database { message: String },

    #[error("Invalid mnemonic: {message}")]
    InvalidMnemonic { message: String },

    #[error("Invalid address: {message}")]
    InvalidAddress { message: String },

    #[error("Invalid invoice: {message}")]
    InvalidInvoice { message: String },

    #[error("Insufficient funds: {message}")]
    InsufficientFunds { message: String },

    #[error("Not found: {message}")]
    NotFound { message: String },

    #[error("Server connection error: {message}")]
    ServerConnection { message: String },

    #[error("Internal error: {message}")]
    Internal { message: String },
}

impl From<anyhow::Error> for BarkError {
    fn from(e: anyhow::Error) -> Self {
        let msg = format!("{:#}", e);

        // Try to categorize based on error message content
        if msg.contains("mnemonic") || msg.contains("Mnemonic") {
            BarkError::InvalidMnemonic { message: msg }
        } else if msg.contains("address") && msg.contains("invalid") {
            BarkError::InvalidAddress { message: msg }
        } else if msg.contains("invoice") && (msg.contains("invalid") || msg.contains("parse")) {
            BarkError::InvalidInvoice { message: msg }
        } else if msg.contains("insufficient")
            || msg.contains("balance")
            || msg.contains("not enough")
        {
            BarkError::InsufficientFunds { message: msg }
        } else if msg.contains("not found")
            || msg.contains("doesn't exist")
            || msg.contains("cannot find")
        {
            BarkError::NotFound { message: msg }
        } else if msg.contains("server") || msg.contains("connection") || msg.contains("connect") {
            BarkError::ServerConnection { message: msg }
        } else if msg.contains("network") || msg.contains("Network") {
            BarkError::Network { message: msg }
        } else if msg.contains("database") || msg.contains("sqlite") || msg.contains("SQL") {
            BarkError::Database { message: msg }
        } else {
            BarkError::Internal { message: msg }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_categorization() {
        let mnemonic_err = anyhow::anyhow!("Invalid mnemonic phrase");
        assert!(matches!(
            BarkError::from(mnemonic_err),
            BarkError::InvalidMnemonic { .. }
        ));

        let insufficient_err = anyhow::anyhow!("Insufficient balance available");
        assert!(matches!(
            BarkError::from(insufficient_err),
            BarkError::InsufficientFunds { .. }
        ));

        let server_err = anyhow::anyhow!("Failed to connect to server");
        assert!(matches!(
            BarkError::from(server_err),
            BarkError::ServerConnection { .. }
        ));
    }
}
