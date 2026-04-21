use std::str::FromStr;
use std::sync::Arc;

use anyhow::Context;
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;
use lnurl::lightning_address::LightningAddress;
use tokio_util::sync::CancellationToken;

use ark_lib::lightning::PaymentHash;
use bark::lightning_invoice::Bolt11Invoice;
use bark::Wallet as InnerWallet;

use crate::error::BarkError;
use crate::notification::NotificationHolder;
use crate::runtime::{run_async, TOKIO_RT};
use crate::types::*;

/// The main Bark wallet interface
pub struct Wallet {
    inner: Arc<InnerWallet>,
    mailbox_task: Option<tokio::task::JoinHandle<()>>,
    /// Held to keep the token alive; dropping cancels the mailbox task.
    #[allow(dead_code)]
    mailbox_cancel: CancellationToken,
}

impl Wallet {
    fn from_inner(inner: InnerWallet) -> Self {
        let inner = Arc::new(inner);
        let cancel = CancellationToken::new();
        let mailbox_task = Some(Self::start_mailbox_processor(inner.clone(), cancel.clone()));
        Self {
            inner,
            mailbox_task,
            mailbox_cancel: cancel,
        }
    }

    /// Create a new Bark wallet
    pub async fn create(
        mnemonic: String,
        config: Config,
        datadir: String,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        run_async(async move {
            let inner = Self::create_async(mnemonic, config, datadir, force_rescan).await?;
            Ok(Self::from_inner(inner))
        })
        .await
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
    pub async fn open(
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<Self, BarkError> {
        run_async(async move {
            let inner = Self::open_async(mnemonic, config, datadir).await?;
            Ok(Self::from_inner(inner))
        })
        .await
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
            eprintln!("[OPEN] ⚠️  WARNING: Server connection FAILED - Lightning and Ark \
                operations will not work!");
        }

        Ok(inner)
    }

    /// Create a new Bark wallet WITH onchain capabilities
    pub async fn create_with_onchain(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Arc<crate::OnchainWallet>,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        run_async(async move {
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

            Ok(Self::from_inner(inner))
        })
        .await
    }

    /// Open an existing Bark wallet WITH onchain capabilities
    pub async fn open_with_onchain(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<Self, BarkError> {
        run_async(async move {
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
                eprintln!("[OPEN] ⚠️  WARNING: Server connection FAILED - Lightning and Ark \
                    operations will not work!");
            }

            eprintln!("[OPEN] ✅ Bark wallet with onchain opened successfully");

            Ok(Self::from_inner(inner))
        }).await
    }

    // ------------------------------------------------------------------------
    // Synchronization & Maintenance
    // ------------------------------------------------------------------------

    /// Lightweight sync with Ark server and blockchain
    ///
    /// Note: Bark's upstream `sync()` returns `()` and handles all errors
    /// internally with warn!() logging. This wrapper cannot surface sync
    /// failures to callers - they are logged internally by Bark.
    pub async fn sync(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[SYNC] Starting sync...");
            inner.sync().await;
            eprintln!("[SYNC] Sync completed");

            // Log balance after sync
            if let Ok(balance) = inner.balance().await {
                eprintln!(
                    "[SYNC] Balance after sync: spendable={}, pending_board={}",
                    balance.spendable.to_sat(),
                    balance.pending_board.to_sat()
                );
            }

            // Log VTXO count
            if let Ok(vtxos) = inner.vtxos().await {
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
        .await
    }

    /// Full maintenance: sync + refresh VTXOs if necessary
    pub async fn maintenance(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            inner.maintenance().await?;
            Ok(())
        })
        .await
    }

