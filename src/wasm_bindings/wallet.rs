use std::sync::Arc;
use std::time::Duration;

use bark::Wallet as InnerWallet;
use tokio_util::sync::CancellationToken;
use wasm_bindgen::prelude::*;

use crate::config::Config;
use crate::core::wallet::Wallet as CoreWallet;
use crate::error::BarkError;
use crate::types::{
    AddressWithIndex, ArkInfo, Balance, ExitClaimTransaction, ExitProgressStatus,
    ExitTransactionStatus, ExitVtxo, FeeEstimate, LightningInvoice, LightningReceive,
    LightningSend, Movement, Network, OffboardResult, PendingBoard, RoundState, Vtxo,
    WalletProperties,
};
use crate::wasm_bindings::db::indexed_db_client;
use crate::wasm_bindings::notification::NotificationHolder;
use crate::wasm_bindings::onchain::OnchainWallet;

fn bark_err(e: BarkError) -> JsError {
    JsError::new(&e.message())
}

#[wasm_bindgen]
pub struct Wallet {
    core: Arc<CoreWallet>,
    #[allow(dead_code)]
    mailbox_cancel: CancellationToken,
}

impl Wallet {
    fn wrap(core: CoreWallet) -> Self {
        let inner = core.inner();
        let cancel = CancellationToken::new();
        Self::start_mailbox_processor(inner, cancel.clone());
        Self {
            core: Arc::new(core),
            mailbox_cancel: cancel,
        }
    }

    fn start_mailbox_processor(inner: Arc<InnerWallet>, cancel: CancellationToken) {
        wasm_bindgen_futures::spawn_local(async move {
            let mut retry_delay: u64 = 1;

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
                        log::warn!(
                            "[MAILBOX] error: {:?}, retrying in {}s",
                            e,
                            retry_delay
                        );
                        tokio::select! {
                            _ = cancel.cancelled() => {
                                log::info!("[MAILBOX] shutting down");
                                return;
                            }
                            _ = gloo_timers::future::sleep(Duration::from_secs(retry_delay)) => {}
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
                    _ = gloo_timers::future::sleep(Duration::from_secs(1)) => {}
                }
            }
        });
    }
}

impl Drop for Wallet {
    fn drop(&mut self) {
        self.mailbox_cancel.cancel();
    }
}

#[wasm_bindgen]
impl Wallet {
    // -- Construction ---------------------------------------------------------

