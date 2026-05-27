use std::str::FromStr;
use std::sync::Arc;

use base64::Engine;
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;

use ark::lightning::{Offer, PaymentHash};
use ark::{ProtocolEncoding, VtxoId};
use bark::lightning_invoice::Bolt11Invoice;
use bark::lock_manager::LockManager;
use bark::persist::BarkPersister;
use bark::Wallet as InnerWallet;

use crate::config::Config;
use crate::core::onchain::OnchainWallet;
use crate::error::BarkError;
use crate::types;

/// Core Bark wallet logic. No binding-specific behavior — pure async over
/// `bark::Wallet`. UniFFI / WASM wrappers layer their own concerns on top
/// (run_async, mailbox processor, JsError conversion, etc).
pub struct Wallet {
    inner: Arc<InnerWallet>,
}

#[allow(dead_code)] // some methods are wired only via the uniffi layer
impl Wallet {
    /// Build from an already-constructed `bark::Wallet`.
    fn from_inner(inner: InnerWallet) -> Self {
        Self {
            inner: Arc::new(inner),
        }
    }

    /// Build from an `Arc<bark::Wallet>` — used by binding wrappers that
    /// construct the inner wallet themselves (e.g. uniffi callback-onchain path).
    pub(crate) fn from_inner_arc(inner: Arc<InnerWallet>) -> Self {
        Self { inner }
    }

    pub(crate) fn inner(&self) -> Arc<InnerWallet> {
        self.inner.clone()
    }

    // ------------------------------------------------------------------------
    // Construction
    // ------------------------------------------------------------------------

    pub async fn create(
        mnemonic: String,
        config: Config,
        db: Arc<dyn BarkPersister>,
        lock_manager: Box<dyn LockManager>,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        let network: BtcNetwork = config.network.into();
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        let inner = InnerWallet::create(&mnemonic, network, cfg, db, lock_manager, force_rescan)
            .await
            .map_err(BarkError::from)?;

        Ok(Self::from_inner(inner))
    }

    pub async fn open(
        mnemonic: String,
        config: Config,
        db: Arc<dyn BarkPersister>,
        lock_manager: Box<dyn LockManager>,
    ) -> Result<Self, BarkError> {
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        let inner = InnerWallet::open(&mnemonic, db, cfg, lock_manager)
            .await
            .map_err(BarkError::from)?;

        if inner.ark_info().await.ok().flatten().is_some() {
            log::info!("[OPEN] Server connection established");
        } else {
            log::warn!(
                "[OPEN] Server connection FAILED - Lightning and Ark operations will not work!"
            );
        }

        Ok(Self::from_inner(inner))
    }

    pub async fn create_with_onchain(
        mnemonic: String,
        config: Config,
        db: Arc<dyn BarkPersister>,
        onchain_wallet: Arc<OnchainWallet>,
        lock_manager: Box<dyn LockManager>,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        let network: BtcNetwork = config.network.into();
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        log::info!("[CREATE] Creating Bark wallet with onchain capabilities...");

        let bdk = onchain_wallet.inner();
        let onchain_guard = bdk.read().await;
        let inner = InnerWallet::create_with_onchain(
            &mnemonic,
            network,
            cfg,
            db,
            lock_manager,
            &*onchain_guard,
            force_rescan,
        )
        .await
        .map_err(BarkError::from)?;
        drop(onchain_guard);

        log::info!("[CREATE] Bark wallet with onchain created successfully");

        Ok(Self::from_inner(inner))
    }

    pub async fn open_with_onchain(
        mnemonic: String,
        config: Config,
        db: Arc<dyn BarkPersister>,
        onchain_wallet: Arc<OnchainWallet>,
        lock_manager: Box<dyn LockManager>,
    ) -> Result<Self, BarkError> {
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        log::info!("[OPEN] Opening Bark wallet with onchain capabilities...");

        let bdk = onchain_wallet.inner();
        let onchain_guard = bdk.read().await;
        let inner =
            InnerWallet::open_with_onchain(&mnemonic, db, &*onchain_guard, cfg, lock_manager)
                .await
                .map_err(BarkError::from)?;
        drop(onchain_guard);

        if inner.ark_info().await.ok().flatten().is_some() {
            log::info!("[OPEN] Server connection established");
        } else {
            log::warn!(
                "[OPEN] Server connection FAILED - Lightning and Ark operations will not work!"
            );
        }

        log::info!("[OPEN] Bark wallet with onchain opened successfully");

        Ok(Self::from_inner(inner))
    }

