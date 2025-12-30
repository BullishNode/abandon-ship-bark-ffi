use std::sync::Arc;

use anyhow::Context;
use bark::Wallet as InnerWallet;
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;
use lightning_invoice::Bolt11Invoice;
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

            let mnemonic = Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
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
    // Wallet Properties
    // ------------------------------------------------------------------------

    /// Get read-only wallet properties
    pub fn properties(&self) -> Result<WalletProperties, BarkError> {
        Ok(self.inner.properties()?.into())
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
            if let Ok(balance) = self.inner.balance() {
                eprintln!(
                    "[SYNC] Balance after sync: spendable={}, pending_board={}",
                    balance.spendable.to_sat(),
                    balance.pending_board.to_sat()
                );
            }

            // Log VTXO count
            if let Ok(vtxos) = self.inner.vtxos() {
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
        Ok(self.inner.balance()?.into())
    }

    /// List all unspent VTXOs in the wallet
    pub fn vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        Ok(self.inner.vtxos()?.into_iter().map(Into::into).collect())
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
    ) -> Result<LightningPaymentResult, BarkError> {
        TOKIO_RT.block_on(async {
            let invoice: Bolt11Invoice =
                invoice.parse().map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("invalid invoice: {}", e),
                })?;

            let amount = amount_sats.map(bitcoin::Amount::from_sat);

            let preimage = self
                .inner
                .pay_lightning_invoice(invoice.clone(), amount)
                .await?;

            Ok(LightningPaymentResult {
                invoice: invoice.to_string(),
                preimage: preimage.to_string(),
            })
        })
    }

    /// Pay to a Lightning Address (LNURL)
    pub fn pay_lightning_address(
        &self,
        lightning_address: String,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<LightningPaymentResult, BarkError> {
        TOKIO_RT.block_on(async {
            let addr: LightningAddress =
                lightning_address
                    .parse()
                    .map_err(|e| BarkError::InvalidAddress {
                        error_message: format!("invalid lightning address: {}", e),
                    })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let (invoice, preimage) = self
                .inner
                .pay_lightning_address(&addr, amount, comment.as_deref())
                .await?;

            Ok(LightningPaymentResult {
                invoice: invoice.to_string(),
                preimage: preimage.to_string(),
            })
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
    pub fn try_claim_all_lightning_receives(&self, wait: bool) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.try_claim_all_lightning_receives(wait).await?;
            Ok(())
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
    pub fn peak_address(&self, index: u32) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = self.inner.peak_address(index).await?;
            Ok(addr.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Movement History
    // ------------------------------------------------------------------------

    /// Get all wallet movements (transaction history)
    pub fn movements(&self) -> Result<Vec<Movement>, BarkError> {
        Ok(self
            .inner
            .movements()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    // ------------------------------------------------------------------------
    // Extended VTXO Queries
    // ------------------------------------------------------------------------

    /// Get a specific VTXO by ID
    pub fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<Vtxo, BarkError> {
        let id = vtxo_id.parse().map_err(|e| BarkError::InvalidAddress {
            error_message: format!("invalid vtxo id: {}", e),
        })?;
        Ok(self.inner.get_vtxo_by_id(id)?.into())
    }

    /// Get all spendable VTXOs
    pub fn spendable_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        Ok(self
            .inner
            .spendable_vtxos()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get all VTXOs (including spent)
    pub fn all_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        Ok(self
            .inner
            .all_vtxos()?
            .into_iter()
            .map(Into::into)
            .collect())
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

    // ------------------------------------------------------------------------
    // Extended Lightning
    // ------------------------------------------------------------------------

    /// Get all pending lightning sends
    pub fn pending_lightning_sends(&self) -> Result<Vec<LightningSendStatus>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_sends()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get all pending lightning receives
    pub fn pending_lightning_receives(&self) -> Result<Vec<LightningReceiveStatus>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_receives()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get claimable lightning receive balance
    pub fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, BarkError> {
        Ok(self.inner.claimable_lightning_receive_balance()?.to_sat())
    }

    // ------------------------------------------------------------------------
    // Onchain Payments
    // ------------------------------------------------------------------------

    /// Send an onchain payment during a round
    pub fn send_round_onchain_payment(
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
            let status = self.inner.send_round_onchain_payment(addr, amount).await?;

            Ok(format!("{:?}", status))
        })
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------
    /// Get Ark server info
    pub fn ark_info(&self) -> Option<ArkInfo> {
        TOKIO_RT.block_on(async {
            match self.inner.ark_info().await {
                Ok(Some(info)) => Some((&info).into()),
                _ => None,
            }
        })
    }

    /// Get wallet config
    pub fn config(&self) -> Config {
        let cfg = self.inner.config();
        let props = self.inner.properties().unwrap();
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
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
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
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
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
    pub fn start_exit_for_entire_wallet(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[EXIT] Starting unilateral exit for entire wallet...");

            if let Some(bdk_wallet) = onchain_wallet.inner_bdk() {
                let onchain = bdk_wallet.lock().await;
                self.inner
                    .exit
                    .write()
                    .await
                    .start_exit_for_entire_wallet(&*onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Start exit failed: {}", e),
                    })?;
            } else if let Some(callback_adapter) = onchain_wallet.inner_callback() {
                let onchain = callback_adapter.lock().await;
                self.inner
                    .exit
                    .write()
                    .await
                    .start_exit_for_entire_wallet(&*onchain)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Start exit failed: {}", e),
                    })?;
            } else {
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                });
            }

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
    /// For that, the onchain wallet must implement progress_exits separately.
    ///
    /// # Arguments
    ///
    /// * `onchain_wallet` - The onchain wallet for checking transaction state
    pub fn sync_exits(
        &self,
        onchain_wallet: Arc<crate::OnchainWallet>,
    ) -> Result<(), BarkError> {
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
                return Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                });
            }

            eprintln!("[EXIT] ✅ Exits synced");

            Ok(())
        })
    }
}
