use std::str::FromStr;
use std::sync::Arc;

use anyhow::Context;
use base64::Engine;
use log::{info, warn};
use bip39::Mnemonic;
use bitcoin::hex::FromHex;

use ark::lightning::{Invoice, Offer, PaymentHash};
use ark::{ProtocolEncoding, VtxoId};

use bark::WalletSeed;
use bark::onchain::DaemonizableOnchainWallet;
use bark::persist::BarkPersister;

use crate::config::Config;
use crate::core::onchain::OnchainWallet;
use crate::error::Error;
use crate::{types, Network};

/// Core Bark wallet logic. No binding-specific behavior — pure async over
/// `bark::Wallet`. UniFFI / WASM wrappers layer their own concerns on top
/// (run_async, mailbox processor, JsError conversion, etc).
#[derive(Clone)]
pub struct Wallet {
    inner: bark::Wallet,
}

/// Optional arguments for [`Wallet::open`].
pub struct OpenArgs {
    /// Whether to run the background daemon
    ///
    /// When disabled, you must manually call `Wallet::sync` to sync the wallet.
    ///
    /// Default: true
    pub run_daemon: bool,

    /// The data directory to use for this wallet
    ///
    /// This field can be used under most platforms as an alternative to
    /// providing the `persister` and `lock_manager` fields.
    ///
    /// This field is ignored if `persister` and `lock_manager` are provided.
    ///
    /// Default: none
    #[cfg(feature = "uniffi")]
    pub datadir: Option<String>,

    /// The persister to use for this wallet
    ///
    /// Default: returned by [`bark::persist::platform_default`]
    pub persister: Option<Arc<dyn BarkPersister>>,

    /// The lock manager to use for this wallet
    ///
    /// Default: returned by [`bark::lock_manager::platform_default`]
    ///
    /// On some platforms (linux, macos, windows) the default lock manager
    /// requires a datadir be provided.
    #[cfg(not(feature = "wasm-web"))]
    pub lock_manager: Option<Box<dyn bark::lock_manager::LockManager>>,

    /// The onchain wallet to use, if any
    ///
    /// Default: none
    pub onchain: Option<Arc<tokio::sync::RwLock<dyn DaemonizableOnchainWallet>>>,

    /// Whether to create a new wallet if no wallet exists
    ///
    ///  Default: true
    pub create_if_not_exists: bool,

    /// Whether to create a new wallet even if the Ark server cannot be reached
    ///
    /// Default: false
    pub create_without_server: bool,
}

impl Default for OpenArgs {
    fn default() -> Self {
        Self {
            run_daemon: true,
            #[cfg(feature = "uniffi")]
            datadir: None,
            persister: None,
            #[cfg(not(feature = "wasm-web"))]
            lock_manager: None,
            onchain: None,
            create_if_not_exists: true,
            create_without_server: false,
        }
    }
}

impl OpenArgs {
    pub(crate) fn into_bark(self) -> bark::OpenWalletArgs {
        bark::OpenWalletArgs {
            run_daemon: self.run_daemon,

            #[cfg(feature = "uniffi")]
            datadir: self.datadir.map(|s| s.into()),
            #[cfg(not(feature = "uniffi"))]
            datadir: None,

            persister: self.persister,

            #[cfg(not(feature = "wasm-web"))]
            lock_manager: self.lock_manager,
            #[cfg(feature = "wasm-web")]
            lock_manager: None,

            onchain: self.onchain,
            create_if_not_exists: self.create_if_not_exists,
            create_without_server: self.create_without_server,
        }
    }
}