    // ------------------------------------------------------------------------
    // Synchronization & Maintenance
    // ------------------------------------------------------------------------

    pub async fn sync(&self) -> Result<(), BarkError> {
        log::info!("[SYNC] Starting sync...");
        self.inner.sync().await;
        log::info!("[SYNC] Sync completed");

        if let Ok(balance) = self.inner.balance().await {
            log::info!(
                "[SYNC] Balance after sync: spendable={}, pending_board={}",
                balance.spendable.to_sat(),
                balance.pending_board.to_sat()
            );
        }

        if let Ok(vtxos) = self.inner.vtxos().await {
            log::info!("[SYNC] VTXOs after sync: {} total", vtxos.len());
            for (i, vtxo) in vtxos.iter().enumerate().take(3) {
                log::info!(
                    "[SYNC]   VTXO {}: {} sats, state={:?}",
                    i,
                    vtxo.vtxo.amount().to_sat(),
                    vtxo.state.kind()
                );
            }
        }

        Ok(())
    }

    pub async fn maintenance(&self) -> Result<(), BarkError> {
        self.inner.maintenance().await?;
        Ok(())
    }

    pub async fn maintenance_with_onchain(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), BarkError> {
        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        self.inner.maintenance_with_onchain(&mut *onchain).await?;
        Ok(())
    }

    pub async fn maintenance_delegated(&self) -> Result<(), BarkError> {
        self.inner.maintenance_delegated().await?;
        Ok(())
    }