    /// Perform full maintenance including onchain sync
    ///
    /// This is more thorough than `maintenance()` as it also syncs the onchain wallet
    /// and the exit system.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet to sync
    pub async fn maintenance_with_onchain(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                inner.maintenance_with_onchain(&mut *onchain).await?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                inner.maintenance_with_onchain(&mut *onchain).await?;
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Invalid onchain wallet".to_string(),
                });
            }
            Ok(())
        })
        .await
    }

    /// Perform maintenance in delegated (non-interactive) mode
    ///
    /// This schedules refresh operations but doesn't wait for completion.
    /// Use this when you want to queue operations without blocking.
    pub async fn maintenance_delegated(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            inner.maintenance_delegated().await?;
            Ok(())
        })
        .await
    }

    /// Perform maintenance with onchain wallet in delegated mode
    pub async fn maintenance_with_onchain_delegated(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            // Implementation similar to maintenance_with_onchain but calls
            // maintenance_with_onchain_delegated on inner wallet
            // Need to handle BDK vs Callback wallet types
            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain_inner = bdk_wallet.lock().await;
                inner
                    .maintenance_with_onchain_delegated(&mut *onchain_inner)
                    .await?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain_inner = callback_adapter.lock().await;
                inner
                    .maintenance_with_onchain_delegated(&mut *onchain_inner)
                    .await?;
            } else {
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                });
            }
            Ok(())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Address Generation
    // ------------------------------------------------------------------------

    /// Generate a new Ark address for receiving payments
    pub async fn new_address(&self) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr = inner.new_address().await?;
            Ok(addr.to_string())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    /// Get detailed wallet balance
    pub async fn balance(&self) -> Result<Balance, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.balance().await?.into()) }).await
    }

    /// List all unspent VTXOs in the wallet
    pub async fn vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.vtxos().await?.into_iter().map(Into::into).collect()) })
            .await
    }

    // ------------------------------------------------------------------------
    // Offboarding
    // ------------------------------------------------------------------------

    /// Offboard all spendable VTXOs to a Bitcoin address
    pub async fn offboard_all(&self, bitcoin_address: String) -> Result<OffboardResult, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr = bitcoin_address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let status = inner.offboard_all(addr).await?;

            // Convert RoundStatus to a displayable round ID
            let round_id = format!("{:?}", status);

            Ok(OffboardResult { round_id })
        })
        .await
    }
    // ------------------------------------------------------------------------
    // Lightning Payments (Send)
    // ------------------------------------------------------------------------

    /// Pay a BOLT11 Lightning invoice
    pub async fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
    ) -> Result<LightningSend, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let invoice: Bolt11Invoice =
                invoice.parse().map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("invalid invoice: {}", e),
                })?;

            let amount = amount_sats.map(bitcoin::Amount::from_sat);

            let lightning_send = inner.pay_lightning_invoice(invoice, amount).await?;

            Ok(lightning_send.into())
        })
        .await
    }

    /// Pay to a Lightning Address (LNURL)
    pub async fn pay_lightning_address(
        &self,
        lightning_address: String,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<LightningSend, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr: LightningAddress =
                lightning_address
                    .parse()
                    .map_err(|e| BarkError::InvalidAddress {
                        error_message: format!("invalid lightning address: {}", e),
                    })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let lightning_send = inner
                .pay_lightning_address(&addr, amount, comment.as_deref())
                .await?;

            Ok(lightning_send.into())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Lightning Payments (Receive)
    // ------------------------------------------------------------------------

    /// Create a BOLT11 invoice to receive Lightning payment
    pub async fn bolt11_invoice(&self, amount_sats: u64) -> Result<LightningInvoice, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let invoice = inner.bolt11_invoice(amount).await?;

            Ok(LightningInvoice {
                invoice: invoice.to_string(),
                amount_sats,
            })
        })
        .await
    }

    /// Try to claim all pending Lightning receives
    pub async fn try_claim_all_lightning_receives(
        &self,
        wait: bool,
    ) -> Result<Vec<LightningReceive>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let receives = inner.try_claim_all_lightning_receives(wait).await?;
            Ok(receives.into_iter().map(Into::into).collect())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Arkoor Payments
    // ------------------------------------------------------------------------

    /// Send an out-of-round payment to an Ark address
    pub async fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr: ark_lib::Address =
                ark_address.parse().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid ark address: {}", e),
                })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let vtxos = inner.send_arkoor_payment(&addr, amount).await?;
            Ok(vtxos
                .first()
                .ok_or_else(|| anyhow::anyhow!("Payment succeeded but returned no vtxos"))?
                .point()
                .txid
                .to_string())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // On-chain Sends
    // ------------------------------------------------------------------------

    /// Send to an onchain address using your offchain balance
    ///
    /// Returns the transaction ID (txid)
    pub async fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let txid = inner.send_onchain(addr, amount).await?;
            Ok(txid.to_string())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Extended Address Management
    // ------------------------------------------------------------------------

    /// Generate a new address and return it with its index
    pub async fn new_address_with_index(&self) -> Result<AddressWithIndex, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let (addr, index) = inner.new_address_with_index().await?;
            Ok(AddressWithIndex {
                address: addr.to_string(),
                index,
            })
        })
        .await
    }

    /// Peek at an address at a specific index
    pub async fn peek_address(&self, index: u32) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr = inner.peek_address(index).await?;
            Ok(addr.to_string())
        })
        .await
    }

    /// Peek at an address at a specific index
    #[deprecated(since = "0.1.0-beta.9", note = "use peek_address")]
    pub async fn peak_address(&self, index: u32) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr = inner.peek_address(index).await?;
            Ok(addr.to_string())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Movement History
    // ------------------------------------------------------------------------

    /// Get all wallet movements (transaction history)
    pub async fn history(&self) -> Result<Vec<Movement>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.history().await?.into_iter().map(Into::into).collect()) })
            .await
    }

    /// Get wallet movements filtered by payment method
    ///
    /// # Arguments
    ///
    /// * `payment_method_type` - Type of payment method
    ///   (e.g. "ark", "bitcoin", "invoice", "offer", "lightning_address", "custom")
    /// * `payment_method_value` - Value of the payment method (e.g. an address or invoice string)
    pub async fn history_by_payment_method(
        &self,
        payment_method_type: String,
        payment_method_value: String,
    ) -> Result<Vec<Movement>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let payment_method = bark::movement::PaymentMethod::from_type_value(
                &payment_method_type,
                &payment_method_value,
            )
            .map_err(|e| BarkError::Internal {
                error_message: format!("Invalid payment method: {}", e),
            })?;

            Ok(inner
                .history_by_payment_method(&payment_method)
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Extended VTXO Queries
    // ------------------------------------------------------------------------

    /// Get a specific VTXO by ID
    pub async fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<Vtxo, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let id = vtxo_id.parse().map_err(|e| BarkError::InvalidAddress {
                error_message: format!("invalid vtxo id: {}", e),
            })?;
            Ok(inner.get_vtxo_by_id(id).await?.into())
        })
        .await
    }

    /// Get all spendable VTXOs
    pub async fn spendable_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .spendable_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get all VTXOs (including spent)
    pub async fn all_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .all_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get VTXOs expiring within threshold blocks
    pub async fn get_expiring_vtxos(&self, threshold_blocks: u32) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .get_expiring_vtxos(threshold_blocks)
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get VTXOs that should be refreshed
    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .get_vtxos_to_refresh()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Extended Offboarding
    // ------------------------------------------------------------------------

    /// Offboard specific VTXOs to a Bitcoin address
    pub async fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
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

            let status = inner.offboard_vtxos(ids?, addr).await?;
            Ok(format!("{:?}", status))
        })
        .await
    }

    // ------------------------------------------------------------------------
    // VTXO Refresh
    // ------------------------------------------------------------------------

    /// Refresh specific VTXOs
    pub async fn refresh_vtxos(&self, vtxo_ids: Vec<String>) -> Result<Option<String>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();

            let result = inner.refresh_vtxos(ids?).await?;
            Ok(result.map(|s| format!("{:?}", s)))
        })
        .await
    }

    /// Perform maintenance refresh
    pub async fn maintenance_refresh(&self) -> Result<Option<String>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let result = inner.maintenance_refresh().await?;
            Ok(result.map(|s| format!("{:?}", s)))
        })
        .await
    }

    /// Refresh VTXOs in delegated (non-interactive) mode
    ///
    /// Returns the round state ID if a refresh was scheduled, None otherwise.
    pub async fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<RoundState>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            // Parse vtxo IDs similar to refresh_vtxos
            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|s| s.parse::<ark_lib::VtxoId>())
                .collect();
            let ids = ids.map_err(|e| BarkError::InvalidVtxoId {
                error_message: e.to_string(),
            })?;

            let state = inner
                .refresh_vtxos_delegated(ids)
                .await
                .map_err(BarkError::from)?;

            Ok(state.map(|s| s.into()))
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Extended Lightning
    // ------------------------------------------------------------------------

    /// Get all pending lightning sends
    pub async fn pending_lightning_sends(&self) -> Result<Vec<LightningSend>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_lightning_sends()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get all pending lightning receives
    pub async fn pending_lightning_receives(&self) -> Result<Vec<LightningReceive>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_lightning_receives()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get claimable lightning receive balance
    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.claimable_lightning_receive_balance().await?.to_sat()) })
            .await
    }

    /// Pay a BOLT12 lightning offer
    ///
    /// # Arguments
    ///
    /// * `offer` - BOLT12 offer string
    /// * `amount_sats` - Optional amount in sats (required if offer doesn't specify amount)
    pub async fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
    ) -> Result<crate::LightningSend, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            use ark_lib::lightning::Offer;
            use std::str::FromStr;

            let offer_obj = Offer::from_str(&offer).map_err(|e| BarkError::InvalidInvoice {
                error_message: format!("Invalid BOLT12 offer: {:?}", e),
            })?;

            let amount = amount_sats.map(bitcoin::Amount::from_sat);

            inner
                .pay_lightning_offer(offer_obj, amount)
                .await
                .map(Into::into)
                .map_err(Into::into)
        })
        .await
    }

    /// Check lightning payment status by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    /// * `wait` - Whether to wait for the payment to complete
    ///
    /// Returns the preimage if payment is successful, None if still pending
    pub async fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<Option<String>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let payment_hash_obj = PaymentHash::from_str(&payment_hash)
                .map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            let payment = inner
                .check_lightning_payment(payment_hash_obj, wait)
                .await?;

            Ok(payment.and_then(|p| p.preimage).map(|p| p.to_string()))
        })
        .await
    }

    /// Get lightning receive status by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    pub async fn lightning_receive_status(
        &self,
        payment_hash: String,
    ) -> Result<Option<crate::LightningReceive>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let payment_hash_obj = PaymentHash::from_str(&payment_hash)
                .map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            Ok(inner
                .lightning_receive_status(payment_hash_obj)
                .await?
                .map(Into::into))
        })
        .await
    }

    /// Try to claim a specific lightning receive by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    /// * `wait` - Whether to wait for claim to complete
    pub async fn try_claim_lightning_receive(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let payment_hash_obj = PaymentHash::from_str(&payment_hash)
                .map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            inner
                .try_claim_lightning_receive(payment_hash_obj, wait, None)
                .await?;

            Ok(())
        })
        .await
    }

    /// Cancel a pending lightning receive by payment hash
    ///
    /// # Arguments
    ///
    /// * `payment_hash` - Payment hash as hex string
    pub async fn cancel_lightning_receive(
        &self,
        payment_hash: String,
    ) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let payment_hash_obj = PaymentHash::from_str(&payment_hash)
                .map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("Invalid payment hash: {}", e),
                })?;

            inner.cancel_lightning_receive(payment_hash_obj).await?;

            Ok(())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------

    /// Get read-only wallet properties
    pub async fn properties(&self) -> Result<WalletProperties, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.properties().await?.into()) }).await
    }

    /// Get the wallet's BIP32 fingerprint
    pub fn fingerprint(&self) -> String {
        self.inner.fingerprint().to_string()
    }

    /// Get the Bitcoin network this wallet is using
    pub async fn network(&self) -> Result<Network, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.network().await?.into()) }).await
    }

    /// Get wallet config
    pub async fn config(&self) -> Config {
        let inner = self.inner.clone();
        run_async(async move {
            let cfg = inner.config();
            let props = inner.properties().await.unwrap();
            Config {
                server_address: cfg.server_address.clone(),
                server_access_token: cfg.server_access_token.clone(),
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
                daemon_fast_sync_interval_secs: Some(cfg.daemon_fast_sync_interval_secs),
                daemon_slow_sync_interval_secs: Some(cfg.daemon_slow_sync_interval_secs),
            }
        })
        .await
    }

    /// Get Ark server info
    pub async fn ark_info(&self) -> Option<ArkInfo> {
        let inner = self.inner.clone();
        run_async(async move {
            match inner.ark_info().await {
                Ok(Some(info)) => Some((&info).into()),
                _ => None,
            }
        })
        .await
    }

    /// Get the timestamp when the next round will start (Unix timestamp in seconds)
    /// Returns an error if the server hasn't provided round timing info
    pub async fn next_round_start_time(&self) -> Result<u64, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let system_time = inner.next_round_start_time().await?;
            Ok(system_time
                .duration_since(std::time::UNIX_EPOCH)
                .expect("next round time should be after Unix epoch")
                .as_secs())
        })
        .await
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
    pub async fn board_amount(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
        amount_sats: u64,
    ) -> Result<crate::PendingBoard, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let amount = bitcoin::Amount::from_sat(amount_sats);

            eprintln!("[BOARD] Boarding {} sats into Ark...", amount_sats);

            let pb = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                inner
                    .board_amount(&mut *onchain, amount)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board failed: {}", e),
                    })?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                inner
                    .board_amount(&mut *onchain, amount)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board failed: {}", e),
                    })?
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Boarding requires a valid onchain wallet. Create one with \
                        OnchainWallet.default() or OnchainWallet.custom()".to_string(),
                });
            };

            let txid = pb.funding_tx.compute_txid();
            let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();

            eprintln!(
                "[BOARD] ✅ Board transaction created: {} (VTXO ID: {})",
                txid, vtxo_id
            );

            Ok(pb.into())
        }).await
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
    pub async fn board_all(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<crate::PendingBoard, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[BOARD] Boarding ALL funds into Ark...");

            let pb = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                inner
                    .board_all(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board all failed: {}", e),
                    })?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                inner
                    .board_all(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Board all failed: {}", e),
                    })?
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Boarding requires a valid onchain wallet. Create one with \
                        OnchainWallet.default() or OnchainWallet.custom()".to_string(),
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
        }).await
    }

    /// Sync pending board transactions
    ///
    /// Checks if pending board transactions have sufficient confirmations
    /// and attempts to register them with the Ark server. Once registered,
    /// the boarded VTXOs become spendable.
    ///
    /// Call this periodically after creating board transactions.
    pub async fn sync_pending_boards(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[BOARD] Syncing pending boards...");

            inner
                .sync_pending_boards()
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Sync pending boards failed: {}", e),
                })?;

            eprintln!("[BOARD] ✅ Pending boards synced");

            Ok(())
        })
        .await
    }

    /// Get all pending board operations
    pub async fn pending_boards(&self) -> Result<Vec<PendingBoard>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_boards()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get all VTXOs that are part of pending boards
    pub async fn pending_board_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_board_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get VTXOs being used as inputs in pending rounds
    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_round_input_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Get VTXOs locked in pending Lightning sends
    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_lightning_send_vtxos()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
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
    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[EXIT] Starting unilateral exit for entire wallet...");

            inner
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
        .await
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
    pub async fn sync_exits(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[EXIT] Syncing exits...");

            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                inner
                    .sync_exits(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Sync exits failed: {}", e),
                    })?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                inner
                    .sync_exits(&mut *onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Sync exits failed: {}", e),
                    })?;
            } else {
                return Err(BarkError::OnchainWalletRequired {
                    error_message: "Syncing exits requires a valid onchain wallet. Create one \
                        with OnchainWallet.default() or OnchainWallet.custom()".to_string(),
                });
            }

            eprintln!("[EXIT] ✅ Exits synced");

            Ok(())
        }).await
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
    pub async fn progress_exits(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<crate::ExitProgressStatus>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[EXIT] Progressing exits...");

            let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

            let result = if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let mut onchain = bdk_wallet.lock().await;
                inner
                    .exit
                    .write()
                    .await
                    .progress_exits(&inner, &mut *onchain, fee_rate)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Progress exits failed: {}", e),
                    })?
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let mut onchain = callback_adapter.lock().await;
                inner
                    .exit
                    .write()
                    .await
                    .progress_exits(&inner, &mut *onchain, fee_rate)
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
        .await
    }

    /// Start unilateral exit for specific VTXOs
    ///
    /// Initiates the emergency exit process for the specified VTXOs.
    /// You must call `progress_exits` periodically to actually advance the exit.
    ///
    /// # Arguments
    ///
    /// * `vtxo_ids` - List of VTXO IDs to exit
    pub async fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
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
                let vtxo = inner
                    .get_vtxo_by_id(id)
                    .await
                    .map_err(|e| BarkError::NotFound {
                        error_message: format!("VTXO not found: {}", e),
                    })?;
                vtxos.push(vtxo);
            }

            let vtxo_refs: Vec<&ark_lib::Vtxo> = vtxos.iter().map(|v| &v.vtxo).collect();

            inner
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
        .await
    }

    /// List all claimable exits
    ///
    /// Returns all exits that are ready to be claimed (funds can be moved to onchain wallet).
    pub async fn list_claimable_exits(&self) -> Result<Vec<crate::ExitVtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let exit_guard = inner.exit.read().await;
            let claimable = exit_guard.list_claimable();
            Ok(claimable.into_iter().map(Into::into).collect())
        })
        .await
    }

    /// Get all exit VTXOs
    ///
    /// Returns all VTXOs that are currently in the exit process.
    pub async fn get_exit_vtxos(&self) -> Result<Vec<crate::ExitVtxo>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let exit_guard = inner.exit.read().await;
            Ok(exit_guard.get_exit_vtxos().iter().map(Into::into).collect())
        })
        .await
    }

    /// Check if there are any pending exits
    pub async fn has_pending_exits(&self) -> Result<bool, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let exit_guard = inner.exit.read().await;
            Ok(exit_guard.has_pending_exits())
        })
        .await
    }

    /// Get total amount in pending exits (in sats)
    pub async fn pending_exits_total_sats(&self) -> Result<u64, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let exit_guard = inner.exit.read().await;
            Ok(exit_guard.pending_total().to_sat())
        })
        .await
    }

    /// Get earliest block height when all exits will be claimable
    ///
    /// Returns None if no exits are tracked or if any exit cannot be determined.
    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let exit_guard = inner.exit.read().await;
            Ok(exit_guard.all_claimable_at_height().await)
        })
        .await
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
    pub async fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<crate::ExitTransactionStatus>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let vtxo_id_parsed =
                vtxo_id
                    .parse::<ark_lib::VtxoId>()
                    .map_err(|e| BarkError::InvalidAddress {
                        error_message: format!("invalid vtxo id: {}", e),
                    })?;

            let exit_guard = inner.exit.read().await;
            let status = exit_guard
                .get_exit_status(vtxo_id_parsed, include_history, include_transactions)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Get exit status failed: {}", e),
                })?;

            Ok(status.map(Into::into))
        })
        .await
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
    pub async fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<crate::ExitClaimTransaction, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            eprintln!("[EXIT] Draining {} exits to {}...", vtxo_ids.len(), address);

            let addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

            let exit_guard = inner.exit.read().await;
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
                .drain_exits(&to_drain, &inner, addr, fee_rate)
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
        .await
    }

    // ------------------------------------------------------------------------
    // Round Management
    // ------------------------------------------------------------------------

    /// Get all pending round states
    pub async fn pending_round_states(&self) -> Result<Vec<crate::RoundState>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .pending_round_states()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
        .await
    }

    /// Cancel a specific pending round
    ///
    /// # Arguments
    ///
    /// * `round_id` - The ID of the round to cancel
    pub async fn cancel_pending_round(&self, round_id: u32) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            use bark::persist::models::RoundStateId;
            inner.cancel_pending_round(RoundStateId(round_id)).await?;
            Ok(())
        })
        .await
    }

    /// Cancel all pending rounds
    pub async fn cancel_all_pending_rounds(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            inner.cancel_all_pending_rounds().await?;
            Ok(())
        })
        .await
    }

    /// Progress pending rounds
    ///
    /// Advances the state of all pending rounds. Call this periodically.
    pub async fn progress_pending_rounds(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            inner.progress_pending_rounds(None).await?;
            Ok(())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Extended Lightning & Misc
    // ------------------------------------------------------------------------

    /// Refresh the server connection
    ///
    /// Re-establishes connection to the Ark server if it was lost.
    pub async fn refresh_server(&self) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            inner.refresh_server().await?;
            Ok(())
        })
        .await
    }

    /// Validate an Ark address against the connected server
    ///
    /// This performs a full validation including checking if the address
    /// belongs to the currently connected Ark server.
    ///
    /// # Arguments
    ///
    /// * `address` - The Ark address to validate
    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr: ark_lib::Address =
                address.parse().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid ark address: {}", e),
                })?;

            match inner.validate_arkoor_address(&addr).await {
                Ok(_) => Ok(true),
                Err(_) => Ok(false),
            }
        })
        .await
    }

    // ------------------------------------------------------------------------
    // VTXO Expiry & Refresh Scheduling
    // ------------------------------------------------------------------------

    /// Get the block height of the first expiring VTXO
    ///
    /// Returns None if there are no spendable VTXOs.
    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.get_first_expiring_vtxo_blockheight().await?) }).await
    }

    /// Get the next block height when a refresh should be performed
    ///
    /// This is calculated as the first expiring VTXO height minus the refresh threshold.
    /// Returns None if there are no VTXOs to refresh.
    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move { Ok(inner.get_next_required_refresh_blockheight().await?) }).await
    }

    /// Schedule a maintenance refresh if VTXOs need refreshing
    ///
    /// Returns the round ID if a refresh was scheduled, None otherwise.
    pub async fn maybe_schedule_maintenance_refresh(&self) -> Result<Option<u32>, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            Ok(inner
                .maybe_schedule_maintenance_refresh()
                .await?
                .map(|id| id.0))
        })
        .await
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
    pub async fn sign_exit_claim_inputs(&self, psbt_base64: String) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
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

            let exit_guard = inner.exit.read().await;
            exit_guard
                .sign_exit_claim_inputs(&mut psbt, &inner)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Sign exit claim inputs failed: {}", e),
                })?;

            let signed_psbt_bytes = psbt.serialize();
            Ok(BASE64_STANDARD.encode(&signed_psbt_bytes))
        })
        .await
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
    pub async fn broadcast_tx(&self, tx_hex: String) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            use bitcoin::consensus::encode::deserialize_hex;
            use bitcoin::Transaction;

            let tx: Transaction =
                deserialize_hex(&tx_hex).map_err(|e| BarkError::InvalidTransaction {
                    error_message: format!("{}", e),
                })?;

            let txid = tx.compute_txid();

            eprintln!("[BROADCAST] Broadcasting transaction: {}", txid);

            inner
                .chain
                .broadcast_tx(&tx)
                .await
                .map_err(|e| BarkError::Network {
                    error_message: format!("Broadcast failed: {}", e),
                })?;

            eprintln!("[BROADCAST] Transaction broadcasted successfully");

            Ok(txid.to_string())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Mailbox
    // ------------------------------------------------------------------------
    /// Get the mailbox identifier for push notifications
    ///
    /// This identifier can be registered with a push notification service
    /// to receive alerts when VTXOs arrive in your mailbox. The mailbox
    /// receives all incoming VTXOs regardless of source (arkoor payments,
    /// Lightning receives, or round outputs).
    ///
    /// Returns the mailbox identifier as a hex-encoded public key.
    pub fn mailbox_identifier(&self) -> Result<String, BarkError> {
        let identifier = self.inner.mailbox_identifier();

        Ok(hex::encode(identifier.to_vec()))
    }

    /// Create a new authorization for your server mailbox
    pub fn mailbox_authorization(&self) -> Result<String, BarkError> {
        use ark_lib::ProtocolEncoding;

        // Default expiry: 24 hours from now
        let expiry = chrono::Local::now() + chrono::Duration::hours(24);

        let auth = self.inner.mailbox_authorization(expiry);

        Ok(hex::encode(auth.serialize()))
    }

    fn start_mailbox_processor(
        inner: Arc<InnerWallet>,
        cancel: CancellationToken,
    ) -> tokio::task::JoinHandle<()> {
        TOKIO_RT.spawn(async move {
            let mut retry_delay = 1;

            loop {
                match inner
                    .subscribe_process_mailbox_messages(None, cancel.clone())
                    .await
                {
                    Ok(_) => {
                        eprintln!("[MAILBOX] stream ended, restarting...");
                        retry_delay = 1; // reset
                    }
                    Err(e) => {
                        if cancel.is_cancelled() {
                            eprintln!("[MAILBOX] shutting down");
                            return;
                        }
                        eprintln!("[MAILBOX] error: {:?}, retrying in {}s", e, retry_delay);
                        tokio::time::sleep(std::time::Duration::from_secs(retry_delay)).await;
                        retry_delay = (retry_delay * 2).min(30); // exponential backoff
                        continue;
                    }
                }

                if cancel.is_cancelled() {
                    eprintln!("[MAILBOX] shutting down");
                    return;
                }

                tokio::time::sleep(std::time::Duration::from_secs(1)).await;
            }
        })
    }

    // ------------------------------------------------------------------------
    // VTXO Import
    // ------------------------------------------------------------------------

    /// Import a serialized VTXO into the wallet
    pub async fn import_vtxo(&self, vtxo_base64: String) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            use ark_lib::ProtocolEncoding;
            use base64::Engine;

            let vtxo_bytes = base64::engine::general_purpose::STANDARD
                .decode(&vtxo_base64)
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Invalid base64: {}", e),
                })?;

            let vtxo =
                ark_lib::Vtxo::deserialize(&vtxo_bytes).map_err(|e| BarkError::Internal {
                    error_message: format!("Invalid VTXO data: {}", e),
                })?;

            inner
                .import_vtxo(&vtxo)
                .await
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Failed to import VTXO: {}", e),
                })?;

            eprintln!("[IMPORT] VTXO imported successfully");
            Ok(())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    /// Estimate the fee for a board operation
    pub async fn estimate_board_fee(&self, amount_sats: u64) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let estimate = inner
                .estimate_board_offchain_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    /// Estimate the fee for an offboard operation
    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxo_ids: Vec<String>,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
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
                let vtxo = inner
                    .get_vtxo_by_id(id)
                    .await
                    .map_err(|e| BarkError::NotFound {
                        error_message: format!("VTXO not found: {}", e),
                    })?;
                vtxos.push(vtxo);
            }

            let estimate = inner
                .estimate_offboard(&btc_addr, &vtxos)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    /// Estimate the fee for a refresh operation
    pub async fn estimate_refresh_fee(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
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
                let vtxo = inner
                    .get_vtxo_by_id(id)
                    .await
                    .map_err(|e| BarkError::NotFound {
                        error_message: format!("VTXO not found: {}", e),
                    })?;
                vtxos.push(vtxo);
            }

            let estimate = inner
                .estimate_refresh_fee(&vtxos)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    /// Estimate the fee for a lightning send
    pub async fn estimate_lightning_send_fee(
        &self,
        amount_sats: u64,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let estimate = inner
                .estimate_lightning_send_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    /// Estimate the fee for a lightning receive
    pub async fn estimate_lightning_receive_fee(
        &self,
        amount_sats: u64,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let estimate = inner
                .estimate_lightning_receive_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    /// Estimate the fee for an arkoor payment
    pub async fn estimate_arkoor_payment_fee(
        &self,
        amount_sats: u64,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let estimate = inner
                .estimate_arkoor_payment_fee(amount)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Notifications
    // ------------------------------------------------------------------------

    /// Get a notification stream holder for this wallet.
    ///
    /// Call `next_notification()` on the holder in a loop to receive events.
    /// Call `cancel_next_notification_wait()` to unblock a pending wait without
    /// destroying the stream.
    ///
    /// Each call creates an independent broadcast receiver; existing holders
    /// are unaffected.
    pub fn notifications(&self) -> Arc<NotificationHolder> {
        NotificationHolder::new(&self.inner)
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    /// Estimate the fee for offboarding all spendable VTXOs
    pub async fn estimate_offboard_all_fee(
        &self,
        address: String,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let btc_addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Failed to parse address: {}", e),
                })?
                .assume_checked();

            let estimate = inner
                .estimate_offboard_all(&btc_addr)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }

    /// Estimate the fee for a send onchain operation
    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<FeeEstimate, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let btc_addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::Internal {
                    error_message: format!("Failed to parse address: {}", e),
                })?
                .assume_checked();

            let amount = bitcoin::Amount::from_sat(amount_sats);
            let estimate = inner
                .estimate_send_onchain(&btc_addr, amount)
                .await
                .map_err(BarkError::from)?;
            Ok(estimate.into())
        })
        .await
    }
}

impl Drop for Wallet {
    fn drop(&mut self) {
        if let Some(handle) = self.mailbox_task.take() {
            handle.abort();
        }
    }
}