/// Parse a [WalletSeed] from a string that is either a BIP-39 mnemonic or a 64-byte hex seed
pub(crate) fn seed_from_str(
    network: bitcoin::Network,
    mnemonic_or_seed: &str,
) -> Result<WalletSeed, Error> {
    // remove leading or trailing whitespace
    let seed_or_phrase = mnemonic_or_seed.trim();

    // all mnemonics have spaces, no seeds have spaces
    if seed_or_phrase.contains(' ') {
        // mnemonic
        let mnemonic = Mnemonic::parse(seed_or_phrase)
            .context("invalid mnemonic")?;
        Ok(WalletSeed::new_from_mnemonic(network, &mnemonic))
    } else {
        // seed
        let bytes = <[u8; 64]>::from_hex(seed_or_phrase)
            .context("invalid hex seed, needs to be 64 bytes")?;
        Ok(WalletSeed::new_from_seed(network, &bytes))
    }
}

#[allow(dead_code)] // some methods are wired only via the uniffi layer
impl Wallet {
    /// Build from an already-constructed `bark::Wallet`. `pub(crate)` so binding
    /// wrappers that construct the inner wallet themselves (e.g. the uniffi
    /// callback-onchain path) can reuse it.
    pub(crate) fn from_inner(inner: bark::Wallet) -> Self {
        Self { inner }
    }

    pub(crate) fn inner(&self) -> &bark::Wallet {
        &self.inner
    }

    // ------------------------------------------------------------------------
    // Construction
    // ------------------------------------------------------------------------

    /// Raw function to create a new wallet
    ///
    /// You will almost always want to just use the `open` function instead, as
    /// it creates a wallet if it doesn't yet exist by default.
    pub async fn create(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        db: &dyn BarkPersister,
        #[cfg(not(feature = "wasm-web"))]
        lock_manager: &dyn bark::lock_manager::LockManager,
        allow_unreachable_server: bool,
    ) -> Result<(), Error> {
        let network = network.into();
        let cfg = config.into_bark(network);
        let seed = seed_from_str(network, &mnemonic_or_seed)?;

        #[cfg(feature = "wasm-web")]
        let lock_manager = bark::lock_manager::platform_default(
            Option::<&str>::None, Some(seed.fingerprint()),
        )?;
        #[cfg(feature = "wasm-web")]
        let lock_manager = lock_manager.as_ref();

        bark::Wallet::create(
            network, &seed, &cfg, db, lock_manager, allow_unreachable_server,
        ).await?;
        Ok(())
    }

    /// Open a wallet, or create one if it doesn't exist
    pub async fn open(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        args: OpenArgs,
    ) -> Result<Self, Error> {
        let network = network.into();
        let cfg = config.into_bark(network);
        let seed = seed_from_str(network, &mnemonic_or_seed)?;
        let args = args.into_bark();

        let inner = bark::Wallet::open(network, seed, cfg, args).await?;

        if inner.ark_info().await.ok().flatten().is_some() {
            info!("[OPEN] Server connection established");
        } else {
            warn!(
                "[OPEN] Server connection FAILED - Lightning and Ark operations will not work!"
            );
        }

        Ok(Self::from_inner(inner))
    }

    // ------------------------------------------------------------------------
    // Synchronization & Maintenance
    // ------------------------------------------------------------------------

    pub async fn sync(&self) -> Result<(), Error> {
        info!("[SYNC] Starting sync...");
        self.inner.sync().await;
        info!("[SYNC] Sync completed");

        if let Ok(balance) = self.inner.balance().await {
            info!(
                "[SYNC] Balance after sync: spendable={}, pending_board={}",
                balance.spendable.to_sat(),
                balance.pending_board.to_sat()
            );
        }

        if let Ok(vtxos) = self.inner.vtxos().await {
            info!("[SYNC] VTXOs after sync: {} total", vtxos.len());
            for (i, vtxo) in vtxos.iter().enumerate().take(3) {
                info!(
                    "[SYNC]   VTXO {}: {} sats, state={:?}",
                    i,
                    vtxo.vtxo.amount().to_sat(),
                    vtxo.state.kind()
                );
            }
        }

        Ok(())
    }

    pub async fn maintenance(&self) -> Result<(), Error> {
        self.inner.maintenance().await?;
        Ok(())
    }

