use std::sync::Arc;

use anyhow::Context;
use tokio_util::sync::CancellationToken;

use crate::{types, Error};
use crate::config::Config;
use crate::core::notification::NotificationHolder;
use crate::core::wallet::{Wallet as CoreWallet, OpenArgs as CoreOpenArgs};
use crate::types::Network;
use crate::muniffi::db::open_sqlite_db;
use crate::muniffi::onchain::OnchainWallet;
use crate::muniffi::runtime::run_async;

/// Optional arguments for [`Wallet::open`], mirroring [`bark::OpenWalletArgs`].
///
/// Every field has a default, so callers only set what they need.
#[derive(uniffi::Record)]
pub struct WalletOpenArgs {
    /// Whether to run the background daemon
    ///
    /// When disabled, you must manually call `Wallet::sync` to sync the wallet.
    ///
    /// Default: true
    #[uniffi(default = true)]
    pub run_daemon: bool,

    /// The data directory to use for this wallet
    pub datadir: String,

    /// The onchain wallet to use, if any
    ///
    /// Default: none
    #[uniffi(default = None)]
    pub onchain: Option<Arc<OnchainWallet>>,

    /// Whether to create a new wallet if no wallet exists
    ///
    ///  Default: true
    #[uniffi(default = true)]
    pub create_if_not_exists: bool,

    /// Whether to create a new wallet even if the Ark server cannot be reached
    ///
    /// Default: false
    #[uniffi(default = false)]
    pub create_without_server: bool,

    /// Whether to skip the seed-recovery mailbox scan
    ///
    /// The scan runs on the open that creates the wallet locally and makes
    /// network calls; its result is available from `Wallet::recovery_report`.
    /// Set this to open without it.
    ///
    /// Default: false
    #[uniffi(default = false)]
    pub skip_recovery: bool,
}

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
    core: CoreWallet,
    /// Direct handle to bark::Wallet so callback-onchain methods can bypass
    /// `core::Wallet` (which only knows BDK).
    inner: bark::Wallet,
    #[allow(dead_code)]
    mailbox_cancel: CancellationToken,
}

impl Wallet {
    fn wrap(core: CoreWallet) -> Arc<Self> {
        let inner = core.inner().clone();
        let cancel = CancellationToken::new();
        Arc::new(Self {
            core,
            inner,
            mailbox_cancel: cancel,
        })
    }
}

/// Low-level function to initialize a wallet
///
/// You probably want to use [`Wallet::open`] instead.
#[uniffi::export(async_runtime = "tokio")]
pub async fn init_wallet(
    network: Network,
    mnemonic_or_seed: String,
    config: Config,
    datadir: String,
    allow_unreachable_server: bool,
) -> Result<(), Error> {
    run_async(async move {
        let db = open_sqlite_db(&datadir)
            .with_context(|| format!("opening sqlite in {}", datadir))?;
        let lock_manager = bark::lock_manager::platform_default(Some(&datadir), None)?;
        CoreWallet::create(
            network, mnemonic_or_seed, config, &*db, &*lock_manager, allow_unreachable_server,
        ).await?;
        Ok(())
    })
    .await
}

#[uniffi::export(async_runtime = "tokio")]
impl Wallet {
    // ------------------------------------------------------------------------
    // Construction
    // ------------------------------------------------------------------------

