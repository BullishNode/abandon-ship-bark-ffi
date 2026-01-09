use thiserror::Error;

/// Error types that can occur when using the Bark wallet FFI
#[derive(Debug, Error)]
pub enum BarkError {
    #[error("Network error: {error_message}")]
    Network { error_message: String },

    #[error("Database error: {error_message}")]
    Database { error_message: String },

    #[error("Invalid mnemonic: {error_message}")]
    InvalidMnemonic { error_message: String },

    #[error("Invalid address: {error_message}")]
    InvalidAddress { error_message: String },

    #[error("Invalid invoice: {error_message}")]
    InvalidInvoice { error_message: String },

    #[error("Invalid PSBT: {error_message}")]
    InvalidPsbt { error_message: String },

    #[error("Invalid transaction: {error_message}")]
    InvalidTransaction { error_message: String },

    #[error("Insufficient funds: {error_message}")]
    InsufficientFunds { error_message: String },

    #[error("Not found: {error_message}")]
    NotFound { error_message: String },

    #[error("Server connection error: {error_message}")]
    ServerConnection { error_message: String },

    #[error("Internal error: {error_message}")]
    Internal { error_message: String },

    #[error("Onchain wallet required: {error_message}")]
    OnchainWalletRequired { error_message: String },
}

impl BarkError {
    pub fn message(&self) -> String {
        match self {
            BarkError::Network { error_message } => error_message.clone(),
            BarkError::Database { error_message } => error_message.clone(),
            BarkError::InvalidMnemonic { error_message } => error_message.clone(),
            BarkError::InvalidAddress { error_message } => error_message.clone(),
            BarkError::InvalidInvoice { error_message } => error_message.clone(),
            BarkError::InvalidPsbt { error_message } => error_message.clone(),
            BarkError::InvalidTransaction { error_message } => error_message.clone(),
            BarkError::InsufficientFunds { error_message } => error_message.clone(),
            BarkError::NotFound { error_message } => error_message.clone(),
            BarkError::ServerConnection { error_message } => error_message.clone(),
            BarkError::Internal { error_message } => error_message.clone(),
            BarkError::OnchainWalletRequired { error_message } => error_message.clone(),
        }
    }
}

impl From<anyhow::Error> for BarkError {
    fn from(e: anyhow::Error) -> Self {
        let msg = format!("{:#}", e);

        // Try to categorize based on error message content
        if msg.contains("mnemonic") || msg.contains("Mnemonic") {
            BarkError::InvalidMnemonic { error_message: msg }
        } else if msg.contains("address") && msg.contains("invalid") {
            BarkError::InvalidAddress { error_message: msg }
        } else if msg.contains("invoice") && (msg.contains("invalid") || msg.contains("parse")) {
            BarkError::InvalidInvoice { error_message: msg }
        } else if msg.contains("insufficient")
            || msg.contains("balance")
            || msg.contains("not enough")
        {
            BarkError::InsufficientFunds { error_message: msg }
        } else if msg.contains("not found")
            || msg.contains("doesn't exist")
            || msg.contains("cannot find")
        {
            BarkError::NotFound { error_message: msg }
        } else if msg.contains("server") || msg.contains("connection") || msg.contains("connect") {
            BarkError::ServerConnection { error_message: msg }
        } else if msg.contains("network") || msg.contains("Network") {
            BarkError::Network { error_message: msg }
        } else if msg.contains("database") || msg.contains("sqlite") || msg.contains("SQL") {
            BarkError::Database { error_message: msg }
        } else {
            BarkError::Internal { error_message: msg }
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
