use std::sync::Arc;

use anyhow::Context;
use bark::lightning_invoice::Bolt11Invoice;
use bark::Wallet as InnerWallet;
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;
use lnurl::lightning_address::LightningAddress;

use crate::error::BarkError;
use crate::runtime::TOKIO_RT;
use crate::types::*;

/// The main Bark wallet interface
pub struct Wallet {
    inner: InnerWallet,
}

impl Wallet {
    /// Create a new Bark wallet
    pub fn create(
        mnemonic: String,
        config: Config,
        datadir: String,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        let inner =
            TOKIO_RT.block_on(Self::create_async(mnemonic, config, datadir, force_rescan))?;
        Ok(Self { inner })
    }

    async fn create_async(
        mnemonic: String,
        config: Config,
        datadir: String,
        force_rescan: bool,
    ) -> Result<InnerWallet, BarkError> {
        let network: BtcNetwork = config.network.into();
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        // Use shared database cache
        let db = crate::db::get_or_open_db(&datadir)
            .with_context(|| format!("opening sqlite in {}", datadir))?;

        let inner = InnerWallet::create(&mnemonic, network, cfg, db, force_rescan)
            .await
            .map_err(BarkError::from)?;

        Ok(inner)
    }

    /// Open an existing Bark wallet
    pub fn open(mnemonic: String, config: Config, datadir: String) -> Result<Self, BarkError> {
        let inner = TOKIO_RT.block_on(Self::open_async(mnemonic, config, datadir))?;
        Ok(Self { inner })
    }