    /// Open a wallet (creating it first if `create_if_not_exists` is set),
    /// mirroring [`bark::Wallet::open`]: a single entry point with everything
    /// else optional (see [`WalletOpenArgs`]). For the explicit
    /// initialize-but-don't-open path, use the top-level `init_wallet`.
    ///
    /// `mnemonic_or_seed` accepts either a BIP-39 mnemonic phrase or a 64-byte
    /// hex-encoded seed.
    #[uniffi::constructor]
    pub async fn open(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        args: WalletOpenArgs,
    ) -> Result<Arc<Self>, Error> {
        run_async(async move {
            let core = CoreWallet::open(network, mnemonic_or_seed, config, CoreOpenArgs {
                persister: Some(open_sqlite_db(&args.datadir)?),
                datadir: Some(args.datadir),
                lock_manager: None,
                onchain: args.onchain.map(|w| w.inner_dyn()),
                run_daemon: args.run_daemon,
                create_if_not_exists: args.create_if_not_exists,
                create_without_server: args.create_without_server,
                skip_recovery: args.skip_recovery,
            })
            .await?;
            Ok(Self::wrap(core))
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Sync & Maintenance
    // ------------------------------------------------------------------------

    pub async fn sync(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.sync().await }).await
    }

    /// Scan for VTXOs that were force-exited on-chain without the user asking
    /// and route them into the unilateral-exit flow so the funds can be claimed.
    ///
    /// This already runs automatically as part of [`Self::sync`]; call it
    /// directly to trigger the scan on demand.
    pub async fn sync_force_exited_vtxos(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.sync_force_exited_vtxos().await }).await
    }

    pub async fn maintenance(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.maintenance().await }).await
    }

    pub async fn maintenance_delegated(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.maintenance_delegated().await }).await
    }

    // ------------------------------------------------------------------------
    // Address
    // ------------------------------------------------------------------------

    pub async fn new_address(&self) -> Result<String, Error> {
        let core = self.core.clone();
        run_async(async move { core.new_address().await }).await
    }

    pub async fn new_address_with_index(&self) -> Result<types::AddressWithIndex, Error> {
        let core = self.core.clone();
        run_async(async move { core.new_address_with_index().await }).await
    }

    pub async fn peek_address(&self, index: u32) -> Result<String, Error> {
        let core = self.core.clone();
        run_async(async move { core.peek_address(index).await }).await
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    pub async fn balance(&self) -> Result<types::Balance, Error> {
        let core = self.core.clone();
        run_async(async move { core.balance().await }).await
    }

    pub async fn vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.vtxos().await }).await
    }

    pub async fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<types::Vtxo, Error> {
        let core = self.core.clone();
        run_async(async move { core.get_vtxo_by_id(vtxo_id).await }).await
    }

    pub async fn spendable_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.spendable_vtxos().await }).await
    }

    pub async fn all_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.all_vtxos().await }).await
    }

    pub async fn get_expiring_vtxos(
        &self,
        threshold_blocks: u32,
    ) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.get_expiring_vtxos(threshold_blocks).await }).await
    }

    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.get_vtxos_to_refresh().await }).await
    }

    // ------------------------------------------------------------------------
    // Offboarding
    // ------------------------------------------------------------------------

    pub async fn offboard_all(
        &self,
        bitcoin_address: String,
    ) -> Result<types::OffboardResult, Error> {
        let core = self.core.clone();
        run_async(async move { core.offboard_all(bitcoin_address).await }).await
    }

    pub async fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<types::OffboardResult, Error> {
        let core = self.core.clone();
        run_async(async move { core.offboard_vtxos(vtxo_ids, bitcoin_address).await }).await
    }

    // ------------------------------------------------------------------------
    // Lightning (send)
    // ------------------------------------------------------------------------

    #[uniffi::method(default(wait = false))]
    pub async fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let core = self.core.clone();
        run_async(async move { core.pay_lightning_invoice(invoice, amount_sats, wait).await }).await
    }

    /// Pay to a Lightning Address (`user@domain`), resolved via LNURL-pay.
    #[uniffi::method(default(wait = false))]
    pub async fn pay_lightning_address(
        &self,
        lightning_address: String,
        amount_sats: u64,
        comment: Option<String>,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let core = self.core.clone();
        run_async(async move {
            core.pay_lightning_address(lightning_address, amount_sats, comment, wait)
                .await
        })
        .await
    }

    /// Pay a raw LNURL-pay link (`lnurl1…`).
    ///
    /// Resolves the LNURL-pay endpoint to a BOLT11 invoice and pays it. Errors
    /// if the link decodes to a non-pay LNURL (auth, withdraw, channel).
    #[uniffi::method(default(wait = false))]
    pub async fn pay_lnurl(
        &self,
        lnurl: String,
        amount_sats: u64,
        comment: Option<String>,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let core = self.core.clone();
        run_async(async move { core.pay_lnurl(lnurl, amount_sats, comment, wait).await }).await
    }

    #[uniffi::method(default(wait = false))]
    pub async fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let core = self.core.clone();
        run_async(async move { core.pay_lightning_offer(offer, amount_sats, wait).await }).await
    }

    #[uniffi::method(default(wait = false))]
    pub async fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<types::LightningSendStatus, Error> {
        let core = self.core.clone();
        run_async(async move { core.check_lightning_payment(payment_hash, wait).await }).await
    }

    pub async fn lightning_send_state(
        &self,
        payment_hash: String,
    ) -> Result<types::LightningSendStatus, Error> {
        let core = self.core.clone();
        run_async(async move { core.lightning_send_state(payment_hash).await }).await
    }

    pub async fn is_invoice_paid(&self, payment_hash: String) -> Result<bool, Error> {
        let core = self.core.clone();
        run_async(async move { core.is_invoice_paid(payment_hash).await }).await
    }

    pub async fn pending_lightning_sends(&self) -> Result<Vec<types::LightningSend>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_lightning_sends().await }).await
    }

    pub async fn stuck_failed_lightning_sends(
        &self,
    ) -> Result<Vec<types::LightningSend>, Error> {
        let core = self.core.clone();
        run_async(async move { core.stuck_failed_lightning_sends().await }).await
    }

    pub async fn allow_lightning_send_to_exit(
        &self,
        payment_hash: String,
    ) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.allow_lightning_send_to_exit(payment_hash).await }).await
    }

    // ------------------------------------------------------------------------
    // Lightning (receive)
    // ------------------------------------------------------------------------

    #[uniffi::method(default(token = None))]
    pub async fn bolt11_invoice(
        &self,
        amount_sats: u64,
        description: Option<String>,
        token: Option<String>,
    ) -> Result<types::LightningInvoice, Error> {
        let core = self.core.clone();
        run_async(async move { core.bolt11_invoice(amount_sats, description, token).await }).await
    }

    /// Create an invoice whose claimed VTXO is delivered to `claim_destination`
    /// (an Ark address), letting that wallet receive while offline.
    ///
    /// The claim is signed directly to that address's own policy, so this wallet
    /// has no custodial control and cannot redirect the payment. It can still
    /// strand it: delivering the signed output to the destination's mailbox is a
    /// separate step only this wallet can perform, and the recipient has no
    /// independent way to recover the funds until it happens. Delivery resumes
    /// automatically on restart, so a crash recovers on its own — but running
    /// this for someone else means they trust you to stay online and eventually
    /// deliver, not that they trust you with custody.
    ///
    /// A `claim_destination` owned by this wallet is claimed locally instead of
    /// going through its mailbox.
    #[uniffi::method(default(description = None, token = None))]
    pub async fn bolt11_invoice_for_address(
        &self,
        amount_sats: u64,
        claim_destination: String,
        description: Option<String>,
        token: Option<String>,
    ) -> Result<types::LightningInvoice, Error> {
        let core = self.core.clone();
        run_async(async move {
            core.bolt11_invoice_for_address(
                amount_sats, claim_destination, description, token,
            )
            .await
        })
        .await
    }

    #[uniffi::method(default(wait = false))]
    pub async fn try_claim_all_lightning_receives(
        &self,
        wait: bool,
    ) -> Result<Vec<types::LightningReceive>, Error> {
        let core = self.core.clone();
        run_async(async move { core.try_claim_all_lightning_receives(wait).await }).await
    }

    pub async fn pending_lightning_receives(
        &self,
    ) -> Result<Vec<types::LightningReceive>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_lightning_receives().await }).await
    }

    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, Error> {
        let core = self.core.clone();
        run_async(async move { core.claimable_lightning_receive_balance_sats().await }).await
    }

    /// Triage a payment hash: settled or in-progress. Errors if no lightning
    /// receive is known for this payment hash.
    pub async fn lightning_receive_state(
        &self,
        payment_hash: String,
    ) -> Result<types::LightningReceive, Error> {
        let core = self.core.clone();
        run_async(async move { core.lightning_receive_state(payment_hash).await }).await
    }

    #[uniffi::method(default(wait = false))]
    pub async fn try_claim_lightning_receive(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<types::LightningReceive, Error> {
        let core = self.core.clone();
        run_async(async move { core.try_claim_lightning_receive(payment_hash, wait).await }).await
    }

    pub async fn cancel_lightning_receive(&self, payment_hash: String) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.cancel_lightning_receive(payment_hash).await }).await
    }

    pub async fn attempt_lightning_receive_exit(
        &self,
        payment_hash: String,
    ) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.attempt_lightning_receive_exit(payment_hash).await }).await
    }

    // ------------------------------------------------------------------------
    // Arkoor
    // ------------------------------------------------------------------------

    pub async fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.send_arkoor_payment(ark_address, amount_sats).await }).await
    }

    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, Error> {
        let core = self.core.clone();
        run_async(async move { core.validate_arkoor_address(address).await }).await
    }

    pub async fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, Error> {
        let core = self.core.clone();
        run_async(async move { core.send_onchain(address, amount_sats).await }).await
    }

    // ------------------------------------------------------------------------
    // History
    // ------------------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<types::Movement>, Error> {
        let core = self.core.clone();
        run_async(async move { core.history().await }).await
    }

    pub async fn history_by_payment_method(
        &self,
        payment_method_type: String,
        payment_method_value: String,
    ) -> Result<Vec<types::Movement>, Error> {
        let core = self.core.clone();
        run_async(async move {
            core.history_by_payment_method(payment_method_type, payment_method_value)
                .await
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Refresh
    // ------------------------------------------------------------------------

    pub async fn refresh_vtxos(&self, vtxo_ids: Vec<String>) -> Result<Option<String>, Error> {
        let core = self.core.clone();
        run_async(async move { core.refresh_vtxos(vtxo_ids).await }).await
    }

    pub async fn maintenance_refresh(&self) -> Result<Option<String>, Error> {
        let core = self.core.clone();
        run_async(async move { core.maintenance_refresh().await }).await
    }

    pub async fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<types::RoundState>, Error> {
        let core = self.core.clone();
        run_async(async move { core.refresh_vtxos_delegated(vtxo_ids).await }).await
    }

    /// Schedule a delegated refresh for `scheduled_height` instead of the next
    /// round. The refresh fee is priced against the VTXO's remaining lifetime at
    /// that height, and the server charges less the closer a VTXO is to expiry,
    /// so scheduling further out never costs more than refreshing now.
    pub async fn refresh_vtxos_scheduled(
        &self,
        vtxo_ids: Vec<String>,
        scheduled_height: u32,
    ) -> Result<Option<types::RoundState>, Error> {
        let core = self.core.clone();
        run_async(async move {
            core.refresh_vtxos_scheduled(vtxo_ids, scheduled_height).await
        })
        .await
    }

    // ------------------------------------------------------------------------
    // Recovery
    // ------------------------------------------------------------------------

    /// Recover the given VTXO ids from the server, importing the ones this
    /// wallet owns that are still spendable. Use it to retry ids a previous
    /// scan reported as `failed`.
    pub async fn recover_vtxos(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<types::RecoveryReport, Error> {
        let core = self.core.clone();
        run_async(async move { core.recover_vtxos(vtxo_ids).await }).await
    }

    /// Result of the seed-recovery scan that ran during `Wallet::open`, or none
    /// if no report was produced.
    ///
    /// Recovery only runs on the open that creates the wallet locally, and not
    /// at all when `WalletOpenArgs.skip_recovery` is set, so this is empty on
    /// every subsequent open. It is also empty when the scan itself failed
    /// outright — bark logs that and lets open succeed, so an empty result does
    /// not prove no funds are missing. `isComplete == false` means funds may
    /// still be missing; retry the report's `failed` ids with `recoverVtxos`.
    pub fn recovery_report(&self) -> Option<types::RecoveryReport> {
        self.core.recovery_report()
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------

    pub async fn properties(&self) -> Result<types::WalletProperties, Error> {
        let core = self.core.clone();
        run_async(async move { core.properties().await }).await
    }

    pub fn fingerprint(&self) -> String {
        self.core.fingerprint()
    }

    pub async fn network(&self) -> Result<types::Network, Error> {
        let core = self.core.clone();
        run_async(async move { core.network().await }).await
    }

    pub async fn config(&self) -> Config {
        let core = self.core.clone();
        run_async(async move { core.config() }).await
    }

    pub async fn ark_info(&self) -> Option<types::ArkInfo> {
        let core = self.core.clone();
        run_async(async move { core.ark_info().await }).await
    }

    pub async fn next_round_start_time(&self) -> Result<u64, Error> {
        let core = self.core.clone();
        run_async(async move { core.next_round_start_time().await }).await
    }

    // ------------------------------------------------------------------------
    // Boarding (requires onchain wallet)
    // ------------------------------------------------------------------------

    pub async fn board_amount(
        &self,
        amount_sats: u64,
    ) -> Result<types::PendingBoard, Error> {
        let core = self.core.clone();
        run_async(async move { core.board_amount(amount_sats).await }).await
    }

    pub async fn board_all(&self) -> Result<types::PendingBoard, Error> {
        let core = self.core.clone();
        run_async(async move { core.board_all().await }).await
    }

    pub async fn sync_pending_boards(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.sync_pending_boards().await }).await
    }

    pub async fn pending_boards(&self) -> Result<Vec<types::PendingBoard>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_boards().await }).await
    }

    pub async fn pending_board_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_board_vtxos().await }).await
    }

    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_round_input_vtxos().await }).await
    }

    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<types::Vtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_lightning_send_vtxos().await }).await
    }

    // ------------------------------------------------------------------------
    // Unilateral Exits
    // ------------------------------------------------------------------------

    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.start_exit_for_entire_wallet().await }).await
    }

    pub async fn sync_exits(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.sync_exits().await }).await
    }

    pub async fn progress_exits(
        &self,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<types::ExitProgressStatus>, Error> {
        let core = self.core.clone();
        run_async(async move { core.progress_exits(fee_rate_sat_per_vb).await }).await
    }

    pub async fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.start_exit_for_vtxos(vtxo_ids).await }).await
    }

    pub async fn list_claimable_exits(&self) -> Result<Vec<types::ExitVtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.list_claimable_exits().await }).await
    }

    pub async fn get_exit_vtxos(&self) -> Result<Vec<types::ExitVtxo>, Error> {
        let core = self.core.clone();
        run_async(async move { core.get_exit_vtxos().await }).await
    }

    pub async fn has_pending_exits(&self) -> Result<bool, Error> {
        let core = self.core.clone();
        run_async(async move { core.has_pending_exits().await }).await
    }

    pub async fn pending_exits_total_sats(&self) -> Result<u64, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_exits_total_sats().await }).await
    }

    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, Error> {
        let core = self.core.clone();
        run_async(async move { core.all_exits_claimable_at_height().await }).await
    }

    pub async fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<types::ExitTransactionStatus>, Error> {
        let core = self.core.clone();
        run_async(async move {
            core.get_exit_status(vtxo_id, include_history, include_transactions)
                .await
        })
        .await
    }

    pub async fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<types::ExitClaimTransaction, Error> {
        let core = self.core.clone();
        run_async(async move {
            core.drain_exits(vtxo_ids, address, fee_rate_sat_per_vb)
                .await
        })
        .await
    }

    pub async fn sign_exit_claim_inputs(&self, psbt_base64: String) -> Result<String, Error> {
        let core = self.core.clone();
        run_async(async move { core.sign_exit_claim_inputs(psbt_base64).await }).await
    }

    // ------------------------------------------------------------------------
    // Rounds
    // ------------------------------------------------------------------------

    pub async fn pending_round_states(&self) -> Result<Vec<types::RoundState>, Error> {
        let core = self.core.clone();
        run_async(async move { core.pending_round_states().await }).await
    }

    pub async fn cancel_pending_round(&self, round_id: u32) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.cancel_pending_round(round_id).await }).await
    }

    pub async fn cancel_all_pending_rounds(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.cancel_all_pending_rounds().await }).await
    }

    pub async fn progress_pending_rounds(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.progress_pending_rounds().await }).await
    }

    // ------------------------------------------------------------------------
    // Server
    // ------------------------------------------------------------------------

    pub async fn refresh_server(&self) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.refresh_server().await }).await
    }

    // ------------------------------------------------------------------------
    // VTXO Expiry & Refresh Scheduling
    // ------------------------------------------------------------------------

    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, Error> {
        let core = self.core.clone();
        run_async(async move { core.get_first_expiring_vtxo_blockheight().await }).await
    }

    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, Error> {
        let core = self.core.clone();
        run_async(async move { core.get_next_required_refresh_blockheight().await }).await
    }

    // ------------------------------------------------------------------------
    // Broadcasting
    // ------------------------------------------------------------------------

    pub async fn broadcast_tx(&self, tx_hex: String) -> Result<String, Error> {
        let core = self.core.clone();
        run_async(async move { core.broadcast_tx(tx_hex).await }).await
    }

    // ------------------------------------------------------------------------
    // Mailbox
    // ------------------------------------------------------------------------

    pub fn mailbox_identifier(&self) -> Result<String, Error> {
        self.core.mailbox_identifier()
    }

    pub fn mailbox_authorization(&self) -> Result<String, Error> {
        self.core.mailbox_authorization()
    }

    // ------------------------------------------------------------------------
    // VTXO Import / Export
    // ------------------------------------------------------------------------

    /// Import a VTXO from its serialized form (hex or base64).
    ///
    /// The parameter keeps its historical `vtxo_base64` name for foreign
    /// binding compatibility (uniffi exposes parameter names), but hex as
    /// returned by [`Wallet::vtxo_encoded`] is accepted too.
    pub async fn import_vtxo(&self, vtxo_base64: String) -> Result<(), Error> {
        let core = self.core.clone();
        run_async(async move { core.import_vtxo(vtxo_base64).await }).await
    }

    /// Hex-encoded serialization of the full VTXO (genesis chain included),
    /// re-importable via [`Wallet::import_vtxo`]. Mirrors bark-rest
    /// `GET /vtxos/{id}/encoded`.
    pub async fn vtxo_encoded(&self, vtxo_id: String) -> Result<String, Error> {
        let core = self.core.clone();
        run_async(async move { core.vtxo_encoded(vtxo_id).await }).await
    }

    // ------------------------------------------------------------------------
    // Fee Estimation
    // ------------------------------------------------------------------------

    pub async fn estimate_board_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_board_fee(amount_sats).await }).await
    }

    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_offboard_fee(address, vtxo_ids).await }).await
    }

    pub async fn estimate_refresh_fee(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_refresh_fee(vtxo_ids).await }).await
    }

    pub async fn estimate_lightning_send_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_lightning_send_fee(amount_sats).await }).await
    }

    pub async fn estimate_lightning_receive_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_lightning_receive_fee(amount_sats).await }).await
    }

    pub async fn estimate_arkoor_payment_fee(
        &self,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_arkoor_payment_fee(amount_sats).await }).await
    }

    pub async fn estimate_offboard_all_fee(
        &self,
        address: String,
    ) -> Result<types::FeeEstimate, Error> {
        let core = self.core.clone();
        run_async(async move { core.estimate_offboard_all_fee(address).await }).await
    }

    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<types::FeeEstimate, Error> {
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

    /// Start the background daemon. The onchain wallet used by the daemon is
    /// the one supplied to `Wallet::open` (see `WalletOpenArgs.onchain`).
    pub async fn run_daemon(&self) -> Result<(), Error> {
        let inner = self.inner.clone();
        run_async(async move { inner.start_daemon().map_err(Error::from) }).await?;
        Ok(())
    }

    pub async fn stop_daemon(&self) -> Result<(), Error> {
        self.inner.stop_daemon();
        Ok(())
    }
}

impl Drop for Wallet {
    fn drop(&mut self) {
        self.inner.stop_daemon();
    }
}