    pub async fn maintenance_with_onchain_delegated(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), BarkError> {
        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        self.inner
            .maintenance_with_onchain_delegated(&mut *onchain)
            .await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Address Generation
    // ------------------------------------------------------------------------

    pub async fn new_address(&self) -> Result<String, BarkError> {
        let addr = self.inner.new_address().await?;
        Ok(addr.to_string())
    }

    pub async fn new_address_with_index(&self) -> Result<types::AddressWithIndex, BarkError> {
        let (addr, index) = self.inner.new_address_with_index().await?;
        Ok(types::AddressWithIndex {
            address: addr.to_string(),
            index,
        })
    }

    pub async fn peek_address(&self, index: u32) -> Result<String, BarkError> {
        let addr = self.inner.peek_address(index).await?;
        Ok(addr.to_string())
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    pub async fn balance(&self) -> Result<types::Balance, BarkError> {
        Ok(self.inner.balance().await?.into())
    }

    pub async fn vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<types::Vtxo, BarkError> {
        let id = vtxo_id.parse().map_err(|e| BarkError::InvalidAddress {
            error_message: format!("invalid vtxo id: {}", e),
        })?;
        Ok(self.inner.get_vtxo_by_id(id).await?.into())
    }

    pub async fn spendable_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .spendable_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn all_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .all_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn get_expiring_vtxos(
        &self,
        threshold_blocks: u32,
    ) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .get_expiring_vtxos(threshold_blocks)
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .get_vtxos_to_refresh()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    // ------------------------------------------------------------------------
    // Offboarding
    // ------------------------------------------------------------------------

    pub async fn offboard_all(
        &self,
        bitcoin_address: String,
    ) -> Result<types::OffboardResult, BarkError> {
        let addr = bitcoin_address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::InvalidAddress {
                error_message: e.to_string(),
            })?
            .assume_checked();

        let status = self.inner.offboard_all(addr).await?;
        let round_id = format!("{:?}", status);
        Ok(types::OffboardResult { round_id })
    }

    pub async fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, BarkError> {
        let addr = bitcoin_address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::InvalidAddress {
                error_message: e.to_string(),
            })?
            .assume_checked();

        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid vtxo id: {}", e),
                })
            })
            .collect();

        let status = self.inner.offboard_vtxos(ids?, addr).await?;
        Ok(format!("{:?}", status))
    }

    // ------------------------------------------------------------------------
    // Lightning (send)
    // ------------------------------------------------------------------------

    pub async fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
    ) -> Result<types::LightningSend, BarkError> {
        let invoice: Bolt11Invoice = invoice.parse().map_err(|e| BarkError::InvalidInvoice {
            error_message: format!("invalid invoice: {}", e),
        })?;
        let amount = amount_sats.map(bitcoin::Amount::from_sat);
        let lightning_send = self.inner.pay_lightning_invoice(invoice, amount).await?;
        Ok(lightning_send.into())
    }

    pub async fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
    ) -> Result<types::LightningSend, BarkError> {
        let offer_obj = Offer::from_str(&offer).map_err(|e| BarkError::InvalidInvoice {
            error_message: format!("Invalid BOLT12 offer: {:?}", e),
        })?;
        let amount = amount_sats.map(bitcoin::Amount::from_sat);
        self.inner
            .pay_lightning_offer(offer_obj, amount)
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    pub async fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<Option<String>, BarkError> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                error_message: format!("Invalid payment hash: {}", e),
            })?;
        let payment = self
            .inner
            .check_lightning_payment(payment_hash_obj, wait)
            .await?;
        Ok(payment.and_then(|p| p.preimage).map(|p| p.to_string()))
    }

    pub async fn pending_lightning_sends(&self) -> Result<Vec<types::LightningSend>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_sends()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    // ------------------------------------------------------------------------
    // Lightning (receive)
    // ------------------------------------------------------------------------

    pub async fn bolt11_invoice(
        &self,
        amount_sats: u64,
        description: Option<String>,
    ) -> Result<types::LightningInvoice, BarkError> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let invoice = self.inner.bolt11_invoice(amount, description).await?;
        Ok(types::LightningInvoice {
            invoice: invoice.to_string(),
            payment_hash: invoice.payment_hash().to_string(),
            amount_sats,
        })
    }

    pub async fn try_claim_all_lightning_receives(
        &self,
        wait: bool,
    ) -> Result<Vec<types::LightningReceive>, BarkError> {
        let receives = self.inner.try_claim_all_lightning_receives(wait).await?;
        Ok(receives.into_iter().map(Into::into).collect())
    }

    pub async fn pending_lightning_receives(
        &self,
    ) -> Result<Vec<types::LightningReceive>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_receives()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, BarkError> {
        Ok(self
            .inner
            .claimable_lightning_receive_balance()
            .await?
            .to_sat())
    }

    pub async fn lightning_receive_status(
        &self,
        payment_hash: String,
    ) -> Result<Option<types::LightningReceive>, BarkError> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                error_message: format!("Invalid payment hash: {}", e),
            })?;
        Ok(self
            .inner
            .lightning_receive_status(payment_hash_obj)
            .await?
            .map(Into::into))
    }

    pub async fn try_claim_lightning_receive(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<(), BarkError> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                error_message: format!("Invalid payment hash: {}", e),
            })?;
        self.inner
            .try_claim_lightning_receive(payment_hash_obj, wait, None)
            .await?;
        Ok(())
    }

    pub async fn cancel_lightning_receive(&self, payment_hash: String) -> Result<(), BarkError> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).map_err(|e| BarkError::InvalidInvoice {
                error_message: format!("Invalid payment hash: {}", e),
            })?;
        self.inner
            .cancel_lightning_receive(payment_hash_obj)
            .await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Arkoor
    // ------------------------------------------------------------------------

    pub async fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        let addr: ark::Address = ark_address.parse().map_err(|e| BarkError::InvalidAddress {
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
    }

    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, BarkError> {
        let addr: ark::Address = address.parse().map_err(|e| BarkError::InvalidAddress {
            error_message: format!("invalid ark address: {}", e),
        })?;
        Ok(self.inner.validate_arkoor_address(&addr).await.is_ok())
    }

    // ------------------------------------------------------------------------
    // Onchain send (from offchain balance)
    // ------------------------------------------------------------------------

    pub async fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        let addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::InvalidAddress {
                error_message: e.to_string(),
            })?
            .assume_checked();
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let txid = self.inner.send_onchain(addr, amount).await?;
        Ok(txid.to_string())
    }

    // ------------------------------------------------------------------------
    // History
    // ------------------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<types::Movement>, BarkError> {
        Ok(self
            .inner
            .history()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn history_by_payment_method(
        &self,
        payment_method_type: String,
        payment_method_value: String,
    ) -> Result<Vec<types::Movement>, BarkError> {
        let payment_method = bark::movement::PaymentMethod::from_type_value(
            &payment_method_type,
            &payment_method_value,
        )
        .map_err(|e| BarkError::Internal {
            error_message: format!("Invalid payment method: {}", e),
        })?;

        Ok(self
            .inner
            .history_by_payment_method(&payment_method)
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    // ------------------------------------------------------------------------
    // Refresh
    // ------------------------------------------------------------------------

    pub async fn refresh_vtxos(&self, vtxo_ids: Vec<String>) -> Result<Option<String>, BarkError> {
        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid vtxo id: {}", e),
                })
            })
            .collect();
        let result = self.inner.refresh_vtxos(ids?).await?;
        Ok(result.map(|s| format!("{:?}", s)))
    }

    pub async fn maintenance_refresh(&self) -> Result<Option<String>, BarkError> {
        let result = self.inner.maintenance_refresh().await?;
        Ok(result.map(|s| format!("{:?}", s)))
    }

    pub async fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<types::RoundState>, BarkError> {
        let ids: Result<Vec<_>, _> = vtxo_ids.iter().map(|s| s.parse::<VtxoId>()).collect();
        let ids = ids.map_err(|e| BarkError::InvalidVtxoId {
            error_message: e.to_string(),
        })?;

        let state = self
            .inner
            .refresh_vtxos_delegated(ids)
            .await
            .map_err(BarkError::from)?;
        Ok(state.map(|s| s.into()))
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------

    pub async fn properties(&self) -> Result<types::WalletProperties, BarkError> {
        Ok(self.inner.properties().await?.into())
    }

    pub fn fingerprint(&self) -> String {
        self.inner.fingerprint().to_string()
    }

    pub async fn network(&self) -> Result<types::Network, BarkError> {
        Ok(self.inner.network().await?.into())
    }

    pub async fn config(&self) -> Config {
        let cfg = self.inner.config();
        let props = self.inner.properties().await.unwrap();
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
            daemon_sync_interval_secs: Some(cfg.daemon_sync_interval_secs),
            offboard_required_confirmations: Some(cfg.offboard_required_confirmations),
            daemon_manual_sync: Some(cfg.daemon_manual_sync),
            lightning_receive_claim_retries: Some(cfg.lightning_receive_claim_retries),
        }
    }

    pub async fn ark_info(&self) -> Option<types::ArkInfo> {
        match self.inner.ark_info().await {
            Ok(Some(info)) => Some((&info).into()),
            _ => None,
        }
    }

    pub async fn next_round_start_time(&self) -> Result<u64, BarkError> {
        let system_time = self.inner.next_round_start_time().await?;
        Ok(system_time
            .duration_since(std::time::UNIX_EPOCH)
            .expect("next round time should be after Unix epoch")
            .as_secs())
    }

    // ------------------------------------------------------------------------
    // Boarding (requires onchain wallet)
    // ------------------------------------------------------------------------

    pub async fn board_amount(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
        amount_sats: u64,
    ) -> Result<types::PendingBoard, BarkError> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        log::info!("[BOARD] Boarding {} sats into Ark...", amount_sats);

        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        let pb = self
            .inner
            .board_amount(&mut *onchain, amount)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Board failed: {}", e),
            })?;

        let txid = pb.funding_tx.compute_txid();
        let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();
        log::info!(
            "[BOARD] Board transaction created: {} (VTXO ID: {})",
            txid,
            vtxo_id
        );

        Ok(pb.into())
    }

    pub async fn board_all(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<types::PendingBoard, BarkError> {
        log::info!("[BOARD] Boarding ALL funds into Ark...");

        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        let pb = self
            .inner
            .board_all(&mut *onchain)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Board all failed: {}", e),
            })?;

        let txid = pb.funding_tx.compute_txid();
        let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();
        log::info!(
            "[BOARD] Board transaction created: {} (VTXO ID: {}, amount: {} sats)",
            txid,
            vtxo_id,
            pb.amount.to_sat()
        );

        Ok(pb.into())
    }

    pub async fn sync_pending_boards(&self) -> Result<(), BarkError> {
        log::info!("[BOARD] Syncing pending boards...");
        self.inner
            .sync_pending_boards()
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Sync pending boards failed: {}", e),
            })?;
        log::info!("[BOARD] Pending boards synced");
        Ok(())
    }

    pub async fn pending_boards(&self) -> Result<Vec<types::PendingBoard>, BarkError> {
        Ok(self
            .inner
            .pending_boards()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn pending_board_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .pending_board_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .pending_round_input_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<types::Vtxo>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_send_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    // ------------------------------------------------------------------------
    // Unilateral Exits (requires onchain wallet)
    // ------------------------------------------------------------------------

    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), BarkError> {
        log::info!("[EXIT] Starting unilateral exit for entire wallet...");
        self.inner
            .exit_mgr()
            .start_exit_for_entire_wallet()
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Start exit failed: {}", e),
            })?;
        log::info!("[EXIT] Exit initiated - call sync_exits() periodically to progress");
        Ok(())
    }

    pub async fn sync_exits(&self, onchain_wallet: Arc<OnchainWallet>) -> Result<(), BarkError> {
        log::info!("[EXIT] Syncing exits...");
        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        self.inner
            .sync_exits(&mut *onchain)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Sync exits failed: {}", e),
            })?;
        log::info!("[EXIT] Exits synced");
        Ok(())
    }

    pub async fn progress_exits(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<types::ExitProgressStatus>, BarkError> {
        log::info!("[EXIT] Progressing exits...");

        let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        let result = self
            .inner
            .exit_mgr()
            .progress_exits(&self.inner, &mut *onchain, fee_rate)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Progress exits failed: {}", e),
            })?;

        let statuses = result
            .unwrap_or_default()
            .into_iter()
            .map(Into::into)
            .collect();
        log::info!("[EXIT] Exits progressed");
        Ok(statuses)
    }

    pub async fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), BarkError> {
        log::info!("[EXIT] Starting exit for {} VTXOs...", vtxo_ids.len());

        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid vtxo id: {}", e),
                })
            })
            .collect();

        let mut vtxos = Vec::new();
        for id in ids? {
            let vtxo = self
                .inner
                .get_vtxo_by_id(id)
                .await
                .map_err(|e| BarkError::NotFound {
                    error_message: format!("VTXO not found: {}", e),
                })?;
            vtxos.push(vtxo);
        }

        let vtxo_refs: Vec<ark::Vtxo<ark::vtxo::Bare>> =
            vtxos.iter().map(|v| v.vtxo.to_bare()).collect();

        self.inner
            .exit_mgr()
            .start_exit_for_vtxos(&vtxo_refs)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Start exit for VTXOs failed: {}", e),
            })?;

        log::info!("[EXIT] Exit initiated for {} VTXOs", vtxo_ids.len());
        Ok(())
    }

    pub async fn list_claimable_exits(&self) -> Result<Vec<types::ExitVtxo>, BarkError> {
        let exit_guard = self.inner.exit_mgr();
        let claimable = exit_guard.list_claimable().await;
        Ok(claimable.iter().map(Into::into).collect())
    }

    pub async fn get_exit_vtxos(&self) -> Result<Vec<types::ExitVtxo>, BarkError> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard
            .get_exit_vtxos()
            .await
            .iter()
            .map(Into::into)
            .collect())
    }

    pub async fn has_pending_exits(&self) -> Result<bool, BarkError> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard.has_pending_exits().await)
    }

    pub async fn pending_exits_total_sats(&self) -> Result<u64, BarkError> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard
            .try_pending_total()
            .unwrap_or(bitcoin::Amount::ZERO)
            .to_sat())
    }

    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, BarkError> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard.all_claimable_at_height().await)
    }

    pub async fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<types::ExitTransactionStatus>, BarkError> {
        let vtxo_id_parsed = vtxo_id
            .parse::<VtxoId>()
            .map_err(|e| BarkError::InvalidAddress {
                error_message: format!("invalid vtxo id: {}", e),
            })?;

        let exit_guard = self.inner.exit_mgr();
        let status = exit_guard
            .get_exit_status(vtxo_id_parsed, include_history, include_transactions)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Get exit status failed: {}", e),
            })?;
        Ok(status.map(Into::into))
    }

    pub async fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<types::ExitClaimTransaction, BarkError> {
        log::info!("[EXIT] Draining {} exits to {}...", vtxo_ids.len(), address);

        let addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::InvalidAddress {
                error_message: e.to_string(),
            })?
            .assume_checked();

        let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

        let exit_guard = self.inner.exit_mgr();
        let claimable = exit_guard.list_claimable().await;

        let to_drain: Vec<_> = if vtxo_ids.is_empty() {
            claimable
        } else {
            let requested_ids: std::collections::HashSet<_> = vtxo_ids
                .iter()
                .filter_map(|id| id.parse::<VtxoId>().ok())
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

        let psbt_bytes = psbt.serialize();
        use bitcoin::base64::prelude::*;
        let psbt_base64 = BASE64_STANDARD.encode(&psbt_bytes);

        log::info!(
            "[EXIT] Drain PSBT created (fee: {} sats)",
            fee_sats.to_sat()
        );

        Ok(types::ExitClaimTransaction {
            psbt_base64,
            fee_sats: fee_sats.to_sat(),
        })
    }

    pub async fn sign_exit_claim_inputs(&self, psbt_base64: String) -> Result<String, BarkError> {
        use bitcoin::base64::prelude::*;
        use bitcoin::psbt::Psbt;

        let psbt_bytes = BASE64_STANDARD
            .decode(&psbt_base64)
            .map_err(|e| BarkError::Internal {
                error_message: format!("Invalid base64: {}", e),
            })?;
        let mut psbt = Psbt::deserialize(&psbt_bytes).map_err(|e| BarkError::Internal {
            error_message: format!("Invalid PSBT: {}", e),
        })?;

        let exit_guard = self.inner.exit_mgr();
        exit_guard
            .sign_exit_claim_inputs(&mut psbt, &self.inner)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Sign exit claim inputs failed: {}", e),
            })?;

        let signed_psbt_bytes = psbt.serialize();
        Ok(BASE64_STANDARD.encode(&signed_psbt_bytes))
    }

    // ------------------------------------------------------------------------
    // Round Management
    // ------------------------------------------------------------------------

    pub async fn pending_round_states(&self) -> Result<Vec<types::RoundState>, BarkError> {
        Ok(self
            .inner
            .pending_round_states()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn cancel_pending_round(&self, round_id: u32) -> Result<(), BarkError> {
        use bark::persist::models::RoundStateId;
        self.inner
            .cancel_pending_round(RoundStateId(round_id))
            .await?;
        Ok(())
    }

    pub async fn cancel_all_pending_rounds(&self) -> Result<(), BarkError> {
        self.inner.cancel_all_pending_rounds().await?;
        Ok(())
    }

    pub async fn progress_pending_rounds(&self) -> Result<(), BarkError> {
        self.inner.progress_pending_rounds(None).await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Server
    // ------------------------------------------------------------------------

    pub async fn refresh_server(&self) -> Result<(), BarkError> {
        self.inner.refresh_server().await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // VTXO Expiry & Refresh Scheduling
    // ------------------------------------------------------------------------

    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, BarkError> {
        Ok(self.inner.get_first_expiring_vtxo_blockheight().await?)
    }

    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, BarkError> {
        Ok(self.inner.get_next_required_refresh_blockheight().await?)
    }

    pub async fn maybe_schedule_maintenance_refresh(&self) -> Result<Option<u32>, BarkError> {
        Ok(self
            .inner
            .maybe_schedule_maintenance_refresh()
            .await?
            .map(|id| id.0))
    }

    // ------------------------------------------------------------------------
    // Broadcasting
    // ------------------------------------------------------------------------

    pub async fn broadcast_tx(&self, tx_hex: String) -> Result<String, BarkError> {
        use bitcoin::consensus::encode::deserialize_hex;
        use bitcoin::Transaction;

        let tx: Transaction =
            deserialize_hex(&tx_hex).map_err(|e| BarkError::InvalidTransaction {
                error_message: format!("{}", e),
            })?;

        let txid = tx.compute_txid();
        log::info!("[BROADCAST] Broadcasting transaction: {}", txid);

        self.inner
            .chain()
            .broadcast_tx(&tx)
            .await
            .map_err(|e| BarkError::Network {
                error_message: format!("Broadcast failed: {}", e),
            })?;

        log::info!("[BROADCAST] Transaction broadcasted successfully");
        Ok(txid.to_string())
    }

    // ------------------------------------------------------------------------
    // Mailbox identifiers (sync, no run_async)
    // ------------------------------------------------------------------------

    pub fn mailbox_identifier(&self) -> Result<String, BarkError> {
        let identifier = self.inner.mailbox_identifier();
        Ok(hex::encode(identifier.serialize()))
    }

    pub fn mailbox_authorization(&self) -> Result<String, BarkError> {
        let expiry = chrono::Local::now() + chrono::Duration::hours(24);
        let auth = self.inner.mailbox_authorization(expiry);
        Ok(hex::encode(auth.serialize()))
    }

    // ------------------------------------------------------------------------
    // VTXO Import
    // ------------------------------------------------------------------------

    pub async fn import_vtxo(&self, vtxo_base64: String) -> Result<(), BarkError> {
        let vtxo_bytes = base64::engine::general_purpose::STANDARD
            .decode(&vtxo_base64)
            .map_err(|e| BarkError::Internal {
                error_message: format!("Invalid base64: {}", e),
            })?;

        let vtxo = ark::Vtxo::deserialize(&vtxo_bytes).map_err(|e| BarkError::Internal {
            error_message: format!("Invalid VTXO data: {}", e),
        })?;

        self.inner
            .import_vtxo(&vtxo)
            .await
            .map_err(|e| BarkError::Internal {
                error_message: format!("Failed to import VTXO: {}", e),
            })?;

        log::info!("[IMPORT] VTXO imported successfully");
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    pub async fn estimate_board_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_board_offchain_fee(amount)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, BarkError> {
        let btc_addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::Internal {
                error_message: format!("Failed to parse address: {}", e),
            })?
            .assume_checked();

        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().map_err(|e| BarkError::InvalidVtxoId {
                    error_message: format!("invalid vtxo id: {}", e),
                })
            })
            .collect();
        let ids = ids?;

        let mut vtxos = Vec::new();
        for id in ids {
            let vtxo = self
                .inner
                .get_vtxo_by_id(id)
                .await
                .map_err(|e| BarkError::NotFound {
                    error_message: format!("VTXO not found: {}", e),
                })?;
            vtxos.push(vtxo);
        }

        let estimate = self
            .inner
            .estimate_offboard(&btc_addr, &vtxos)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_refresh_fee(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, BarkError> {
        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().map_err(|e| BarkError::InvalidVtxoId {
                    error_message: format!("invalid vtxo id: {}", e),
                })
            })
            .collect();
        let ids = ids?;

        let mut vtxos = Vec::new();
        for id in ids {
            let vtxo = self
                .inner
                .get_vtxo_by_id(id)
                .await
                .map_err(|e| BarkError::NotFound {
                    error_message: format!("VTXO not found: {}", e),
                })?;
            vtxos.push(vtxo);
        }

        let estimate = self
            .inner
            .estimate_refresh_fee(&vtxos)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_lightning_send_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_lightning_send_fee(amount)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_lightning_receive_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_lightning_receive_fee(amount)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_arkoor_payment_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_arkoor_payment_fee(amount)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_offboard_all_fee(
        &self,
        address: String,
    ) -> Result<types::FeeEstimate, BarkError> {
        let btc_addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::Internal {
                error_message: format!("Failed to parse address: {}", e),
            })?
            .assume_checked();

        let estimate = self
            .inner
            .estimate_offboard_all(&btc_addr)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }

    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, BarkError> {
        let btc_addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::Internal {
                error_message: format!("Failed to parse address: {}", e),
            })?
            .assume_checked();

        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_send_onchain(&btc_addr, amount)
            .await
            .map_err(BarkError::from)?;
        Ok(estimate.into())
    }
}
