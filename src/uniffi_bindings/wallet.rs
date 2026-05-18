use std::sync::Arc;

use anyhow::Context;
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;
use lnurl::lightning_address::LightningAddress;
use tokio_util::sync::CancellationToken;

use bark::Wallet as InnerWallet;

use crate::config::Config;
use crate::core::notification::NotificationHolder;
use crate::core::wallet::Wallet as CoreWallet;
use crate::error::BarkError;
use crate::types;
use crate::uniffi_bindings::db::get_or_open_db;
use crate::uniffi_bindings::onchain::OnchainWallet;
use crate::uniffi_bindings::runtime::{run_async, TOKIO_RT};

/// UniFFI-facing Bark wallet.
///
/// Wraps `core::Wallet` and adds:
/// - `run_async` runtime offload on every entry point
/// - mailbox processor task + cancellation on drop
/// - LNURL `pay_lightning_address`
/// - Daemon control methods
/// - Notification holder
/// - Callback onchain dispatch
#[derive(uniffi::Object)]
pub struct Wallet {
    core: Arc<CoreWallet>,
    /// Direct handle to bark::Wallet so callback-onchain methods can bypass
    /// `core::Wallet` (which only knows BDK).
    inner: Arc<InnerWallet>,
    mailbox_task: std::sync::Mutex<Option<tokio::task::JoinHandle<()>>>,
    #[allow(dead_code)]
    mailbox_cancel: CancellationToken,
}

impl Wallet {
    fn wrap(core: CoreWallet) -> Arc<Self> {
        let inner = core.inner();
        let cancel = CancellationToken::new();
        let mailbox_task = Some(Self::start_mailbox_processor(inner.clone(), cancel.clone()));
        Arc::new(Self {
            core: Arc::new(core),
            inner,
            mailbox_task: std::sync::Mutex::new(mailbox_task),
            mailbox_cancel: cancel,
        })
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
                        log::info!("[MAILBOX] stream ended, restarting...");
                        retry_delay = 1;
                    }
                    Err(e) => {
                        if cancel.is_cancelled() {
                            log::info!("[MAILBOX] shutting down");
                            return;
                        }
                        log::warn!("[MAILBOX] error: {:?}, retrying in {}s", e, retry_delay);
                        tokio::select! {
                            _ = cancel.cancelled() => {
                                log::info!("[MAILBOX] shutting down");
                                return;
                            }
                            _ = tokio::time::sleep(std::time::Duration::from_secs(retry_delay)) => {}
                        }
                        retry_delay = (retry_delay * 2).min(30);
                        continue;
                    }
                }

                tokio::select! {
                    _ = cancel.cancelled() => {
                        log::info!("[MAILBOX] shutting down");
                        return;
                    }
                    _ = tokio::time::sleep(std::time::Duration::from_secs(1)) => {}
                }
            }
        })
    }
}

#[uniffi::export(async_runtime = "tokio")]
impl Wallet {
    // ------------------------------------------------------------------------
    // Construction
    // ------------------------------------------------------------------------

    #[uniffi::constructor]
    pub async fn create(
        mnemonic: String,
        config: Config,
        datadir: String,
        force_rescan: bool,
    ) -> Result<Arc<Self>, BarkError> {
        run_async(async move {
            let db = get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;
            let core = CoreWallet::create(mnemonic, config, db, force_rescan).await?;
            Ok(Self::wrap(core))
        })
        .await
    }