    pub async fn create(
        mnemonic: String,
        config: Config,
        db_name: String,
        force_rescan: bool,
    ) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&db_name).await.map_err(bark_err)?;
        let core = CoreWallet::create(mnemonic, config, db, force_rescan).await.map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    pub async fn open(
        mnemonic: String,
        config: Config,
        db_name: String,
    ) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&db_name).await.map_err(bark_err)?;
        let core = CoreWallet::open(mnemonic, config, db).await.map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    #[wasm_bindgen(js_name = createWithOnchain)]
    pub async fn create_with_onchain(
        mnemonic: String,
        config: Config,
        db_name: String,
        onchain_wallet: &OnchainWallet,
        force_rescan: bool,
    ) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&db_name).await.map_err(bark_err)?;
        let onchain = onchain_wallet.inner();
        let core = CoreWallet::create_with_onchain(mnemonic, config, db, onchain, force_rescan)
            .await
            .map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    #[wasm_bindgen(js_name = openWithOnchain)]
    pub async fn open_with_onchain(
        mnemonic: String,
        config: Config,
        db_name: String,
        onchain_wallet: &OnchainWallet,
    ) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&db_name).await.map_err(bark_err)?;
        let onchain = onchain_wallet.inner();
        let core = CoreWallet::open_with_onchain(mnemonic, config, db, onchain)
            .await
            .map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    // -- Sync & Maintenance ---------------------------------------------------

    pub async fn sync(&self) -> Result<(), JsError> {
        self.core.sync().await.map_err(bark_err)
    }

    pub async fn maintenance(&self) -> Result<(), JsError> {
        self.core.maintenance().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceWithOnchain)]
    pub async fn maintenance_with_onchain(
        &self,
        onchain_wallet: &OnchainWallet,
    ) -> Result<(), JsError> {
        self.core.maintenance_with_onchain(onchain_wallet.inner()).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceDelegated)]
    pub async fn maintenance_delegated(&self) -> Result<(), JsError> {
        self.core.maintenance_delegated().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceWithOnchainDelegated)]
    pub async fn maintenance_with_onchain_delegated(
        &self,
        onchain_wallet: &OnchainWallet,
    ) -> Result<(), JsError> {
        self.core
            .maintenance_with_onchain_delegated(onchain_wallet.inner())
            .await
            .map_err(bark_err)
    }

    // -- Address --------------------------------------------------------------

    #[wasm_bindgen(js_name = newAddress)]
    pub async fn new_address(&self) -> Result<String, JsError> {
        self.core.new_address().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = newAddressWithIndex)]
    pub async fn new_address_with_index(&self) -> Result<AddressWithIndex, JsError> {
        self.core.new_address_with_index().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = peekAddress)]
    pub async fn peek_address(&self, index: u32) -> Result<String, JsError> {
        self.core.peek_address(index).await.map_err(bark_err)
    }

    // -- Balance & VTXOs ------------------------------------------------------

    pub async fn balance(&self) -> Result<Balance, JsError> {
        self.core.balance().await.map_err(bark_err)
    }

    pub async fn vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.vtxos().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getVtxoById)]
    pub async fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<Vtxo, JsError> {
        self.core.get_vtxo_by_id(vtxo_id).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = spendableVtxos)]
    pub async fn spendable_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.spendable_vtxos().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = allVtxos)]
    pub async fn all_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.all_vtxos().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getExpiringVtxos)]
    pub async fn get_expiring_vtxos(&self, threshold_blocks: u32) -> Result<Vec<Vtxo>, JsError> {
        self.core.get_expiring_vtxos(threshold_blocks).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getVtxosToRefresh)]
    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.get_vtxos_to_refresh().await.map_err(bark_err)
    }

    // -- Offboarding ----------------------------------------------------------

    #[wasm_bindgen(js_name = offboardAll)]
    pub async fn offboard_all(&self, bitcoin_address: String) -> Result<OffboardResult, JsError> {
        self.core.offboard_all(bitcoin_address).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = offboardVtxos)]
    pub async fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, JsError> {
        self.core.offboard_vtxos(vtxo_ids, bitcoin_address).await.map_err(bark_err)
    }

    // -- Lightning send -------------------------------------------------------

    #[wasm_bindgen(js_name = payLightningInvoice)]
    pub async fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
    ) -> Result<LightningSend, JsError> {
        self.core.pay_lightning_invoice(invoice, amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = payLightningOffer)]
    pub async fn pay_lightning_offer(
        &self,
        offer: String,
        amount_sats: Option<u64>,
    ) -> Result<LightningSend, JsError> {
        self.core.pay_lightning_offer(offer, amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = checkLightningPayment)]
    pub async fn check_lightning_payment(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<Option<String>, JsError> {
        self.core.check_lightning_payment(payment_hash, wait).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingLightningSends)]
    pub async fn pending_lightning_sends(&self) -> Result<Vec<LightningSend>, JsError> {
        self.core.pending_lightning_sends().await.map_err(bark_err)
    }

    // -- Lightning receive ----------------------------------------------------

    #[wasm_bindgen(js_name = bolt11Invoice)]
    pub async fn bolt11_invoice(
        &self,
        amount_sats: u64,
        description: Option<String>,
    ) -> Result<LightningInvoice, JsError> {
        self.core.bolt11_invoice(amount_sats, description).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = tryClaimAllLightningReceives)]
    pub async fn try_claim_all_lightning_receives(
        &self,
        wait: bool,
    ) -> Result<Vec<LightningReceive>, JsError> {
        self.core.try_claim_all_lightning_receives(wait).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingLightningReceives)]
    pub async fn pending_lightning_receives(&self) -> Result<Vec<LightningReceive>, JsError> {
        self.core.pending_lightning_receives().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = claimableLightningReceiveBalanceSats)]
    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, JsError> {
        self.core.claimable_lightning_receive_balance_sats().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = lightningReceiveStatus)]
    pub async fn lightning_receive_status(
        &self,
        payment_hash: String,
    ) -> Result<Option<LightningReceive>, JsError> {
        self.core.lightning_receive_status(payment_hash).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = tryClaimLightningReceive)]
    pub async fn try_claim_lightning_receive(
        &self,
        payment_hash: String,
        wait: bool,
    ) -> Result<(), JsError> {
        self.core.try_claim_lightning_receive(payment_hash, wait).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = cancelLightningReceive)]
    pub async fn cancel_lightning_receive(&self, payment_hash: String) -> Result<(), JsError> {
        self.core.cancel_lightning_receive(payment_hash).await.map_err(bark_err)
    }

    // -- Arkoor ---------------------------------------------------------------

    #[wasm_bindgen(js_name = sendArkoorPayment)]
    pub async fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<String, JsError> {
        self.core.send_arkoor_payment(ark_address, amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = validateArkoorAddress)]
    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, JsError> {
        self.core.validate_arkoor_address(address).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = sendOnchain)]
    pub async fn send_onchain(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, JsError> {
        self.core.send_onchain(address, amount_sats).await.map_err(bark_err)
    }

    // -- History --------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<Movement>, JsError> {
        self.core.history().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = historyByPaymentMethod)]
    pub async fn history_by_payment_method(
        &self,
        payment_method_type: String,
        payment_method_value: String,
    ) -> Result<Vec<Movement>, JsError> {
        self.core
            .history_by_payment_method(payment_method_type, payment_method_value)
            .await
            .map_err(bark_err)
    }

    // -- Refresh --------------------------------------------------------------

    #[wasm_bindgen(js_name = refreshVtxos)]
    pub async fn refresh_vtxos(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<String>, JsError> {
        self.core.refresh_vtxos(vtxo_ids).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceRefresh)]
    pub async fn maintenance_refresh(&self) -> Result<Option<String>, JsError> {
        self.core.maintenance_refresh().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = refreshVtxosDelegated)]
    pub async fn refresh_vtxos_delegated(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<Option<RoundState>, JsError> {
        self.core.refresh_vtxos_delegated(vtxo_ids).await.map_err(bark_err)
    }

    // -- Info -----------------------------------------------------------------

    pub async fn properties(&self) -> Result<WalletProperties, JsError> {
        self.core.properties().await.map_err(bark_err)
    }

    pub fn fingerprint(&self) -> String {
        self.core.fingerprint()
    }

    pub async fn network(&self) -> Result<Network, JsError> {
        self.core.network().await.map_err(bark_err)
    }

    pub async fn config(&self) -> Config {
        self.core.config().await
    }

    #[wasm_bindgen(js_name = arkInfo)]
    pub async fn ark_info(&self) -> Option<ArkInfo> {
        self.core.ark_info().await
    }

    #[wasm_bindgen(js_name = nextRoundStartTime)]
    pub async fn next_round_start_time(&self) -> Result<u64, JsError> {
        self.core.next_round_start_time().await.map_err(bark_err)
    }

    // -- Boarding -------------------------------------------------------------

    #[wasm_bindgen(js_name = boardAmount)]
    pub async fn board_amount(
        &self,
        onchain_wallet: &OnchainWallet,
        amount_sats: u64,
    ) -> Result<PendingBoard, JsError> {
        self.core.board_amount(onchain_wallet.inner(), amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = boardAll)]
    pub async fn board_all(&self, onchain_wallet: &OnchainWallet) -> Result<PendingBoard, JsError> {
        self.core.board_all(onchain_wallet.inner()).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = syncPendingBoards)]
    pub async fn sync_pending_boards(&self) -> Result<(), JsError> {
        self.core.sync_pending_boards().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingBoards)]
    pub async fn pending_boards(&self) -> Result<Vec<PendingBoard>, JsError> {
        self.core.pending_boards().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingBoardVtxos)]
    pub async fn pending_board_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.pending_board_vtxos().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingRoundInputVtxos)]
    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.pending_round_input_vtxos().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingLightningSendVtxos)]
    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.pending_lightning_send_vtxos().await.map_err(bark_err)
    }

    // -- Exits ----------------------------------------------------------------

    #[wasm_bindgen(js_name = startExitForEntireWallet)]
    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), JsError> {
        self.core.start_exit_for_entire_wallet().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = syncExits)]
    pub async fn sync_exits(&self, onchain_wallet: &OnchainWallet) -> Result<(), JsError> {
        self.core.sync_exits(onchain_wallet.inner()).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = progressExits)]
    pub async fn progress_exits(
        &self,
        onchain_wallet: &OnchainWallet,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<Vec<ExitProgressStatus>, JsError> {
        self.core
            .progress_exits(onchain_wallet.inner(), fee_rate_sat_per_vb)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = startExitForVtxos)]
    pub async fn start_exit_for_vtxos(&self, vtxo_ids: Vec<String>) -> Result<(), JsError> {
        self.core.start_exit_for_vtxos(vtxo_ids).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = listClaimableExits)]
    pub async fn list_claimable_exits(&self) -> Result<Vec<ExitVtxo>, JsError> {
        self.core.list_claimable_exits().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getExitVtxos)]
    pub async fn get_exit_vtxos(&self) -> Result<Vec<ExitVtxo>, JsError> {
        self.core.get_exit_vtxos().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = hasPendingExits)]
    pub async fn has_pending_exits(&self) -> Result<bool, JsError> {
        self.core.has_pending_exits().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingExitsTotalSats)]
    pub async fn pending_exits_total_sats(&self) -> Result<u64, JsError> {
        self.core.pending_exits_total_sats().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = drainExits)]
    pub async fn drain_exits(
        &self,
        vtxo_ids: Vec<String>,
        address: String,
        fee_rate_sat_per_vb: Option<u64>,
    ) -> Result<ExitClaimTransaction, JsError> {
        self.core
            .drain_exits(vtxo_ids, address, fee_rate_sat_per_vb)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = allExitsClaimableAtHeight)]
    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, JsError> {
        self.core.all_exits_claimable_at_height().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getExitStatus)]
    pub async fn get_exit_status(
        &self,
        vtxo_id: String,
        include_history: bool,
        include_transactions: bool,
    ) -> Result<Option<ExitTransactionStatus>, JsError> {
        self.core
            .get_exit_status(vtxo_id, include_history, include_transactions)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = signExitClaimInputs)]
    pub async fn sign_exit_claim_inputs(&self, psbt_base64: String) -> Result<String, JsError> {
        self.core.sign_exit_claim_inputs(psbt_base64).await.map_err(bark_err)
    }

    // -- Rounds ---------------------------------------------------------------

    #[wasm_bindgen(js_name = pendingRoundStates)]
    pub async fn pending_round_states(&self) -> Result<Vec<RoundState>, JsError> {
        self.core.pending_round_states().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = cancelPendingRound)]
    pub async fn cancel_pending_round(&self, round_id: u32) -> Result<(), JsError> {
        self.core.cancel_pending_round(round_id).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = cancelAllPendingRounds)]
    pub async fn cancel_all_pending_rounds(&self) -> Result<(), JsError> {
        self.core.cancel_all_pending_rounds().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = progressPendingRounds)]
    pub async fn progress_pending_rounds(&self) -> Result<(), JsError> {
        self.core.progress_pending_rounds().await.map_err(bark_err)
    }

    // -- Server ---------------------------------------------------------------

    #[wasm_bindgen(js_name = refreshServer)]
    pub async fn refresh_server(&self) -> Result<(), JsError> {
        self.core.refresh_server().await.map_err(bark_err)
    }

    // -- VTXO Expiry & Refresh Scheduling ------------------------------------

    #[wasm_bindgen(js_name = getFirstExpiringVtxoBlockheight)]
    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, JsError> {
        self.core.get_first_expiring_vtxo_blockheight().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getNextRequiredRefreshBlockheight)]
    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, JsError> {
        self.core.get_next_required_refresh_blockheight().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maybeScheduleMaintenanceRefresh)]
    pub async fn maybe_schedule_maintenance_refresh(&self) -> Result<Option<u32>, JsError> {
        self.core.maybe_schedule_maintenance_refresh().await.map_err(bark_err)
    }

    // -- Broadcast ------------------------------------------------------------

    #[wasm_bindgen(js_name = broadcastTx)]
    pub async fn broadcast_tx(&self, tx_hex: String) -> Result<String, JsError> {
        self.core.broadcast_tx(tx_hex).await.map_err(bark_err)
    }

    // -- Mailbox --------------------------------------------------------------

    #[wasm_bindgen(js_name = mailboxIdentifier)]
    pub fn mailbox_identifier(&self) -> Result<String, JsError> {
        self.core.mailbox_identifier().map_err(bark_err)
    }

    #[wasm_bindgen(js_name = mailboxAuthorization)]
    pub fn mailbox_authorization(&self) -> Result<String, JsError> {
        self.core.mailbox_authorization().map_err(bark_err)
    }

    // -- VTXO Import ----------------------------------------------------------

    #[wasm_bindgen(js_name = importVtxo)]
    pub async fn import_vtxo(&self, vtxo_base64: String) -> Result<(), JsError> {
        self.core.import_vtxo(vtxo_base64).await.map_err(bark_err)
    }

    // -- Fee Estimation -------------------------------------------------------

    #[wasm_bindgen(js_name = estimateBoardFee)]
    pub async fn estimate_board_fee(&self, amount_sats: u64) -> Result<FeeEstimate, JsError> {
        self.core.estimate_board_fee(amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateOffboardFee)]
    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxo_ids: Vec<String>,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_offboard_fee(address, vtxo_ids).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateRefreshFee)]
    pub async fn estimate_refresh_fee(
        &self,
        vtxo_ids: Vec<String>,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_refresh_fee(vtxo_ids).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateLightningSendFee)]
    pub async fn estimate_lightning_send_fee(
        &self,
        amount_sats: u64,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_lightning_send_fee(amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateLightningReceiveFee)]
    pub async fn estimate_lightning_receive_fee(
        &self,
        amount_sats: u64,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_lightning_receive_fee(amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateArkoorPaymentFee)]
    pub async fn estimate_arkoor_payment_fee(
        &self,
        amount_sats: u64,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_arkoor_payment_fee(amount_sats).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateOffboardAllFee)]
    pub async fn estimate_offboard_all_fee(&self, address: String) -> Result<FeeEstimate, JsError> {
        self.core.estimate_offboard_all_fee(address).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateSendOnchainFee)]
    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_send_onchain_fee(address, amount_sats).await.map_err(bark_err)
    }

    // -- Notifications --------------------------------------------------------

    pub fn notifications(&self) -> NotificationHolder {
        NotificationHolder::new(&self.core.inner())
    }
}
