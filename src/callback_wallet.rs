//! Callback-based onchain wallet adapter
//!
//! This module allows foreign languages (Dart, Swift, Kotlin) to provide their own
//! onchain wallet implementations via UniFFI callbacks. The adapter implements all
//! required Bark onchain traits by forwarding calls to the callback interface.

use std::sync::Arc;

use bitcoin::{
    address::NetworkChecked, Amount, BlockHash, FeeRate, OutPoint, Psbt, Transaction, Txid,
};

use bark::onchain::{
    CpfpError, GetBalance, GetSpendingTx, GetWalletTx, MakeCpfp, MakeCpfpFees, PreparePsbt,
    SignPsbt,
};
use bark_bitcoin_ext::BlockRef;

use crate::error::BarkError;
use crate::types::{BlockRef as FfiBlockRef, CpfpParams, Destination, OutPoint as FfiOutPoint};

/// Callback interface for onchain wallet operations
///
/// Foreign languages implement this trait to provide their own wallet functionality.
pub trait OnchainWalletCallbacks: Send + Sync {
    /// Get the wallet balance in satoshis
    fn get_balance(&self) -> Result<u64, BarkError>;

    /// Prepare a transaction to send to given destinations
    ///
    /// # Arguments
    /// * `destinations` - List of destinations with addresses and amounts
    /// * `fee_rate_sat_per_vb` - Fee rate in sats per vbyte
    ///
    /// # Returns
    /// Base64-encoded PSBT
    fn prepare_tx(
        &self,
        destinations: Vec<Destination>,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, BarkError>;

    /// Prepare a transaction that drains the wallet to a single address
    ///
    /// # Arguments
    /// * `address` - Bitcoin address to drain to
    /// * `fee_rate_sat_per_vb` - Fee rate in sats per vbyte
    ///
    /// # Returns
    /// Base64-encoded PSBT
    fn prepare_drain_tx(
        &self,
        address: String,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, BarkError>;

    /// Sign and finalize a PSBT
    ///
    /// # Arguments
    /// * `psbt_base64` - Base64-encoded PSBT
    ///
    /// # Returns
    /// Hex-encoded signed transaction
    fn finish_tx(&self, psbt_base64: String) -> Result<String, BarkError>;

    /// Get a wallet transaction by txid
    ///
    /// # Arguments
    /// * `txid` - Transaction ID as hex string
    ///
    /// # Returns
    /// Hex-encoded transaction, or null if not found
    fn get_wallet_tx(&self, txid: String) -> Result<Option<String>, BarkError>;

    /// Get the block hash where a transaction was confirmed
    ///
    /// # Arguments
    /// * `txid` - Transaction ID as hex string
    ///
    /// # Returns
    /// Block reference with height and hash, or null if unconfirmed
    fn get_wallet_tx_confirmed_block(&self, txid: String) -> Result<Option<FfiBlockRef>, BarkError>;

    /// Find transaction that spends a given output
    ///
    /// # Arguments
    /// * `outpoint` - Transaction outpoint to check
    ///
    /// # Returns
    /// Hex-encoded spending transaction, or null if unspent
    fn get_spending_tx(&self, outpoint: FfiOutPoint) -> Result<Option<String>, BarkError>;

    /// Create a signed P2A CPFP transaction
    ///
    /// # Arguments
    /// * `params` - CPFP transaction parameters
    ///
    /// # Returns
    /// Hex-encoded signed CPFP transaction
    fn make_signed_p2a_cpfp(&self, params: CpfpParams) -> Result<String, BarkError>;

    /// Store a signed P2A CPFP transaction in the wallet
    ///
    /// # Arguments
    /// * `tx_hex` - Hex-encoded transaction
    fn store_signed_p2a_cpfp(&self, tx_hex: String) -> Result<(), BarkError>;
}

/// Rust adapter that implements Bark traits using callback interface
pub struct CallbackWalletAdapter {
    callbacks: Box<dyn OnchainWalletCallbacks>,
}

impl CallbackWalletAdapter {
    pub fn new(callbacks: Box<dyn OnchainWalletCallbacks>) -> Self {
        Self { callbacks }
    }
}

// Implement GetBalance trait
impl GetBalance for CallbackWalletAdapter {
    fn get_balance(&self) -> Amount {
        match self.callbacks.get_balance() {
            Ok(sats) => Amount::from_sat(sats),
            Err(e) => {
                eprintln!("[ERROR] OnchainWalletCallbacks::get_balance failed: {}", e.message());
                eprintln!("[ERROR] Returning 0 balance - this may cause unexpected behavior!");
                eprintln!("[ERROR] Please fix the wallet implementation to ensure get_balance never fails");
                Amount::ZERO
            }
        }
    }
}

// Implement PreparePsbt trait
impl PreparePsbt for CallbackWalletAdapter {
    fn prepare_tx(
        &mut self,
        destinations: &[(bitcoin::Address<NetworkChecked>, Amount)],
        fee_rate: FeeRate,
    ) -> anyhow::Result<Psbt> {
        // Convert destinations to FFI-friendly type
        let dests: Vec<Destination> = destinations
            .iter()
            .map(|(addr, amt)| Destination {
                address: addr.to_string(),
                amount_sats: amt.to_sat(),
            })
            .collect();

        // Get fee rate in sat/vB
        let fee_rate_sat_per_vb = fee_rate.to_sat_per_vb_ceil();

        // Call callback
        let psbt_base64 = self
            .callbacks
            .prepare_tx(dests, fee_rate_sat_per_vb)
            .map_err(|e| anyhow::anyhow!("prepare_tx failed: {}", e.message()))?;

        // Decode PSBT from base64
        use base64::Engine;
        let psbt_bytes = base64::engine::general_purpose::STANDARD.decode(&psbt_base64)?;
        let psbt = Psbt::deserialize(&psbt_bytes)?;

        Ok(psbt)
    }

    fn prepare_drain_tx(
        &mut self,
        address: bitcoin::Address<NetworkChecked>,
        fee_rate: FeeRate,
    ) -> anyhow::Result<Psbt> {
        let fee_rate_sat_per_vb = fee_rate.to_sat_per_vb_ceil();

        let psbt_base64 = self
            .callbacks
            .prepare_drain_tx(address.to_string(), fee_rate_sat_per_vb)
            .map_err(|e| anyhow::anyhow!("prepare_drain_tx failed: {}", e.message()))?;

        use base64::Engine;
        let psbt_bytes = base64::engine::general_purpose::STANDARD.decode(&psbt_base64)?;
        let psbt = Psbt::deserialize(&psbt_bytes)?;

        Ok(psbt)
    }
}

// Implement SignPsbt trait
impl SignPsbt for CallbackWalletAdapter {
    fn finish_tx(&mut self, psbt: Psbt) -> anyhow::Result<Transaction> {
        // Serialize PSBT to base64
        use base64::Engine;
        let psbt_bytes = psbt.serialize();
        let psbt_base64 = base64::engine::general_purpose::STANDARD.encode(&psbt_bytes);

        // Call callback
        let tx_hex = self
            .callbacks
            .finish_tx(psbt_base64)
            .map_err(|e| anyhow::anyhow!("finish_tx failed: {}", e.message()))?;

        // Decode transaction from hex
        let tx: Transaction = bitcoin::consensus::deserialize(&hex::decode(&tx_hex)?)?;

        Ok(tx)
    }
}

// Implement GetWalletTx trait
impl GetWalletTx for CallbackWalletAdapter {
    fn get_wallet_tx(&self, txid: Txid) -> Option<Arc<Transaction>> {
        let tx_hex_opt = self.callbacks.get_wallet_tx(txid.to_string()).ok()??;

        if let Ok(tx_bytes) = hex::decode(&tx_hex_opt) {
            if let Ok(tx) = bitcoin::consensus::deserialize::<Transaction>(&tx_bytes) {
                return Some(Arc::new(tx));
            }
        }
        None
    }

    fn get_wallet_tx_confirmed_block(&self, txid: Txid) -> anyhow::Result<Option<BlockRef>> {
        let block_ref_opt = self
            .callbacks
            .get_wallet_tx_confirmed_block(txid.to_string())
            .map_err(|e| {
                anyhow::anyhow!("get_wallet_tx_confirmed_block failed: {}", e.message())
            })?;

        if let Some(ffi_block_ref) = block_ref_opt {
            let block_hash: BlockHash = ffi_block_ref.hash.parse()?;
            Ok(Some(BlockRef {
                height: ffi_block_ref.height,
                hash: block_hash,
            }))
        } else {
            Ok(None)
        }
    }
}

// Implement GetSpendingTx trait
impl GetSpendingTx for CallbackWalletAdapter {
    fn get_spending_tx(&self, outpoint: OutPoint) -> Option<Arc<Transaction>> {
        // Convert bitcoin::OutPoint to FFI OutPoint
        let ffi_outpoint = FfiOutPoint {
            txid: outpoint.txid.to_string(),
            vout: outpoint.vout,
        };

        let tx_hex_opt = self.callbacks.get_spending_tx(ffi_outpoint).ok()??;

        if let Ok(tx_bytes) = hex::decode(&tx_hex_opt) {
            if let Ok(tx) = bitcoin::consensus::deserialize::<Transaction>(&tx_bytes) {
                return Some(Arc::new(tx));
            }
        }
        None
    }
}

// Implement MakeCpfp trait
impl MakeCpfp for CallbackWalletAdapter {
    fn make_signed_p2a_cpfp(
        &mut self,
        tx: &Transaction,
        fees: MakeCpfpFees,
    ) -> Result<Transaction, CpfpError> {
        // Convert to FFI-friendly CPFP params
        let tx_hex = hex::encode(bitcoin::consensus::serialize(tx));

        let (fees_type, effective_rate, current_fee) = match fees {
            MakeCpfpFees::Effective(fr) => ("Effective".to_string(), fr.to_sat_per_vb_ceil(), None),
            MakeCpfpFees::Rbf {
                min_effective_fee_rate,
                current_package_fee,
            } => (
                "Rbf".to_string(),
                min_effective_fee_rate.to_sat_per_vb_ceil(),
                Some(current_package_fee.to_sat()),
            ),
        };

        let params = CpfpParams {
            tx_hex,
            fees_type,
            effective_fee_rate_sat_per_vb: effective_rate,
            current_package_fee_sats: current_fee,
        };

        // Call callback
        let cpfp_tx_hex = self
            .callbacks
            .make_signed_p2a_cpfp(params)
            .map_err(|e| CpfpError::CreateError(e.message()))?;

        // Decode transaction
        let cpfp_tx_bytes = hex::decode(&cpfp_tx_hex)
            .map_err(|e| CpfpError::InternalError(format!("Invalid hex: {}", e)))?;
        let cpfp_tx: Transaction = bitcoin::consensus::deserialize(&cpfp_tx_bytes)
            .map_err(|e| CpfpError::InternalError(format!("Invalid transaction: {}", e)))?;

        Ok(cpfp_tx)
    }

    fn store_signed_p2a_cpfp(&mut self, tx: &Transaction) -> Result<(), CpfpError> {
        let tx_hex = hex::encode(bitcoin::consensus::serialize(tx));

        self.callbacks
            .store_signed_p2a_cpfp(tx_hex)
            .map_err(|e| CpfpError::StoreError(e.message()))?;

        Ok(())
    }
}
