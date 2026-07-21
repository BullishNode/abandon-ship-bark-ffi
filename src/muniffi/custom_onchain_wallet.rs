//! Callback-based onchain wallet adapter
//!
//! This module allows foreign languages (Dart, Swift, Kotlin) to provide their own
//! onchain wallet implementations via UniFFI callbacks. The adapter implements the
//! Bark onchain wallet trait by forwarding calls to the callback interface.

use std::sync::Arc;

use anyhow::Context;
use async_trait::async_trait;
use log::error;
use bitcoin::{Address, Amount, FeeRate, Psbt, Script, Transaction};

use bark::chain::ChainSource;
use bark::onchain::{CpfpError, MakeCpfpFees, OnchainWalletTrait};

use crate::error::Error;
use crate::types::{CpfpParams, Destination};

/// Callback interface for custom onchain wallet implementations
///
/// Foreign languages implement this trait to provide their own wallet functionality.
#[uniffi::export(with_foreign)]
pub trait CustomOnchainWalletCallbacks: Send + Sync {
    /// Get the wallet balance in satoshis
    fn get_balance(&self) -> Result<u64, Error>;

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
    ) -> Result<String, Error>;

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
    ) -> Result<String, Error>;

    /// Sign and finalize a PSBT
    ///
    /// # Arguments
    /// * `psbt_base64` - Base64-encoded PSBT
    ///
    /// # Returns
    /// Base64-encoded fully signed PSBT (all witnesses filled in)
    fn finish_psbt(&self, psbt_base64: String) -> Result<String, Error>;

    /// Whether a script pubkey belongs to the wallet's keychains
    ///
    /// # Arguments
    /// * `script_pubkey_hex` - Hex-encoded script pubkey
    fn is_mine(&self, script_pubkey_hex: String) -> Result<bool, Error>;

    /// Register an unconfirmed transaction relevant to the wallet
    ///
    /// # Arguments
    /// * `tx_hex` - Hex-encoded transaction
    fn register_tx(&self, tx_hex: String) -> Result<(), Error>;

    /// Create a signed P2A CPFP transaction
    ///
    /// # Arguments
    /// * `params` - CPFP transaction parameters
    ///
    /// # Returns
    /// Hex-encoded signed CPFP transaction
    fn make_signed_p2a_cpfp(&self, params: CpfpParams) -> Result<String, Error>;

    /// Store a signed P2A CPFP transaction in the wallet
    ///
    /// # Arguments
    /// * `tx_hex` - Hex-encoded transaction
    fn store_signed_p2a_cpfp(&self, tx_hex: String) -> Result<(), Error>;

    /// Sync the wallet with the chain.
    ///
    /// Called by Bark (e.g. the background daemon) to ask the wallet to refresh
    /// its view of the chain before reading balances or building transactions.
    /// Implementations bring their own chain backend up to date — Bark's chain
    /// source is intentionally not passed across the FFI boundary.
    fn sync(&self) -> Result<(), Error>;
}

/// Rust adapter that implements Bark's onchain wallet trait using the callback interface
pub struct CallbackWalletAdapter {
    callbacks: Arc<dyn CustomOnchainWalletCallbacks>,
}

impl CallbackWalletAdapter {
    pub fn new(callbacks: Arc<dyn CustomOnchainWalletCallbacks>) -> Self {
        Self { callbacks }
    }
}

#[async_trait]
impl OnchainWalletTrait for CallbackWalletAdapter {
    async fn balance(&self) -> Amount {
        match self.callbacks.get_balance() {
            Ok(sats) => Amount::from_sat(sats),
            Err(e) => {
                error!(
                    "CustomOnchainWalletCallbacks::get_balance failed: {}",
                    e.message()
                );
                error!("Returning 0 balance - this may cause unexpected behavior!");
                error!(
                    "Please fix the wallet implementation to ensure get_balance never fails"
                );
                Amount::ZERO
            }
        }
    }

    async fn address(&mut self) -> anyhow::Result<Address> {
        // Callback wallets have no address callback; foreign wallets generate
        // addresses on their own side.
        Err(anyhow::anyhow!("address() not supported for callback wallets"))
    }

    async fn sync(&mut self, _chain: &ChainSource) -> anyhow::Result<()> {
        // Forwards to the foreign wallet's own `sync`. Bark's `ChainSource`
        // (esplora/bitcoind) is not used by the foreign implementation — it
        // owns its chain backend — so it is not passed across the FFI.
        self.callbacks.sync().context("sync failed")?;
        Ok(())
    }

    async fn is_mine(&self, spk: &Script) -> anyhow::Result<bool> {
        let spk_hex = hex::encode(spk.as_bytes());
        self.callbacks
            .is_mine(spk_hex)
            .map_err(|e| anyhow::anyhow!("is_mine failed: {}", e.message()))
    }

    async fn register_tx(&mut self, tx: &Transaction) -> anyhow::Result<()> {
        let tx_hex = hex::encode(bitcoin::consensus::serialize(tx));
        self.callbacks
            .register_tx(tx_hex)
            .map_err(|e| anyhow::anyhow!("register_tx failed: {}", e.message()))?;
        Ok(())
    }

    async fn prepare_tx(
        &mut self,
        destinations: &[(Address, Amount)],
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

    async fn prepare_drain_tx(
        &mut self,
        destination: Address,
        fee_rate: FeeRate,
    ) -> anyhow::Result<Psbt> {
        let fee_rate_sat_per_vb = fee_rate.to_sat_per_vb_ceil();

        let psbt_base64 = self
            .callbacks
            .prepare_drain_tx(destination.to_string(), fee_rate_sat_per_vb)
            .map_err(|e| anyhow::anyhow!("prepare_drain_tx failed: {}", e.message()))?;

        use base64::Engine;
        let psbt_bytes = base64::engine::general_purpose::STANDARD.decode(&psbt_base64)?;
        let psbt = Psbt::deserialize(&psbt_bytes)?;

        Ok(psbt)
    }

    async fn finish_psbt(&mut self, psbt: Psbt) -> anyhow::Result<Psbt> {
        // Serialize PSBT to base64
        use base64::Engine;
        let psbt_bytes = psbt.serialize();
        let psbt_base64 = base64::engine::general_purpose::STANDARD.encode(&psbt_bytes);

        // Call callback
        let signed_base64 = self
            .callbacks
            .finish_psbt(psbt_base64)
            .map_err(|e| anyhow::anyhow!("finish_psbt failed: {}", e.message()))?;

        // Decode the fully signed PSBT returned by the callback
        let signed_bytes = base64::engine::general_purpose::STANDARD.decode(&signed_base64)?;
        let signed_psbt = Psbt::deserialize(&signed_bytes)?;

        Ok(signed_psbt)
    }

    async fn make_signed_p2a_cpfp(
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

    async fn store_signed_p2a_cpfp(&mut self, tx: &Transaction) -> anyhow::Result<(), CpfpError> {
        let tx_hex = hex::encode(bitcoin::consensus::serialize(tx));

        self.callbacks
            .store_signed_p2a_cpfp(tx_hex)
            .map_err(|e| CpfpError::StoreError(e.message()))?;

        Ok(())
    }
}