    /// Scan for spendable VTXOs that were force-exited on-chain without the
    /// user asking (e.g. the server's watchman progressing a shared tree) and
    /// route them into the unilateral-exit flow so the funds can be claimed.
    ///
    /// This already runs automatically as part of [`Self::sync`]; expose it so
    /// callers can trigger the scan on demand.
    pub async fn sync_force_exited_vtxos(&self) -> Result<(), Error> {
        self.inner.sync_force_exited_vtxos().await?;
        Ok(())
    }

    pub async fn maintenance_with_onchain(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), Error> {
        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        self.inner.maintenance_with_onchain(&mut *onchain).await?;
        Ok(())
    }

    pub async fn maintenance_delegated(&self) -> Result<(), Error> {
        self.inner.maintenance_delegated().await?;
        Ok(())
    }

    pub async fn maintenance_with_onchain_delegated(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<(), Error> {
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

    pub async fn new_address(&self) -> Result<String, Error> {
        let addr = self.inner.new_address().await?;
        Ok(addr.to_string())
    }

    pub async fn new_address_with_index(&self) -> Result<types::AddressWithIndex, Error> {
        let (addr, index) = self.inner.new_address_with_index().await?;
        Ok(types::AddressWithIndex {
            address: addr.to_string(),
            index,
        })
    }

    pub async fn peek_address(&self, index: u32) -> Result<String, Error> {
        let addr = self.inner.peek_address(index).await?;
        Ok(addr.to_string())
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    pub async fn balance(&self) -> Result<types::Balance, Error> {
        Ok(self.inner.balance().await?.into())
    }

    pub async fn vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        Ok(self
            .inner
            .vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<types::Vtxo, Error> {
        let id = vtxo_id.parse().context("invalid vtxo id")?;
        Ok(self.inner.get_vtxo_by_id(id).await?.into())
    }

    pub async fn spendable_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        Ok(self
            .inner
            .spendable_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn all_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
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
    ) -> Result<Vec<types::Vtxo>, Error> {
        Ok(self
            .inner
            .get_expiring_vtxos(threshold_blocks)
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<types::Vtxo>, Error> {
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
    ) -> Result<types::OffboardResult, Error> {
        let addr = bitcoin_address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("invalid address")?
            .assume_checked();

        let status = self.inner.offboard_all(addr).await?;
        let round_id = format!("{:?}", status);
        Ok(types::OffboardResult { round_id })
    }

    pub async fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, Error> {
        let addr = bitcoin_address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("invalid address")?
            .assume_checked();

        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| id.parse::<VtxoId>().context("invalid vtxo id"))
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
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let invoice: Invoice = invoice.parse().context("invalid invoice")?;
        let amount = amount_sats.map(bitcoin::Amount::from_sat);
        let resolved = self
            .inner
            .pay_lightning_invoice(invoice, amount, wait)
            .await?;
        self.lightning_send_status(resolved).await
    }

    pub async fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let offer_obj = Offer::from_str(&offer)
            .map_err(|e| anyhow::anyhow!("invalid BOLT12 offer: {e:?}"))?;
        let amount = amount_sats.map(bitcoin::Amount::from_sat);
        let resolved = self
            .inner
            .pay_lightning_offer(offer_obj, amount, wait)
            .await?;
        self.lightning_send_status(resolved).await
    }

    /// Resolve the [`types::LightningSendStatus`] for a just-initiated send.
    /// `bark` now returns only the resolved [`Invoice`] from `pay_lightning_*`,
    /// so the send state is read back from the state machine by payment hash.
    pub(crate) async fn lightning_send_status(
        &self,
        invoice: Invoice,
    ) -> Result<types::LightningSendStatus, Error> {
        let state = self
            .inner
            .lightning_send_state(invoice.payment_hash())
            .await?;
        Ok(state.into())
    }

    pub async fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        let state = self
            .inner
            .check_lightning_payment(payment_hash_obj, wait)
            .await?;
        Ok(state.into())
    }

    /// Read-only triage of a payment hash without driving the send forward.
    /// Use this to poll progress after initiating a payment with `wait = false`.
    /// Unlike [`Self::check_lightning_payment`], this never advances the action.
    pub async fn lightning_send_state(
        &self,
        payment_hash: String,
    ) -> Result<types::LightningSendStatus, Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        let state = self.inner.lightning_send_state(payment_hash_obj).await?;
        Ok(state.into())
    }

    /// Cheap "has this invoice ever been paid?" check, answered from the local
    /// `bark_paid_invoice` fact table without consulting the server.
    pub async fn is_invoice_paid(&self, payment_hash: String) -> Result<bool, Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        Ok(self.inner.is_invoice_paid(payment_hash_obj).await?)
    }

    pub async fn pending_lightning_sends(&self) -> Result<Vec<types::LightningSend>, Error> {
        Ok(self
            .inner
            .pending_lightning_sends()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// List failed lightning sends whose HTLC revocation also failed.
    pub async fn stuck_failed_lightning_sends(
        &self,
    ) -> Result<Vec<types::LightningSend>, Error> {
        Ok(self
            .inner
            .stuck_failed_lightning_sends()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Opt an individual stuck send into auto-exiting its HTLCs as they approach
    /// expiry.
    pub async fn allow_lightning_send_to_exit(
        &self,
        payment_hash: String,
    ) -> Result<(), Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        self.inner
            .allow_lightning_send_to_exit(payment_hash_obj)
            .await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Lightning (receive)
    // ------------------------------------------------------------------------

    pub async fn bolt11_invoice(
        &self,
        amount_sats: u64,
        description: Option<String>,
    ) -> Result<types::LightningInvoice, Error> {
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
    ) -> Result<Vec<types::LightningReceive>, Error> {
        let receives = self.inner.try_claim_all_lightning_receives(wait).await?;
        Ok(receives.into_iter().map(Into::into).collect())
    }

    pub async fn pending_lightning_receives(
        &self,
    ) -> Result<Vec<types::LightningReceive>, Error> {
        Ok(self
            .inner
            .pending_lightning_receives()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, Error> {
        Ok(self
            .inner
            .claimable_lightning_receive_balance()
            .await?
            .to_sat())
    }

    pub async fn lightning_receive_status(
        &self,
        payment_hash: String,
    ) -> Result<Option<types::LightningReceive>, Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
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
    ) -> Result<(), Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        self.inner
            .try_claim_lightning_receive(payment_hash_obj, wait, None)
            .await?;
        Ok(())
    }

    pub async fn cancel_lightning_receive(&self, payment_hash: String) -> Result<(), Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        self.inner
            .cancel_lightning_receive(payment_hash_obj)
            .await?;
        Ok(())
    }

    /// Force-exit an unfinished lightning receive.
    pub async fn attempt_lightning_receive_exit(
        &self,
        payment_hash: String,
    ) -> Result<(), Error> {
        let payment_hash_obj =
            PaymentHash::from_str(&payment_hash).context("invalid payment hash")?;
        self.inner
            .attempt_lightning_receive_exit(payment_hash_obj)
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
    ) -> Result<(), Error> {
        let addr: ark::Address = ark_address.parse().context("invalid ark address")?;
        let amount = bitcoin::Amount::from_sat(amount_sats);
        self.inner.send_arkoor_payment(&addr, amount).await?;
        Ok(())
    }

    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, Error> {
        let addr: ark::Address = address.parse().context("invalid ark address")?;
        Ok(self.inner.validate_arkoor_address(&addr).await.is_ok())
    }

    // ------------------------------------------------------------------------
    // Onchain send (from offchain balance)
    // ------------------------------------------------------------------------

    pub async fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, Error> {
        let addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("invalid address")?
            .assume_checked();
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let txid = self.inner.send_onchain(addr, amount).await?;
        Ok(txid.to_string())
    }

    // ------------------------------------------------------------------------
    // History
    // ------------------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<types::Movement>, Error> {
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
    ) -> Result<Vec<types::Movement>, Error> {
        let payment_method = bark::movement::PaymentMethod::from_type_value(
            &payment_method_type,
            &payment_method_value,
        )
        .context("Invalid payment method")?;

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

    pub async fn refresh_vtxos(&self, vtxo_ids: Vec<String>) -> Result<Option<String>, Error> {
        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().context("invalid vtxo id")
            })
            .collect();
        let result = self.inner.refresh_vtxos(ids?).await?;
        Ok(result.map(|s| format!("{:?}", s)))
    }

    pub async fn maintenance_refresh(&self) -> Result<Option<String>, Error> {
        let result = self.inner.maintenance_refresh().await?;
        Ok(result.map(|s| format!("{:?}", s)))
    }

    pub async fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<types::RoundState>, Error> {
        let ids: Result<Vec<_>, _> = vtxo_ids.iter().map(|s| s.parse::<VtxoId>()).collect();
        let ids = ids.context("invalid VTXO id")?;

        let state = self
            .inner
            .refresh_vtxos_delegated(ids)
            .await?;
        Ok(state.map(|s| s.into()))
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------

    pub async fn properties(&self) -> Result<types::WalletProperties, Error> {
        Ok(self.inner.properties().await?.into())
    }

    pub fn fingerprint(&self) -> String {
        self.inner.fingerprint().to_string()
    }

    pub async fn network(&self) -> Result<types::Network, Error> {
        Ok(self.inner.network().await?.into())
    }

    pub fn config(&self) -> Config {
        let cfg = self.inner.config();
        Config {
            server_address: cfg.server_address.clone(),
            server_access_token: cfg.server_access_token.clone(),
            esplora_address: cfg.esplora_address.clone(),
            bitcoind_address: cfg.bitcoind_address.clone(),
            bitcoind_cookiefile: cfg.bitcoind_cookiefile.as_ref()
                .map(|p| p.to_string_lossy().to_string()),
            bitcoind_user: cfg.bitcoind_user.clone(),
            bitcoind_pass: cfg.bitcoind_pass.clone(),
            vtxo_refresh_expiry_threshold: Some(cfg.vtxo_refresh_expiry_threshold),
            vtxo_exit_margin: Some(cfg.vtxo_exit_margin),
            htlc_recv_claim_delta: Some(cfg.htlc_recv_claim_delta),
            fallback_fee_rate: cfg.fallback_fee_rate.map(|r| r.to_sat_per_kwu()),
            round_tx_required_confirmations: Some(cfg.round_tx_required_confirmations),
            daemon_sync_interval_secs: Some(cfg.daemon_sync_interval_secs),
            offboard_required_confirmations: Some(cfg.offboard_required_confirmations),
            daemon_manual_sync: Some(cfg.daemon_manual_sync),
            lightning_receive_claim_retries: Some(cfg.lightning_receive_claim_retries),
            user_agent: cfg.user_agent.clone(),
        }
    }

    pub async fn ark_info(&self) -> Option<types::ArkInfo> {
        match self.inner.ark_info().await {
            Ok(Some(info)) => Some((&info).into()),
            _ => None,
        }
    }

    pub async fn next_round_start_time(&self) -> Result<u64, Error> {
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
    ) -> Result<types::PendingBoard, Error> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        info!("[BOARD] Boarding {} sats into Ark...", amount_sats);

        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        let pb = self
            .inner
            .board_amount(&mut *onchain, amount)
            .await
            .context("Board failed")?;

        let txid = pb.funding_tx.compute_txid();
        let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();
        info!(
            "[BOARD] Board transaction created: {} (VTXO ID: {})",
            txid,
            vtxo_id
        );

        Ok(pb.into())
    }

    pub async fn board_all(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
    ) -> Result<types::PendingBoard, Error> {
        info!("[BOARD] Boarding ALL funds into Ark...");

        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        let pb = self
            .inner
            .board_all(&mut *onchain)
            .await
            .context("Board all failed")?;

        let txid = pb.funding_tx.compute_txid();
        let vtxo_id = pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default();
        info!(
            "[BOARD] Board transaction created: {} (VTXO ID: {}, amount: {} sats)",
            txid,
            vtxo_id,
            pb.amount.to_sat()
        );

        Ok(pb.into())
    }

    pub async fn sync_pending_boards(&self) -> Result<(), Error> {
        info!("[BOARD] Syncing pending boards...");
        self.inner
            .sync_pending_boards()
            .await
            .context("Sync pending boards failed")?;
        info!("[BOARD] Pending boards synced");
        Ok(())
    }

    pub async fn pending_boards(&self) -> Result<Vec<types::PendingBoard>, Error> {
        Ok(self
            .inner
            .pending_boards()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn pending_board_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        Ok(self
            .inner
            .pending_board_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        Ok(self
            .inner
            .pending_round_input_vtxos()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
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

    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), Error> {
        info!("[EXIT] Starting unilateral exit for entire wallet...");
        self.inner
            .exit_mgr()
            .start_exit_for_entire_wallet()
            .await
            .context("Start exit failed")?;
        info!("[EXIT] Exit initiated - call sync_exits() periodically to progress");
        Ok(())
    }

    pub async fn sync_exits(&self, _onchain_wallet: Arc<OnchainWallet>) -> Result<(), Error> {
        info!("[EXIT] Syncing exits...");
        self.inner
            .sync_exits()
            .await
            .context("Sync exits failed")?;
        info!("[EXIT] Exits synced");
        Ok(())
    }

    pub async fn progress_exits(
        &self,
        onchain_wallet: Arc<OnchainWallet>,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<types::ExitProgressStatus>, Error> {
        info!("[EXIT] Progressing exits...");

        let fee_rate = fee_rate_sat_per_vb.and_then(bitcoin::FeeRate::from_sat_per_vb);

        let bdk = onchain_wallet.inner();
        let mut onchain = bdk.write().await;
        let result = self
            .inner
            .exit_mgr()
            .progress_exits_with_bdk(&self.inner, &mut *onchain, fee_rate)
            .await
            .context("Progress exits failed")?;

        let statuses = result
            .unwrap_or_default()
            .into_iter()
            .map(Into::into)
            .collect();
        info!("[EXIT] Exits progressed");
        Ok(statuses)
    }

    pub async fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), Error> {
        info!("[EXIT] Starting exit for {} VTXOs...", vtxo_ids.len());

        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().context("invalid vtxo id")
            })
            .collect();

        let mut vtxos = Vec::new();
        for id in ids? {
            let vtxo = self
                .inner
                .get_vtxo_by_id(id)
                .await
                .context("VTXO not found")?;
            vtxos.push(vtxo);
        }

        let vtxo_refs: Vec<ark::Vtxo<ark::vtxo::Bare>> =
            vtxos.iter().map(|v| v.vtxo.to_bare()).collect();

        self.inner
            .exit_mgr()
            .start_exit_for_vtxos(&vtxo_refs)
            .await
            .context("Start exit for VTXOs failed")?;

        info!("[EXIT] Exit initiated for {} VTXOs", vtxo_ids.len());
        Ok(())
    }

    pub async fn list_claimable_exits(&self) -> Result<Vec<types::ExitVtxo>, Error> {
        let exit_guard = self.inner.exit_mgr();
        let claimable = exit_guard.list_claimable().await;
        Ok(claimable.iter().map(Into::into).collect())
    }

    pub async fn get_exit_vtxos(&self) -> Result<Vec<types::ExitVtxo>, Error> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard
            .get_exit_vtxos()
            .await
            .iter()
            .map(Into::into)
            .collect())
    }

    pub async fn has_pending_exits(&self) -> Result<bool, Error> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard.has_pending_exits().await)
    }

    pub async fn pending_exits_total_sats(&self) -> Result<u64, Error> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard
            .try_pending_total()
            .unwrap_or(bitcoin::Amount::ZERO)
            .to_sat())
    }

    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, Error> {
        let exit_guard = self.inner.exit_mgr();
        Ok(exit_guard.all_claimable_at_height().await)
    }

    pub async fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<types::ExitTransactionStatus>, Error> {
        let vtxo_id_parsed = vtxo_id
            .parse::<VtxoId>()
            .context("invalid vtxo id")?;

        let exit_guard = self.inner.exit_mgr();
        let status = exit_guard
            .get_exit_status(vtxo_id_parsed, include_history, include_transactions)
            .await
            .context("Get exit status failed")?;
        Ok(status.map(Into::into))
    }

    pub async fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<types::ExitClaimTransaction, Error> {
        info!("[EXIT] Draining {} exits to {}...", vtxo_ids.len(), address);

        let addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("invalid address")?
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
            return Err(anyhow::anyhow!("No claimable exits found").into());
        }

        let psbt = exit_guard
            .drain_exits(&to_drain, &self.inner, addr, fee_rate)
            .await
            .context("Drain exits failed")?;

        let fee_sats = psbt.fee().context("Failed to get fee")?;

        let psbt_bytes = psbt.serialize();
        use bitcoin::base64::prelude::*;
        let psbt_base64 = BASE64_STANDARD.encode(&psbt_bytes);

        info!(
            "[EXIT] Drain PSBT created (fee: {} sats)",
            fee_sats.to_sat()
        );

        Ok(types::ExitClaimTransaction {
            psbt_base64,
            fee_sats: fee_sats.to_sat(),
        })
    }

    pub async fn sign_exit_claim_inputs(&self, psbt_base64: String) -> Result<String, Error> {
        use bitcoin::base64::prelude::*;
        use bitcoin::psbt::Psbt;

        let psbt_bytes = BASE64_STANDARD
            .decode(&psbt_base64)
            .context("Invalid base64")?;
        let mut psbt = Psbt::deserialize(&psbt_bytes).context("Invalid PSBT")?;

        let exit_guard = self.inner.exit_mgr();
        exit_guard
            .sign_exit_claim_inputs(&mut psbt, &self.inner)
            .await
            .context("Sign exit claim inputs failed")?;

        let signed_psbt_bytes = psbt.serialize();
        Ok(BASE64_STANDARD.encode(&signed_psbt_bytes))
    }

    // ------------------------------------------------------------------------
    // Round Management
    // ------------------------------------------------------------------------

    pub async fn pending_round_states(&self) -> Result<Vec<types::RoundState>, Error> {
        Ok(self
            .inner
            .pending_round_states()
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    pub async fn cancel_pending_round(&self, round_id: u32) -> Result<(), Error> {
        use bark::persist::models::RoundStateId;
        self.inner
            .cancel_pending_round(RoundStateId(round_id))
            .await?;
        Ok(())
    }

    pub async fn cancel_all_pending_rounds(&self) -> Result<(), Error> {
        self.inner.cancel_all_pending_rounds().await?;
        Ok(())
    }

    pub async fn progress_pending_rounds(&self) -> Result<(), Error> {
        self.inner.progress_pending_rounds(None).await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Server
    // ------------------------------------------------------------------------

    pub async fn refresh_server(&self) -> Result<(), Error> {
        self.inner.refresh_server().await?;
        Ok(())
    }

    // ------------------------------------------------------------------------
    // VTXO Expiry & Refresh Scheduling
    // ------------------------------------------------------------------------

    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, Error> {
        Ok(self.inner.get_first_expiring_vtxo_blockheight().await?)
    }

    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, Error> {
        Ok(self.inner.get_next_required_refresh_blockheight().await?)
    }

    // ------------------------------------------------------------------------
    // Broadcasting
    // ------------------------------------------------------------------------

    pub async fn broadcast_tx(&self, tx_hex: String) -> Result<String, Error> {
        use bitcoin::consensus::encode::deserialize_hex;
        use bitcoin::Transaction;

        let tx: Transaction =
            deserialize_hex(&tx_hex).context("invalid transaction")?;

        let txid = tx.compute_txid();
        info!("[BROADCAST] Broadcasting transaction: {}", txid);

        self.inner
            .chain()
            .broadcast_tx(&tx)
            .await
            .context("Broadcast failed")?;

        info!("[BROADCAST] Transaction broadcasted successfully");
        Ok(txid.to_string())
    }

    // ------------------------------------------------------------------------
    // Mailbox identifiers (sync, no run_async)
    // ------------------------------------------------------------------------

    pub fn mailbox_identifier(&self) -> Result<String, Error> {
        let identifier = self.inner.mailbox_identifier();
        Ok(hex::encode(identifier.serialize()))
    }

    pub fn mailbox_authorization(&self) -> Result<String, Error> {
        let expiry = chrono::Local::now() + chrono::Duration::hours(24);
        let auth = self.inner.mailbox_authorization(expiry);
        Ok(hex::encode(auth.serialize()))
    }

    // ------------------------------------------------------------------------
    // VTXO Import
    // ------------------------------------------------------------------------

    pub async fn import_vtxo(&self, vtxo_base64: String) -> Result<(), Error> {
        let vtxo_bytes = base64::engine::general_purpose::STANDARD
            .decode(&vtxo_base64)
            .context("Invalid base64")?;

        let vtxo = ark::Vtxo::deserialize(&vtxo_bytes).context("Invalid VTXO data")?;

        self.inner
            .import_vtxo(&vtxo)
            .await
            .context("Failed to import VTXO")?;

        info!("[IMPORT] VTXO imported successfully");
        Ok(())
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    pub async fn estimate_board_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_board_offchain_fee(amount)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, Error> {
        let btc_addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("Failed to parse address")?
            .assume_checked();

        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().context("invalid vtxo id")
            })
            .collect();
        let ids = ids?;

        let mut vtxos = Vec::new();
        for id in ids {
            let vtxo = self
                .inner
                .get_vtxo_by_id(id)
                .await
                .context("VTXO not found")?;
            vtxos.push(vtxo);
        }

        let estimate = self
            .inner
            .estimate_offboard(&btc_addr, &vtxos)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_refresh_fee(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, Error> {
        let ids: Result<Vec<_>, _> = vtxo_ids
            .iter()
            .map(|id| {
                id.parse::<VtxoId>().context("invalid vtxo id")
            })
            .collect();
        let ids = ids?;

        let mut vtxos = Vec::new();
        for id in ids {
            let vtxo = self
                .inner
                .get_vtxo_by_id(id)
                .await
                .context("VTXO not found")?;
            vtxos.push(vtxo);
        }

        let estimate = self
            .inner
            .estimate_refresh_fee(&vtxos)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_lightning_send_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_lightning_send_fee(amount)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_lightning_receive_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_lightning_receive_fee(amount)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_arkoor_payment_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_arkoor_payment_fee(amount)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_offboard_all_fee(
        &self,
        address: String,
    ) -> Result<types::FeeEstimate, Error> {
        let btc_addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("Failed to parse address")?
            .assume_checked();

        let estimate = self
            .inner
            .estimate_offboard_all(&btc_addr)
            .await?;
        Ok(estimate.into())
    }

    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let btc_addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("Failed to parse address")?
            .assume_checked();

        let amount = bitcoin::Amount::from_sat(amount_sats);
        let estimate = self
            .inner
            .estimate_send_onchain(&btc_addr, amount)
            .await?;
        Ok(estimate.into())
    }
}