    async fn open_async(
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<InnerWallet, BarkError> {
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        // Use shared database cache
        let db = crate::db::get_or_open_db(&datadir)
            .with_context(|| format!("opening sqlite in {}", datadir))?;

        let inner = InnerWallet::open(&mnemonic, db, cfg)
            .await
            .map_err(BarkError::from)?;

        // Check if server connection was established
        if inner.ark_info().await.ok().flatten().is_some() {
            eprintln!("[OPEN] ✅ Server connection established");
        } else {
            eprintln!("[OPEN] ⚠️  WARNING: Server connection FAILED - Lightning and Ark operations will not work!");
        }

        Ok(inner)
    }

    /// Create a new Bark wallet WITH onchain capabilities
    pub fn create_with_onchain(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Arc<crate::OnchainWallet>,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        TOKIO_RT.block_on(async {
            let network: BtcNetwork = config.network.into();
            let cfg: bark::Config = config.into();

            let mnemonic =
                Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                    error_message: e.to_string(),
                })?;

            // Use shared database cache
            let db = crate::db::get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;

            eprintln!("[CREATE] Creating Bark wallet with onchain capabilities...");

            let inner = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let onchain_inner = bdk_wallet.lock().await;
                InnerWallet::create_with_onchain(
                    &mnemonic,
                    network,
                    cfg,
                    db,
                    &*onchain_inner,
                    force_rescan,
                )
                .await
                .map_err(BarkError::from)?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let onchain_inner = callback_adapter.lock().await;
                InnerWallet::create_with_onchain(
                    &mnemonic,
                    network,
                    cfg,
                    db,
                    &*onchain_inner,
                    force_rescan,
                )
                .await
                .map_err(BarkError::from)?
            } else {
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                });
            };

            eprintln!("[CREATE] ✅ Bark wallet with onchain created successfully");

            Ok(Self { inner })
        })
    }

    /// Open an existing Bark wallet WITH onchain capabilities
    pub fn open_with_onchain(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<Self, BarkError> {
        TOKIO_RT.block_on(async {
            let cfg: bark::Config = config.into();

            let mnemonic = Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

            // Use shared database cache
            let db = crate::db::get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;

            eprintln!("[OPEN] Opening Bark wallet with onchain capabilities...");

            let inner = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let onchain_inner = bdk_wallet.lock().await;
                InnerWallet::open_with_onchain(&mnemonic, db, &*onchain_inner, cfg)
                    .await
                    .map_err(BarkError::from)?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let onchain_inner = callback_adapter.lock().await;
                InnerWallet::open_with_onchain(&mnemonic, db, &*onchain_inner, cfg)
                    .await
                    .map_err(BarkError::from)?
            } else {
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                });
            };

            // Check if server connection was established
            if inner.ark_info().await.ok().flatten().is_some() {
                eprintln!("[OPEN] ✅ Server connection established");
            } else {
                eprintln!("[OPEN] ⚠️  WARNING: Server connection FAILED - Lightning and Ark operations will not work!");
            }

            eprintln!("[OPEN] ✅ Bark wallet with onchain opened successfully");

            Ok(Self { inner })
        })
    }

    // ------------------------------------------------------------------------
    // Synchronization & Maintenance
    // ------------------------------------------------------------------------

    /// Lightweight sync with Ark server and blockchain
    ///
    /// Note: Bark's upstream `sync()` returns `()` and handles all errors
    /// internally with warn!() logging. This wrapper cannot surface sync
    /// failures to callers - they are logged internally by Bark.
    pub fn sync(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[SYNC] Starting sync...");
            self.inner.sync().await;
            eprintln!("[SYNC] Sync completed");

            // Log balance after sync
            if let Ok(balance) = self.inner.balance().await {
                eprintln!(
                    "[SYNC] Balance after sync: spendable={}, pending_board={}",
                    balance.spendable.to_sat(),
                    balance.pending_board.to_sat()
                );
            }

            // Log VTXO count
            if let Ok(vtxos) = self.inner.vtxos().await {
                eprintln!("[SYNC] VTXOs after sync: {} total", vtxos.len());
                for (i, vtxo) in vtxos.iter().enumerate().take(3) {
                    eprintln!(
                        "[SYNC]   VTXO {}: {} sats, state={:?}",
                        i,
                        vtxo.vtxo.amount().to_sat(),
                        vtxo.state.kind()
                    );
                }
            }

            Ok(())
        })
    }

    /// Full maintenance: sync + refresh VTXOs if necessary
    pub fn maintenance(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.maintenance().await?;
            Ok(())
        })
    }

    /// Perform full maintenance including onchain sync
    ///
    /// This is more thorough than `maintenance()` as it also syncs the onchain wallet
    /// and the exit system.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet to sync
    pub fn maintenance_with_onchain(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                self.inner.maintenance_with_onchain(&mut *onchain).await?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                self.inner.maintenance_with_onchain(&mut *onchain).await?;
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Invalid onchain wallet".to_string(),
                });
            }
            Ok(())
        })
    }

    /// Perform maintenance in delegated (non-interactive) mode
    ///
    /// This schedules refresh operations but doesn't wait for completion.
    /// Use this when you want to queue operations without blocking.
    pub fn maintenance_delegated(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.maintenance_delegated().await?;
            Ok(())
        })
    }

    /// Perform maintenance with onchain wallet in delegated mode
    pub fn maintenance_with_onchain_delegated(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            // Implementation similar to maintenance_with_onchain but calls
            // maintenance_with_onchain_delegated on inner wallet
            // Need to handle BDK vs Callback wallet types
            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain_inner = bdk_wallet.lock().await;
                self.inner
                    .maintenance_with_onchain_delegated(&mut *onchain_inner)
                    .await?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain_inner = callback_adapter.lock().await;
                self.inner
                    .maintenance_with_onchain_delegated(&mut *onchain_inner)
                    .await?;
            } else {
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                });
            }
            Ok(())
        })
    }

    // ------------------------------------------------------------------------
    // Address Generation
    // ------------------------------------------------------------------------

    /// Generate a new Ark address for receiving payments
    pub fn new_address(&self) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = self.inner.new_address().await?;
            Ok(addr.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    /// Get detailed wallet balance
    pub fn balance(&self) -> Result<Balance, BarkError> {
        TOKIO_RT.block_on(async { Ok(self.inner.balance().await?.into()) })
    }

    /// List all unspent VTXOs in the wallet
    pub fn vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    // ------------------------------------------------------------------------
    // Offboarding
    // ------------------------------------------------------------------------

    /// Offboard all spendable VTXOs to a Bitcoin address
    pub fn offboard_all(&self, bitcoin_address: String) -> Result<OffboardResult, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = bitcoin_address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let status = self.inner.offboard_all(addr).await?;

            // Convert RoundStatus to a displayable round ID
            let round_id = format!("{:?}", status);

            Ok(OffboardResult { round_id })
        })
    }
    // ------------------------------------------------------------------------
    // Lightning Payments (Send)
    // ------------------------------------------------------------------------

    /// Pay a BOLT11 Lightning invoice
    pub fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
    ) -> Result<LightningSend, BarkError> {
        TOKIO_RT.block_on(async {
            let invoice: Bolt11Invoice =
                invoice.parse().map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("invalid invoice: {}", e),
                })?;

            let amount = amount_sats.map(bitcoin::Amount::from_sat);

            let lightning_send = self.inner.pay_lightning_invoice(invoice, amount).await?;

            Ok(lightning_send.into())
        })
    }

    /// Pay to a Lightning Address (LNURL)
    pub fn pay_lightning_address(
        &self,
        lightning_address: String,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<LightningSend, BarkError> {
        TOKIO_RT.block_on(async {
            let addr: LightningAddress =
                lightning_address
                    .parse()
                    .map_err(|e| BarkError::InvalidAddress {
                        error_message: format!("invalid lightning address: {}", e),
                    })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let lightning_send = self
                .inner
                .pay_lightning_address(&addr, amount, comment.as_deref())
                .await?;

            Ok(lightning_send.into())
        })
    }

    // ------------------------------------------------------------------------
    // Lightning Payments (Receive)
    // ------------------------------------------------------------------------

    /// Create a BOLT11 invoice to receive Lightning payment
    pub fn bolt11_invoice(&self, amount_sats: u64) -> Result<LightningInvoice, BarkError> {
        TOKIO_RT.block_on(async {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let invoice = self.inner.bolt11_invoice(amount).await?;

            Ok(LightningInvoice {
                invoice: invoice.to_string(),
                amount_sats,
            })
        })
    }

    /// Try to claim all pending Lightning receives
    pub fn try_claim_all_lightning_receives(&self, wait: bool) -> Result<Vec<LightningReceive>, BarkError> {
        TOKIO_RT.block_on(async {
            let receives = self.inner.try_claim_all_lightning_receives(wait).await?;
            Ok(receives.into_iter().map(Into::into).collect())
        })
    }

    // ------------------------------------------------------------------------
    // Arkoor Payments
    // ------------------------------------------------------------------------

    /// Send an out-of-round payment to an Ark address
    pub fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr: ark_lib::Address =
                ark_address.parse().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid ark address: {}", e),
                })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let vtxos = self.inner.send_arkoor_payment(&addr, amount).await?;
            Ok(vtxos
                .first()
                .ok_or_else(|| anyhow::anyhow!("Payment succeeded but returned no vtxos"))?
                .point()
                .txid
                .to_string())
        })
    }

    // ------------------------------------------------------------------------
    // On-chain Sends
    // ------------------------------------------------------------------------

    /// Send to an onchain address using your offchain balance
    ///
    /// Returns the transaction ID (txid)
    pub fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let txid = self.inner.send_onchain(addr, amount).await?;
            Ok(txid.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Extended Address Management
    // ------------------------------------------------------------------------

    /// Generate a new address and return it with its index
    pub fn new_address_with_index(&self) -> Result<AddressWithIndex, BarkError> {
        TOKIO_RT.block_on(async {
            let (addr, index) = self.inner.new_address_with_index().await?;
            Ok(AddressWithIndex {
                address: addr.to_string(),
                index,
            })
        })
    }

    /// Peek at an address at a specific index
    pub fn peek_address(&self, index: u32) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = self.inner.peek_address(index).await?;
            Ok(addr.to_string())
        })
    }

    /// Peek at an address at a specific index
	#[deprecated(since = "0.1.0-beta.9", note = "use peek_address")]
    pub fn peak_address(&self, index: u32) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = self.inner.peek_address(index).await?;
            Ok(addr.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Movement History
    // ------------------------------------------------------------------------

    /// Get all wallet movements (transaction history)
    pub fn history(&self) -> Result<Vec<Movement>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .history()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    // ------------------------------------------------------------------------
    // Extended VTXO Queries
    // ------------------------------------------------------------------------

    /// Get a specific VTXO by ID
    pub fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<Vtxo, BarkError> {
        TOKIO_RT.block_on(async {
            let id = vtxo_id.parse().map_err(|e| BarkError::InvalidAddress {
                error_message: format!("invalid vtxo id: {}", e),
            })?;
            Ok(self.inner.get_vtxo_by_id(id).await?.into())
        })
    }

    /// Get all spendable VTXOs
    pub fn spendable_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .spendable_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get all VTXOs (including spent)
    pub fn all_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .all_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get VTXOs expiring within threshold blocks
    pub fn get_expiring_vtxos(&self, threshold_blocks: u32) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .get_expiring_vtxos(threshold_blocks)
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get VTXOs that should be refreshed
    pub fn get_vtxos_to_refresh(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .get_vtxos_to_refresh()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    // ------------------------------------------------------------------------
    // Extended Offboarding
    // ------------------------------------------------------------------------

    /// Offboard specific VTXOs to a Bitcoin address
    pub fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = bitcoin_address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();

            let status = self.inner.offboard_vtxos(ids?, addr).await?;
            Ok(format!("{:?}", status))
        })
    }

    // ------------------------------------------------------------------------
    // VTXO Refresh
    // ------------------------------------------------------------------------

    /// Refresh specific VTXOs
    pub fn refresh_vtxos(&self, vtxo_ids: Vec<String>) -> Result<Option<String>, BarkError> {
        TOKIO_RT.block_on(async {
            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();

            let result = self.inner.refresh_vtxos(ids?).await?;
            Ok(result.map(|s| format!("{:?}", s)))
        })
    }

    /// Perform maintenance refresh
    pub fn maintenance_refresh(&self) -> Result<Option<String>, BarkError> {
        TOKIO_RT.block_on(async {
            let result = self.inner.maintenance_refresh().await?;
            Ok(result.map(|s| format!("{:?}", s)))
        })
    }

    /// Refresh VTXOs in delegated (non-interactive) mode
    ///
    /// Returns the round state ID if a refresh was scheduled, None otherwise.
    pub fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<RoundState>, BarkError> {
        TOKIO_RT.block_on(async {
            // Parse vtxo IDs similar to refresh_vtxos
            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|s| s.parse::<ark_lib::VtxoId>())
                .collect();
            let ids = ids.map_err(|e| BarkError::InvalidVtxoId {
                error_message: e.to_string(),
            })?;

            let state = self
                .inner
                .refresh_vtxos_delegated(ids)
                .await
                .map_err(BarkError::from)?;

            Ok(state.map(|s| s.into()))
        })
    }

    // ------------------------------------------------------------------------
    // Extended Lightning
    // ------------------------------------------------------------------------

    /// Get all pending lightning sends
    pub fn pending_lightning_sends(&self) -> Result<Vec<LightningSend>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_lightning_sends()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get all pending lightning receives
    pub fn pending_lightning_receives(&self) -> Result<Vec<LightningReceive>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_lightning_receives()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get claimable lightning receive balance
    pub fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .claimable_lightning_receive_balance()
                .await?
                .to_sat())
        })
    }

    /// Pay a BOLT12 lightning offer
    ///
    /// # Arguments
    ///
    /// * `offer` - BOLT12 offer string
    /// * `amount_sats` - Optional amount in sats (required if offer doesn't specify amount)
    pub fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
    ) -> Result<crate::LightningSend, BarkError> {
        TOKIO_RT.block_on(async {
            use ark_lib::lightning::Offer;
            use std::str::FromStr;

            let offer_obj = Offer::from_str(&offer).map_err(|e| BarkError::InvalidInvoice {
                error_message: format!("Invalid BOLT12 offer: {:?}", e),
            })?;

            let amount = amount_sats.map(bitcoin::Amount::from_sat);

            self.inner
                .pay_lightning_offer(offer_obj, amount)
                .await
                .map(Into::into)
                .map_err(Into::into)
        })
    }

    /// Check lightning payment status by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    /// * `wait` - Whether to wait for the payment to complete
    ///
    /// Returns the preimage if payment is successful, None if still pending
    pub fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<Option<String>, BarkError> {
        TOKIO_RT.block_on(async {
            use ark_lib::lightning::PaymentHash;
            use bitcoin::hex::FromHex;

            let hash_bytes =
                <[u8; 32]>::from_hex(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            let payment_hash_obj = PaymentHash::from_byte_array(hash_bytes);

            let payment = self
                .inner
                .check_lightning_payment(payment_hash_obj, wait)
                .await?;

            Ok(payment.and_then(|p| p.preimage).map(|p| p.to_string()))
        })
    }

    /// Get lightning receive status by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    pub fn lightning_receive_status(
        &self,
        payment_hash: String,
    ) -> Result<Option<crate::LightningReceive>, BarkError> {
        TOKIO_RT.block_on(async {
            use ark_lib::lightning::PaymentHash;
            use bitcoin::hex::FromHex;

            let hash_bytes =
                <[u8; 32]>::from_hex(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            let payment_hash_obj = PaymentHash::from_byte_array(hash_bytes);

            Ok(self
                .inner
                .lightning_receive_status(payment_hash_obj)
                .await?
                .map(Into::into))
        })
    }

    /// Try to claim a specific lightning receive by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    /// * `wait` - Whether to wait for claim to complete
    pub fn try_claim_lightning_receive(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            use ark_lib::lightning::PaymentHash;
            use bitcoin::hex::FromHex;

            let hash_bytes =
                <[u8; 32]>::from_hex(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            let payment_hash_obj = PaymentHash::from_byte_array(hash_bytes);

            self.inner
                .try_claim_lightning_receive(payment_hash_obj, wait, None)
                .await?;

            Ok(())
        })
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------

    /// Get read-only wallet properties
    pub fn properties(&self) -> Result<WalletProperties, BarkError> {
        TOKIO_RT.block_on(async { Ok(self.inner.properties().await?.into()) })
    }

    /// Get the wallet's BIP32 fingerprint
    pub fn fingerprint(&self) -> String {
        self.inner.fingerprint().to_string()
    }

    /// Get the Bitcoin network this wallet is using
    pub fn network(&self) -> Result<Network, BarkError> {
        TOKIO_RT.block_on(async { Ok(self.inner.network().await?.into()) })
    }

    /// Get wallet config
    pub fn config(&self) -> Config {
        TOKIO_RT.block_on(async {
            let cfg = self.inner.config();
            let props = self.inner.properties().await.unwrap();
            Config {
                server_address: cfg.server_address.clone(),
                esplora_address: cfg.esplora_address.clone(),
                bitcoind_address: cfg.bitcoind_address.clone(),
                bitcoind_cookiefile: cfg
                    .bitcoind_cookiefile
                    .as_ref()
                    .map(|p| p.to_string_lossy().to_string()),
                bitcoind_user: cfg.bitcoind_user.clone(),
                bitcoind_pass: cfg.bitcoind_pass.clone(),
                network: props.network.into(),
                vtxo_refresh_expiry_threshold: Some(cfg.vtxo_refresh_expiry_threshold),
                vtxo_exit_margin: Some(cfg.vtxo_exit_margin),
                htlc_recv_claim_delta: Some(cfg.htlc_recv_claim_delta),
                fallback_fee_rate: cfg.fallback_fee_rate.map(|r| r.to_sat_per_kwu()),
                round_tx_required_confirmations: Some(cfg.round_tx_required_confirmations),
            }
        })
    }

    /// Get the mailbox identifier for push notifications
    ///
    /// This identifier can be registered with a push notification service
    /// to receive alerts when VTXOs arrive in your mailbox. The mailbox
    /// receives all incoming VTXOs regardless of source (arkoor payments,
    /// Lightning receives, or round outputs).
    ///
    /// Returns the mailbox identifier as a hex-encoded public key.
    pub fn mailbox_identifier(&self) -> Result<String, BarkError> {
        let keypair = self.inner.mailbox_keypair();

        let identifier = ark_lib::mailbox::MailboxIdentifier::from_pubkey(keypair.public_key());
        Ok(hex::encode(identifier.to_vec()))
    }

    /// Get Ark server info
    pub fn ark_info(&self) -> Option<ArkInfo> {
        TOKIO_RT.block_on(async {
            match self.inner.ark_info().await {
                Ok(Some(info)) => Some((&info).into()),
                _ => None,
            }
        })
    }

    /// Get the timestamp when the next round will start (Unix timestamp in seconds)
    /// Returns an error if the server hasn't provided round timing info
    pub fn next_round_start_time(&self) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let system_time = self.inner.next_round_start_time().await?;
            Ok(system_time
                .duration_since(std::time::UNIX_EPOCH)
                .expect("next round time should be after Unix epoch")
                .as_secs())
        })
    }

    // ------------------------------------------------------------------------
    // Boarding (requires onchain wallet)
    // ------------------------------------------------------------------------

    /// Board a specific amount from onchain wallet into Ark
    ///
    /// Creates a board transaction that moves funds from the onchain wallet
    /// into the Ark. The board transaction must confirm on-chain and be
    /// registered with the Ark server before the funds become spendable.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet to fund the board from
    /// * `amount_sats` - Amount to board in satoshis
    ///
    /// Returns information about the pending board transaction
    pub fn board_amount(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
        amount_sats: u64,
    ) -> Result<crate::PendingBoard, BarkError> {
        TOKIO_RT.block_on(async {
            let amount = bitcoin::Amount::from_sat(amount_sats);

            eprintln!("[BOARD] Boarding {} sats into Ark...", amount_sats);

            let pb = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                self.inner
                    .board_amount(&mut *onchain, amount)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board failed: {}", e),
                    })?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                self.inner
                    .board_amount(&mut *onchain, amount)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board failed: {}", e),
                    })?
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Boarding requires a valid onchain wallet. Create one with OnchainWallet.default() or OnchainWallet.custom()".to_string(),
                });
            };

            let txid = pb.funding_tx.compute_txid();
            let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();

            eprintln!(
                "[BOARD] ✅ Board transaction created: {} (VTXO ID: {})",
                txid, vtxo_id
            );

            Ok(pb.into())
        })
    }

    /// Board all funds from onchain wallet into Ark
    ///
    /// Creates a board transaction that moves all available funds from the
    /// onchain wallet into the Ark. The board transaction must confirm
    /// on-chain and be registered with the Ark server before the funds
    /// become spendable.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet to drain funds from
    ///
    /// Returns information about the pending board transaction
    pub fn board_all(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<crate::PendingBoard, BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[BOARD] Boarding ALL funds into Ark...");

            let pb = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                self.inner
                    .board_all(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board all failed: {}", e),
                    })?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                self.inner
                    .board_all(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board all failed: {}", e),
                    })?
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Boarding requires a valid onchain wallet. Create one with OnchainWallet.default() or OnchainWallet.custom()".to_string(),
                });
            };

            let txid = pb.funding_tx.compute_txid();
            let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();

            eprintln!(
                "[BOARD] ✅ Board transaction created: {} (VTXO ID: {}, amount: {} sats)",
                txid,
                vtxo_id,
                pb.amount.to_sat()
            );

            Ok(pb.into())
        })
    }

    /// Sync pending board transactions
    ///
    /// Checks if pending board transactions have sufficient confirmations
    /// and attempts to register them with the Ark server. Once registered,
    /// the boarded VTXOs become spendable.
    ///
    /// Call this periodically after creating board transactions.
    pub fn sync_pending_boards(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[BOARD] Syncing pending boards...");

            self.inner
                .sync_pending_boards()
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Sync pending boards failed: {}", e),
                })?;

            eprintln!("[BOARD] ✅ Pending boards synced");

            Ok(())
        })
    }

    /// Get all pending board operations
    pub fn pending_boards(&self) -> Result<Vec<PendingBoard>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_boards()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get all VTXOs that are part of pending boards
    pub fn pending_board_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_board_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get VTXOs being used as inputs in pending rounds
    pub fn pending_round_input_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_round_input_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get VTXOs locked in pending Lightning sends
    pub fn pending_lightning_send_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_lightning_send_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    // ------------------------------------------------------------------------
    // Unilateral Exits (requires onchain wallet)
    // ------------------------------------------------------------------------

    /// Start unilateral exit for the entire wallet
    ///
    /// Initiates the emergency exit process for all eligible VTXOs in the
    /// wallet. This does NOT complete the exit - you must call `sync_exits`
    /// periodically to progress the exit state machine.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet for building exit transactions
    ///
    /// Recommended to call `maintenance()` or `sync()` before starting exits.
    pub fn start_exit_for_entire_wallet(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[EXIT] Starting unilateral exit for entire wallet...");

            self.inner
                .exit
                .write()
                .await
                .start_exit_for_entire_wallet()
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Start exit failed: {}", e),
                })?;

            eprintln!("[EXIT] ✅ Exit initiated - call sync_exits() periodically to progress");

            Ok(())
        })
    }

    /// Sync exit state
    ///
    /// Checks the status of pending unilateral exits and updates their state.
    /// Call this periodically after starting exits to monitor progress.
    ///
    /// This does NOT progress exits (broadcast transactions, fee bump, etc.).
    /// For that, use progress_exits.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet for checking transaction state
    pub fn sync_exits(&self, onchain_wallet: Arc<crate::OnchainWallet>) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[EXIT] Syncing exits...");

            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                self.inner
                    .sync_exits(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Sync exits failed: {}", e),
                    })?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                self.inner
                    .sync_exits(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Sync exits failed: {}", e),
                    })?;
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Syncing exits requires a valid onchain wallet. Create one with OnchainWallet.default() or OnchainWallet.custom()".to_string(),
                });
            }

            eprintln!("[EXIT] ✅ Exits synced");

            Ok(())
        })
    }

    /// Progress unilateral exits
    ///
    /// Advances the state machine for all pending exits. This will broadcast transactions,
    /// perform fee bumping (CPFP), and update the exit state until exits become claimable.
    ///
    /// Call this periodically after starting exits to actually move them forward.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet for building exit transactions
    /// * `fee_rate_sat_per_vb` - Optional fee rate override in sats per vbyte
    ///
    /// Returns a list of exit progress statuses
    pub fn progress_exits(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<crate::ExitProgressStatus>, BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[EXIT] Progressing exits...");

            let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

            let result = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                self.inner
                    .exit
                    .write()
                    .await
                    .progress_exits(&self.inner, &mut *onchain, fee_rate)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Progress exits failed: {}", e),
                    })?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                self.inner
                    .exit
                    .write()
                    .await
                    .progress_exits(&self.inner, &mut *onchain, fee_rate)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Progress exits failed: {}", e),
                    })?
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Progressing exits requires a valid onchain wallet".to_string(),
                });
            };

            let statuses = result
                .unwrap_or_default()
                .into_iter()
                .map(Into::into)
                .collect();

            eprintln!("[EXIT] ✅ Exits progressed");

            Ok(statuses)
        })
    }

    /// Start unilateral exit for specific VTXOs
    ///
    /// Initiates the emergency exit process for the specified VTXOs.
    /// You must call `progress_exits` periodically to actually advance the exit.
    ///
    /// # Arguments
    ///
    /// * `vtxo_ids` - List of VTXO IDs to exit
    pub fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[EXIT] Starting exit for {} VTXOs...", vtxo_ids.len());

            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();

            let mut vtxos = Vec::new();
            for id in ids? {
                let vtxo =
                    self.inner
                        .get_vtxo_by_id(id)
                        .await
                        .map_err(|e| BarkError::NotFound {
                            error_message: format!("VTXO not found: {}", e),
                        })?;
                vtxos.push(vtxo);
            }

            let vtxo_refs: Vec<&ark_lib::Vtxo> = vtxos.iter().map(|v| &v.vtxo).collect();

            self.inner
                .exit
                .write()
                .await
                .start_exit_for_vtxos(&vtxo_refs)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Start exit for VTXOs failed: {}", e),
                })?;

            eprintln!("[EXIT] ✅ Exit initiated for {} VTXOs", vtxo_ids.len());

            Ok(())
        })
    }

    /// List all claimable exits
    ///
    /// Returns all exits that are ready to be claimed (funds can be moved to onchain wallet).
    pub fn list_claimable_exits(&self) -> Result<Vec<crate::ExitVtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            let exit_guard = self.inner.exit.read().await;
            let claimable = exit_guard.list_claimable();
            Ok(claimable.into_iter().map(Into::into).collect())
        })
    }

    /// Get all exit VTXOs
    ///
    /// Returns all VTXOs that are currently in the exit process.
    pub fn get_exit_vtxos(&self) -> Result<Vec<crate::ExitVtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            let exit_guard = self.inner.exit.read().await;
            Ok(exit_guard.get_exit_vtxos().iter().map(Into::into).collect())
        })
    }

    /// Check if there are any pending exits
    pub fn has_pending_exits(&self) -> Result<bool, BarkError> {
        TOKIO_RT.block_on(async {
            let exit_guard = self.inner.exit.read().await;
            Ok(exit_guard.has_pending_exits())
        })
    }

    /// Get total amount in pending exits (in sats)
    pub fn pending_exits_total_sats(&self) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let exit_guard = self.inner.exit.read().await;
            Ok(exit_guard.pending_total().to_sat())
        })
    }

    /// Get earliest block height when all exits will be claimable
    ///
    /// Returns None if no exits are tracked or if any exit cannot be determined.
    pub fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, BarkError> {
        TOKIO_RT.block_on(async {
            let exit_guard = self.inner.exit.read().await;
            Ok(exit_guard.all_claimable_at_height().await)
        })
    }

    /// Get detailed exit status for a specific VTXO
    ///
    /// Returns detailed status including current state, history, and transactions.
    ///
    /// # Arguments
    ///
    /// * `vtxo_id` - The VTXO ID to check
    /// * `include_history` - Whether to include full state machine history
    /// * `include_transactions` - Whether to include transaction details
    pub fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<crate::ExitTransactionStatus>, BarkError> {
        TOKIO_RT.block_on(async {
            let vtxo_id_parsed =
                vtxo_id
                    .parse::<ark_lib::VtxoId>()
                    .map_err(|e| BarkError::InvalidAddress {
                        error_message: format!("invalid vtxo id: {}", e),
                    })?;

            let exit_guard = self.inner.exit.read().await;
            let status = exit_guard
                .get_exit_status(vtxo_id_parsed, include_history, include_transactions)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Get exit status failed: {}", e),
                })?;

            Ok(status.map(Into::into))
        })
    }

    /// Drain claimable exits to an address
    ///
    /// Builds a PSBT that claims all claimable exit funds and sends them to the specified address.
    /// The PSBT is already signed and can be broadcast directly.
    ///
    /// # Arguments
    ///
    /// * `vtxo_ids` - List of claimable VTXO IDs to claim
    /// * `address` - Bitcoin address to send the claimed funds to
    /// * `fee_rate_sat_per_vb` - Optional fee rate override in sats per vbyte
    ///
    /// Returns a signed transaction ready to broadcast
    pub fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<crate::ExitClaimTransaction, BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[EXIT] Draining {} exits to {}...", vtxo_ids.len(), address);

            let addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

            let exit_guard = self.inner.exit.read().await;
            let claimable = exit_guard.list_claimable();

            // Filter to requested VTXO IDs
            let to_drain: Vec<_> = if vtxo_ids.is_empty() {
                claimable
            } else {
                let requested_ids: std::collections::HashSet<_> = vtxo_ids
                    .iter()
                    .filter_map(|id| id.parse::<ark_lib::VtxoId>().ok())
                    .collect();
                claimable
                    .into_iter()
                    .filter(|ev| requested_ids.contains(&ev.id()))
                    .collect()
            };

            if to_drain.is_empty() {
                return Err(BarkError::NotFound {
                    error_message: "No claimable exits found".to_string(),
                });
            }

            let psbt = exit_guard
                .drain_exits(&to_drain, &self.inner, addr, fee_rate)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Drain exits failed: {}", e),
                })?;

            let fee_sats = psbt.fee().map_err(|e| BarkError::Internal {
                error_message: format!("Failed to get fee: {}", e),
            })?;

            // PSBT serialization
            let psbt_bytes = psbt.serialize();
            use bitcoin::base64::prelude::*;
            let psbt_base64 = BASE64_STANDARD.encode(&psbt_bytes);

            eprintln!(
                "[EXIT] ✅ Drain PSBT created (fee: {} sats)",
                fee_sats.to_sat()
            );

            Ok(crate::ExitClaimTransaction {
                psbt_base64,
                fee_sats: fee_sats.to_sat(),
            })
        })
    }

    // ------------------------------------------------------------------------
    // Round Management
    // ------------------------------------------------------------------------

    /// Get all pending round states
    pub fn pending_round_states(&self) -> Result<Vec<crate::RoundState>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .pending_round_states()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Cancel a specific pending round
    ///
    /// # Arguments
    ///
    /// * `round_id` - The ID of the round to cancel
    pub fn cancel_pending_round(&self, round_id: u32) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            use bark::persist::models::RoundStateId;
            self.inner
                .cancel_pending_round(RoundStateId(round_id))
                .await?;
            Ok(())
        })
    }

    /// Cancel all pending rounds
    pub fn cancel_all_pending_rounds(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.cancel_all_pending_rounds().await?;
            Ok(())
        })
    }

    /// Progress pending rounds
    ///
    /// Advances the state of all pending rounds. Call this periodically.
    pub fn progress_pending_rounds(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.progress_pending_rounds(None).await?;
            Ok(())
        })
    }

    // ------------------------------------------------------------------------
    // Extended Lightning & Misc
    // ------------------------------------------------------------------------

    /// Refresh the server connection
    ///
    /// Re-establishes connection to the Ark server if it was lost.
    pub fn refresh_server(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.refresh_server().await?;
            Ok(())
        })
    }

    /// Validate an Ark address against the connected server
    ///
    /// This performs a full validation including checking if the address
    /// belongs to the currently connected Ark server.
    ///
    /// # Arguments
    ///
    /// * `address` - The Ark address to validate
    pub fn validate_arkoor_address(&self, address: String) -> Result<bool, BarkError> {
        TOKIO_RT.block_on(async {
            let addr: ark_lib::Address =
                address.parse().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid ark address: {}", e),
                })?;

            match self.inner.validate_arkoor_address(&addr).await {
                Ok(_) => Ok(true),
                Err(_) => Ok(false),
            }
        })
    }

    // ------------------------------------------------------------------------
    // VTXO Expiry & Refresh Scheduling
    // ------------------------------------------------------------------------

    /// Get the block height of the first expiring VTXO
    ///
    /// Returns None if there are no spendable VTXOs.
    pub fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, BarkError> {
        TOKIO_RT.block_on(async { Ok(self.inner.get_first_expiring_vtxo_blockheight().await?) })
    }

    /// Get the next block height when a refresh should be performed
    ///
    /// This is calculated as the first expiring VTXO height minus the refresh threshold.
    /// Returns None if there are no VTXOs to refresh.
    pub fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, BarkError> {
        TOKIO_RT.block_on(async { Ok(self.inner.get_next_required_refresh_blockheight().await?) })
    }

    /// Schedule a maintenance refresh if VTXOs need refreshing
    ///
    /// Returns the round ID if a refresh was scheduled, None otherwise.
    pub fn maybe_schedule_maintenance_refresh(&self) -> Result<Option<u32>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .maybe_schedule_maintenance_refresh()
                .await?
                .map(|id| id.0))
        })
    }

    // ------------------------------------------------------------------------
    // Advanced Exit Methods
    // ------------------------------------------------------------------------

    /// Sign exit claim inputs in an external PSBT
    ///
    /// This is useful if you want to combine exit claims with other inputs
    /// in a single transaction.
    ///
    /// # Arguments
    ///
    /// * `psbt_base64` - Base64-encoded PSBT to sign
    ///
    /// Returns the signed PSBT
    pub fn sign_exit_claim_inputs(&self, psbt_base64: String) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            use bitcoin::base64::prelude::*;
            use bitcoin::psbt::Psbt;

            let psbt_bytes =
                BASE64_STANDARD
                    .decode(&psbt_base64)
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Invalid base64: {}", e),
                    })?;

            let mut psbt = Psbt::deserialize(&psbt_bytes).map_err(|e| BarkError::Internal {
                error_message: format!("Invalid PSBT: {}", e),
            })?;

            let exit_guard = self.inner.exit.read().await;
            exit_guard
                .sign_exit_claim_inputs(&mut psbt, &self.inner)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Sign exit claim inputs failed: {}", e),
                })?;

            let signed_psbt_bytes = psbt.serialize();
            Ok(BASE64_STANDARD.encode(&signed_psbt_bytes))
        })
    }

    // ------------------------------------------------------------------------
    // Transaction Broadcasting
    // ------------------------------------------------------------------------

    /// Broadcast a signed transaction to the Bitcoin network
    ///
    /// Takes a hex-encoded transaction and broadcasts it via the wallet's chain source.
    /// This is useful after extracting a transaction from a PSBT.
    ///
    /// # Arguments
    ///
    /// * `tx_hex` - Hex-encoded signed transaction
    ///
    /// # Example
    ///
    /// ```ignore
    /// let psbt = wallet.drain_exits(vtxo_ids, address, None)?;
    /// let tx_hex = extract_tx_from_psbt(psbt.psbt_base64)?;
    /// let txid = wallet.broadcast_tx(tx_hex)?;
    /// ```
    ///
    /// Returns the transaction ID (txid) of the broadcasted transaction
    pub fn broadcast_tx(&self, tx_hex: String) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            use bitcoin::consensus::encode::deserialize_hex;
            use bitcoin::Transaction;

            let tx: Transaction =
                deserialize_hex(&tx_hex).map_err(|e| BarkError::InvalidTransaction {
                    error_message: format!("{}", e),
                })?;

            let txid = tx.compute_txid();

            eprintln!("[BROADCAST] Broadcasting transaction: {}", txid);

            self.inner
                .chain
                .broadcast_tx(&tx)
                .await
                .map_err(|e| BarkError::Network {
                    error_message: format!("Broadcast failed: {}", e),
                })?;

            eprintln!("[BROADCAST] Transaction broadcasted successfully");

            Ok(txid.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Mailbox Authorization
    // ------------------------------------------------------------------------

    /// Create a new authorization for your server mailbox
    pub fn mailbox_authorization(&self) -> Result<String, BarkError> {
        use ark_lib::ProtocolEncoding;

        // Default expiry: 24 hours from now
        let expiry = chrono::Local::now() + chrono::Duration::hours(24);

        let auth = self.inner.mailbox_authorization(expiry);

        Ok(hex::encode(auth.serialize()))
    }

    // ------------------------------------------------------------------------
    // VTXO Import
    // ------------------------------------------------------------------------

    /// Import a serialized VTXO into the wallet
    pub fn import_vtxo(&self, vtxo_base64: String) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            use ark_lib::ProtocolEncoding;
            use base64::Engine;

            let vtxo_bytes =
                base64::engine::general_purpose::STANDARD
                    .decode(&vtxo_base64)
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Invalid base64: {}", e),
                    })?;

            let vtxo =
                ark_lib::Vtxo::deserialize(&vtxo_bytes).map_err(|e| BarkError::Internal {
                    error_message: format!("Invalid VTXO data: {}", e),
                })?;

            self.inner
                .import_vtxo(&vtxo)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Failed to import VTXO: {}", e),
                })?;

            eprintln!("[IMPORT] VTXO imported successfully");
            Ok(())
        })
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    /// Estimate the fee for a board operation
    pub fn estimate_board_fee(&self, amount_sats: u64) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let fee = self
                .inner
                .estimate_board_offchain_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(fee.fee.to_sat())
        })
    }

    /// Estimate the fee for an offboard operation
    pub fn estimate_offboard_fee(&self, address: String, vtxo_ids: Vec<String>) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let btc_addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Failed to parse address: {}", e),
                })?
                .assume_checked();

            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidVtxoId {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();
            let ids = ids?;

            let mut vtxos = Vec::new();
            for id in ids {
                let vtxo = self.inner.get_vtxo_by_id(id).await.map_err(|e| {
                    BarkError::NotFound {
                        error_message: format!("VTXO not found: {}", e),
                    }
                })?;
                vtxos.push(vtxo);
            }

            let fee = self
                .inner
                .estimate_offboard(&btc_addr, &vtxos)
                .await
                .map_err(BarkError::from)?;
            Ok(fee.fee.to_sat())
        })
    }

    /// Estimate the fee for a refresh operation
    pub fn estimate_refresh_fee(&self, vtxo_ids: Vec<String>) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidVtxoId {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();
            let ids = ids?;

            // Look up the actual VTXOs from the wallet
            let mut vtxos = Vec::new();
            for id in ids {
                let vtxo = self.inner.get_vtxo_by_id(id).await.map_err(|e| {
                    BarkError::NotFound {
                        error_message: format!("VTXO not found: {}", e),
                    }
                })?;
                vtxos.push(vtxo);
            }

            let fee = self
                .inner
                .estimate_refresh_fee(&vtxos)
                .await
                .map_err(BarkError::from)?;
            Ok(fee.fee.to_sat())
        })
    }

    /// Estimate the fee for a lightning send
    pub fn estimate_lightning_send_fee(&self, amount_sats: u64) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let fee = self
                .inner
                .estimate_lightning_send_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(fee.fee.to_sat())
        })
    }

    /// Estimate the fee for a lightning receive
    pub fn estimate_lightning_receive_fee(&self, amount_sats: u64) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let fee = self
                .inner
                .estimate_lightning_receive_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(fee.fee.to_sat())
        })
    }

    /// Estimate the fee for a send onchain operation
    pub fn estimate_send_onchain_fee(&self, address: String, amount_sats: u64) -> Result<u64, BarkError> {
        TOKIO_RT.block_on(async {
            let btc_addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Failed to parse address: {}", e),
                })?
                .assume_checked();

            let amount = bitcoin::Amount::from_sat(amount_sats);
            let fee = self
                .inner
                .estimate_send_onchain(&btc_addr, amount)
                .await
                .map_err(BarkError::from)?;
            Ok(fee.fee.to_sat())
        })
    }
}