    #[uniffi::constructor]
    pub async fn open(
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<Arc<Self>, BarkError> {
        run_async(async move {
            let db = get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;
            let core = CoreWallet::open(mnemonic, config, db).await?;
            Ok(Self::wrap(core))
        })
        .await
    }

    #[uniffi::constructor]
    pub async fn create_with_onchain(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Arc<OnchainWallet>,
        force_rescan: bool,
    ) -> Result<Arc<Self>, BarkError> {
        run_async(async move {
            let db = get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;

            if let Some(bdk) = onchain_wallet.bdk_core() {
                let core = CoreWallet::create_with_onchain(
                    mnemonic,
                    config,
                    db,
                    bdk,
                    force_rescan,
                )
                .await?;
                Ok(Self::wrap(core))
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                // Bypass core::Wallet: it doesn't model callback wallets.
                let network: BtcNetwork = config.network.into();
                let cfg: bark::Config = config.into();
                let mn = Mnemonic::parse(mnemonic.trim()).map_err(|e| {
                    BarkError::InvalidMnemonic { error_message: e.to_string() }
                })?;

                let onchain = adapter.read().await;
                let inner = InnerWallet::create_with_onchain(
                    &mn, network, cfg, db, &*onchain, force_rescan,
                )
                .await
                .map_err(BarkError::from)?;
                drop(onchain);

                let core = CoreWallet::from_inner_arc(Arc::new(inner));
                Ok(Self::wrap(core))
            } else {
                Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                })
            }
        })
        .await
    }

    #[uniffi::constructor]
    pub async fn open_with_onchain(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<Arc<Self>, BarkError> {
        run_async(async move {
            let db = get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;

            if let Some(bdk) = onchain_wallet.bdk_core() {
                let core = CoreWallet::open_with_onchain(mnemonic, config, db, bdk).await?;
                Ok(Self::wrap(core))
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                let cfg: bark::Config = config.into();
                let mn = Mnemonic::parse(mnemonic.trim()).map_err(|e| {
                    BarkError::InvalidMnemonic { error_message: e.to_string() }
                })?;

                let onchain = adapter.read().await;
                let inner = InnerWallet::open_with_onchain(&mn, db, &*onchain, cfg)
                    .await
                    .map_err(BarkError::from)?;
                drop(onchain);

                let core = CoreWallet::from_inner_arc(Arc::new(inner));
                Ok(Self::wrap(core))
            } else {
                Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                })
            }
        })
        .await
    }

    /// Open an existing wallet and start running the daemon.
    #[uniffi::constructor]
    pub async fn open_with_daemon(
        mnemonic: String,
        config: Config,
        datadir: String,
        onchain_wallet: Option<Arc<OnchainWallet>>,
    ) -> Result<Arc<Self>, BarkError> {
        run_async(async move {
            let cfg: bark::Config = config.into();

            let mn = Mnemonic::parse(mnemonic.trim()).map_err(|e| {
                BarkError::InvalidMnemonic { error_message: e.to_string() }
            })?;

            let db = get_or_open_db(&datadir)
                .with_context(|| format!("opening sqlite in {}", datadir))?;

            log::info!("[OPEN] Opening Bark wallet with daemon...");

            let bdk = onchain_wallet.as_ref().and_then(|w| w.inner_bdk());
            if bdk.is_none() {
                if onchain_wallet.as_ref().and_then(|w| w.inner_callback()).is_some() {
                    log::warn!(
                        "[OPEN] Callback wallets are not supported for daemon mode, running without onchain capabilities"
                    );
                } else {
                    log::warn!(
                        "[OPEN] No onchain wallet provided, running without onchain capabilities"
                    );
                }
            }

            let inner = match bdk {
                Some(bdk) => InnerWallet::open_with_daemon(&mn, db, cfg, Some(bdk)).await,
                None => InnerWallet::open_with_daemon(&mn, db, cfg, None).await,
            }
            .map_err(BarkError::from)?;

            if inner.ark_info().await.ok().flatten().is_some() {
                log::info!("[OPEN] Server connection established");
            } else {
                log::warn!(
                    "[OPEN] Server connection FAILED - Lightning and Ark operations will not work!"
                );
            }

            log::info!("[OPEN] Bark wallet opened successfully and daemon running");

            let core = CoreWallet::from_inner_arc(inner);
            Ok(Self::wrap(core))
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Sync & Maintenance
    // ------------------------------------------------------------------------

    pub async fn sync(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.sync().await }).await
    }

    pub async fn maintenance(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.maintenance().await }).await
    }

    pub async fn maintenance_with_onchain(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), BarkError> {
        let core = self.core.clone();
        let inner = self.inner.clone();
        run_async(async move {
            if let Some(bdk) = onchain_wallet.inner_bdk() {
                let _ = bdk; // core path uses bdk via core::OnchainWallet wrapper
                core.maintenance_with_onchain(onchain_wallet.bdk_core().unwrap()).await
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                let mut o = adapter.write().await;
                inner.maintenance_with_onchain(&mut *o).await?;
                Ok(())
            } else {
                Err(BarkError::OnchainWalletRequired {
                    error_message: "Invalid onchain wallet".to_string(),
                })
            }
        })
        .await
    }

    pub async fn maintenance_delegated(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.maintenance_delegated().await }).await
    }

    pub async fn maintenance_with_onchain_delegated(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), BarkError> {
        let core = self.core.clone();
        let inner = self.inner.clone();
        run_async(async move {
            if onchain_wallet.inner_bdk().is_some() {
                core.maintenance_with_onchain_delegated(onchain_wallet.bdk_core().unwrap()).await
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                let mut o = adapter.write().await;
                inner.maintenance_with_onchain_delegated(&mut *o).await?;
                Ok(())
            } else {
                Err(BarkError::Internal {
                    error_message: "Invalid onchain wallet state".to_string(),
                })
            }
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Address
    // ------------------------------------------------------------------------

    pub async fn new_address(&self) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.new_address().await }).await
    }

    pub async fn new_address_with_index(&self) -> Result<types::AddressWithIndex, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.new_address_with_index().await }).await
    }

    pub async fn peek_address(&self, index: u32) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.peek_address(index).await }).await
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    pub async fn balance(&self) -> Result<types::Balance, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.balance().await }).await
    }

    pub async fn vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.vtxos().await }).await
    }

    pub async fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<types::Vtxo, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.get_vtxo_by_id(vtxo_id).await }).await
    }

    pub async fn spendable_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.spendable_vtxos().await }).await
    }

    pub async fn all_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.all_vtxos().await }).await
    }

    pub async fn get_expiring_vtxos(
        &self,
        threshold_blocks: u32,
    ) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.get_expiring_vtxos(threshold_blocks).await }).await
    }

    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.get_vtxos_to_refresh().await }).await
    }

    // ------------------------------------------------------------------------
    // Offboarding
    // ------------------------------------------------------------------------

    pub async fn offboard_all(
        &self,
        bitcoin_address: String,
    ) -> Result<types::OffboardResult, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.offboard_all(bitcoin_address).await }).await
    }

    pub async fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.offboard_vtxos(vtxo_ids, bitcoin_address).await }).await
    }

    // ------------------------------------------------------------------------
    // Lightning (send)
    // ------------------------------------------------------------------------

    pub async fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
    ) -> Result<types::LightningSend, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pay_lightning_invoice(invoice, amount_sats).await }).await
    }

    /// Pay to a Lightning Address (LNURL). UniFFI-only — lnurl-rs is not wasm-compatible.
    pub async fn pay_lightning_address(
        &self,
        lightning_address: String,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<types::LightningSend, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let addr: LightningAddress = lightning_address.parse().map_err(|e| {
                BarkError::InvalidAddress {
                    error_message: format!("invalid lightning address: {}", e),
                }
            })?;
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let lightning_send = inner
                .pay_lightning_address(&addr, amount, comment.as_deref())
                .await?;
            Ok(lightning_send.into())
        })
        .await
    }

    pub async fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
    ) -> Result<types::LightningSend, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pay_lightning_offer(offer, amount_sats).await }).await
    }

    pub async fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<Option<String>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.check_lightning_payment(payment_hash, wait).await }).await
    }

    pub async fn pending_lightning_sends(
        &self,
    ) -> Result<Vec<types::LightningSend>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_lightning_sends().await }).await
    }

    // ------------------------------------------------------------------------
    // Lightning (receive)
    // ------------------------------------------------------------------------

    pub async fn bolt11_invoice(
        &self,
        amount_sats: u64,
        description: Option<String>,
    ) -> Result<types::LightningInvoice, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.bolt11_invoice(amount_sats, description).await }).await
    }

    pub async fn try_claim_all_lightning_receives(
        &self,
        wait: bool,
    ) -> Result<Vec<types::LightningReceive>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.try_claim_all_lightning_receives(wait).await }).await
    }

    pub async fn pending_lightning_receives(
        &self,
    ) -> Result<Vec<types::LightningReceive>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_lightning_receives().await }).await
    }

    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.claimable_lightning_receive_balance_sats().await }).await
    }

    pub async fn lightning_receive_status(
        &self,
        payment_hash: String,
    ) -> Result<Option<types::LightningReceive>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.lightning_receive_status(payment_hash).await }).await
    }

    pub async fn try_claim_lightning_receive(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.try_claim_lightning_receive(payment_hash, wait).await }).await
    }

    pub async fn cancel_lightning_receive(
        &self,
        payment_hash: String,
    ) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.cancel_lightning_receive(payment_hash).await }).await
    }

    // ------------------------------------------------------------------------
    // Arkoor
    // ------------------------------------------------------------------------

    pub async fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.send_arkoor_payment(ark_address, amount_sats).await }).await
    }

    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.validate_arkoor_address(address).await }).await
    }

    pub async fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.send_onchain(address, amount_sats).await }).await
    }

    // ------------------------------------------------------------------------
    // History
    // ------------------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<types::Movement>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.history().await }).await
    }

    pub async fn history_by_payment_method(
        &self,
        payment_method_type: String,
        payment_method_value: String,
    ) -> Result<Vec<types::Movement>, BarkError> {
        let core = self.core.clone();
        run_async(async move {
            core.history_by_payment_method(payment_method_type, payment_method_value).await
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Refresh
    // ------------------------------------------------------------------------

    pub async fn refresh_vtxos(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<String>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.refresh_vtxos(vtxo_ids).await }).await
    }

    pub async fn maintenance_refresh(&self) -> Result<Option<String>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.maintenance_refresh().await }).await
    }

    pub async fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<types::RoundState>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.refresh_vtxos_delegated(vtxo_ids).await }).await
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------

    pub async fn properties(&self) -> Result<types::WalletProperties, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.properties().await }).await
    }

    pub fn fingerprint(&self) -> String {
        self.core.fingerprint()
    }

    pub async fn network(&self) -> Result<types::Network, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.network().await }).await
    }

    pub async fn config(&self) -> Config {
        let core = self.core.clone();
        run_async(async move { core.config().await }).await
    }

    pub async fn ark_info(&self) -> Option<types::ArkInfo> {
        let core = self.core.clone();
        run_async(async move { core.ark_info().await }).await
    }

    pub async fn next_round_start_time(&self) -> Result<u64, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.next_round_start_time().await }).await
    }

    // ------------------------------------------------------------------------
    // Boarding (requires onchain wallet)
    // ------------------------------------------------------------------------

    pub async fn board_amount(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
        amount_sats: u64,
    ) -> Result<types::PendingBoard, BarkError> {
        let core = self.core.clone();
        let inner = self.inner.clone();
        run_async(async move {
            if onchain_wallet.inner_bdk().is_some() {
                core.board_amount(onchain_wallet.bdk_core().unwrap(), amount_sats).await
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                let amount = bitcoin::Amount::from_sat(amount_sats);
                log::info!("[BOARD] Boarding {} sats into Ark...", amount_sats);
                let mut onchain = adapter.write().await;
                let pb = inner.board_amount(&mut *onchain, amount).await.map_err(|e| {
                    BarkError::Internal { error_message: format!("Board failed: {}", e) }
                })?;
                Ok(pb.into())
            } else {
                Err(BarkError::OnchainWalletRequired {
                    error_message: "Boarding requires a valid onchain wallet. Create one with \
                        OnchainWallet.default() or OnchainWallet.custom()"
                        .to_string(),
                })
            }
        })
        .await
    }

    pub async fn board_all(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<types::PendingBoard, BarkError> {
        let core = self.core.clone();
        let inner = self.inner.clone();
        run_async(async move {
            if onchain_wallet.inner_bdk().is_some() {
                core.board_all(onchain_wallet.bdk_core().unwrap()).await
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                log::info!("[BOARD] Boarding ALL funds into Ark...");
                let mut onchain = adapter.write().await;
                let pb = inner.board_all(&mut *onchain).await.map_err(|e| {
                    BarkError::Internal { error_message: format!("Board all failed: {}", e) }
                })?;
                Ok(pb.into())
            } else {
                Err(BarkError::OnchainWalletRequired {
                    error_message: "Boarding requires a valid onchain wallet. Create one with \
                        OnchainWallet.default() or OnchainWallet.custom()"
                        .to_string(),
                })
            }
        })
        .await
    }

    pub async fn sync_pending_boards(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.sync_pending_boards().await }).await
    }

    pub async fn pending_boards(&self) -> Result<Vec<types::PendingBoard>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_boards().await }).await
    }

    pub async fn pending_board_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_board_vtxos().await }).await
    }

    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_round_input_vtxos().await }).await
    }

    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_lightning_send_vtxos().await }).await
    }

    // ------------------------------------------------------------------------
    // Unilateral Exits
    // ------------------------------------------------------------------------

    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.start_exit_for_entire_wallet().await }).await
    }

    pub async fn sync_exits(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), BarkError> {
        let core = self.core.clone();
        let inner = self.inner.clone();
        run_async(async move {
            if onchain_wallet.inner_bdk().is_some() {
                core.sync_exits(onchain_wallet.bdk_core().unwrap()).await
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                log::info!("[EXIT] Syncing exits...");
                let mut onchain = adapter.write().await;
                inner.sync_exits(&mut *onchain).await.map_err(|e| BarkError::Internal {
                    error_message: format!("Sync exits failed: {}", e),
                })?;
                log::info!("[EXIT] Exits synced");
                Ok(())
            } else {
                Err(BarkError::OnchainWalletRequired {
                    error_message: "Syncing exits requires a valid onchain wallet. Create one \
                        with OnchainWallet.default() or OnchainWallet.custom()"
                        .to_string(),
                })
            }
        })
        .await
    }

    pub async fn progress_exits(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<types::ExitProgressStatus>, BarkError> {
        let core = self.core.clone();
        let inner = self.inner.clone();
        run_async(async move {
            if onchain_wallet.inner_bdk().is_some() {
                core.progress_exits(onchain_wallet.bdk_core().unwrap(), fee_rate_sat_per_vb).await
            } else if let Some(adapter) = onchain_wallet.inner_callback() {
                log::info!("[EXIT] Progressing exits...");
                let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);
                let mut onchain = adapter.write().await;
                let result = inner
                    .exit
                    .write()
                    .await
                    .progress_exits(&inner, &mut *onchain, fee_rate)
                    .await
                    .map_err(|e| BarkError::Internal {
                        error_message: format!("Progress exits failed: {}", e),
                    })?;
                let statuses = result.unwrap_or_default().into_iter().map(Into::into).collect();
                log::info!("[EXIT] Exits progressed");
                Ok(statuses)
            } else {
                Err(BarkError::OnchainWalletRequired {
                    error_message: "Progressing exits requires a valid onchain wallet".to_string(),
                })
            }
        })
        .await
    }

    pub async fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.start_exit_for_vtxos(vtxo_ids).await }).await
    }

    pub async fn list_claimable_exits(&self) -> Result<Vec<types::ExitVtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.list_claimable_exits().await }).await
    }

    pub async fn get_exit_vtxos(&self) -> Result<Vec<types::ExitVtxo>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.get_exit_vtxos().await }).await
    }

    pub async fn has_pending_exits(&self) -> Result<bool, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.has_pending_exits().await }).await
    }

    pub async fn pending_exits_total_sats(&self) -> Result<u64, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_exits_total_sats().await }).await
    }

    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.all_exits_claimable_at_height().await }).await
    }

    pub async fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<types::ExitTransactionStatus>, BarkError> {
        let core = self.core.clone();
        run_async(async move {
            core.get_exit_status(vtxo_id, include_history, include_transactions).await
        })
        .await
    }

    pub async fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<types::ExitClaimTransaction, BarkError> {
        let core = self.core.clone();
        run_async(async move {
            core.drain_exits(vtxo_ids, address, fee_rate_sat_per_vb).await
        })
        .await
    }

    pub async fn sign_exit_claim_inputs(
        &self,
        psbt_base64: String,
    ) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.sign_exit_claim_inputs(psbt_base64).await }).await
    }

    // ------------------------------------------------------------------------
    // Rounds
    // ------------------------------------------------------------------------

    pub async fn pending_round_states(&self) -> Result<Vec<types::RoundState>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.pending_round_states().await }).await
    }

    pub async fn cancel_pending_round(&self, round_id: u32) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.cancel_pending_round(round_id).await }).await
    }

    pub async fn cancel_all_pending_rounds(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.cancel_all_pending_rounds().await }).await
    }

    pub async fn progress_pending_rounds(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.progress_pending_rounds().await }).await
    }

    // ------------------------------------------------------------------------
    // Server
    // ------------------------------------------------------------------------

    pub async fn refresh_server(&self) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.refresh_server().await }).await
    }

    // ------------------------------------------------------------------------
    // VTXO Expiry & Refresh Scheduling
    // ------------------------------------------------------------------------

    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.get_first_expiring_vtxo_blockheight().await }).await
    }

    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.get_next_required_refresh_blockheight().await }).await
    }

    pub async fn maybe_schedule_maintenance_refresh(&self) -> Result<Option<u32>, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.maybe_schedule_maintenance_refresh().await }).await
    }

    // ------------------------------------------------------------------------
    // Broadcasting
    // ------------------------------------------------------------------------

    pub async fn broadcast_tx(&self, tx_hex: String) -> Result<String, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.broadcast_tx(tx_hex).await }).await
    }

    // ------------------------------------------------------------------------
    // Mailbox
    // ------------------------------------------------------------------------

    pub fn mailbox_identifier(&self) -> Result<String, BarkError> {
        self.core.mailbox_identifier()
    }

    pub fn mailbox_authorization(&self) -> Result<String, BarkError> {
        self.core.mailbox_authorization()
    }

    // ------------------------------------------------------------------------
    // VTXO Import
    // ------------------------------------------------------------------------

    pub async fn import_vtxo(&self, vtxo_base64: String) -> Result<(), BarkError> {
        let core = self.core.clone();
        run_async(async move { core.import_vtxo(vtxo_base64).await }).await
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    pub async fn estimate_board_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_board_fee(amount_sats).await }).await
    }

    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_offboard_fee(address, vtxo_ids).await }).await
    }

    pub async fn estimate_refresh_fee(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_refresh_fee(vtxo_ids).await }).await
    }

    pub async fn estimate_lightning_send_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_lightning_send_fee(amount_sats).await }).await
    }

    pub async fn estimate_lightning_receive_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_lightning_receive_fee(amount_sats).await }).await
    }

    pub async fn estimate_arkoor_payment_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_arkoor_payment_fee(amount_sats).await }).await
    }

    pub async fn estimate_offboard_all_fee(
        &self,
        address: String,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_offboard_all_fee(address).await }).await
    }

    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let core = self.core.clone();
        run_async(async move { core.estimate_send_onchain_fee(address, amount_sats).await }).await
    }

    // ------------------------------------------------------------------------
    // Notifications
    // ------------------------------------------------------------------------

    pub fn notifications(&self) -> Arc<NotificationHolder> {
        NotificationHolder::new(&self.inner)
    }

    // ------------------------------------------------------------------------
    // Daemon
    // ------------------------------------------------------------------------

    pub async fn run_daemon(
        &self,
        onchain_wallet: Option<Arc<OnchainWallet>>,
    ) -> Result<(), BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            let bdk = onchain_wallet.as_ref().and_then(|w| w.inner_bdk());
            if bdk.is_none() {
                if onchain_wallet.as_ref().and_then(|w| w.inner_callback()).is_some() {
                    log::warn!(
                        "[OPEN] Callback wallets are not supported for daemon mode, running without onchain capabilities"
                    );
                } else {
                    log::warn!(
                        "[OPEN] No onchain wallet provided, running without onchain capabilities"
                    );
                }
            }

            match bdk {
                Some(bdk) => inner.start_daemon(Some(bdk)).map_err(BarkError::from),
                None => inner.start_daemon(None).map_err(BarkError::from),
            }
        })
        .await?;
        Ok(())
    }

    pub async fn stop_daemon(&self) -> Result<(), BarkError> {
        self.inner.stop_daemon();
        Ok(())
    }
}

impl Drop for Wallet {
    fn drop(&mut self) {
        if let Some(handle) = self.mailbox_task.lock().unwrap().take() {
            handle.abort();
        }
    }
}
