#![allow(non_snake_case)]

use std::sync::Arc;
use std::time::Duration;

use bark::Wallet as InnerWallet;
use serde::{Deserialize, Serialize};
use tokio_util::sync::CancellationToken;
use tsify::Tsify;
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

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct PayLightningInvoiceArgs {
    pub invoice: String,
    #[tsify(optional)]
    pub amountSats: Option<u64>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct PayLightningOfferArgs {
    pub offer: String,
    #[tsify(optional)]
    pub amountSats: Option<u64>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct Bolt11InvoiceArgs {
    pub amountSats: u64,
    #[tsify(optional)]
    pub description: Option<String>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct ProgressExitsArgs {
    #[tsify(optional)]
    pub feeRateSatPerVb: Option<u64>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct DrainExitsArgs {
    pub vtxoIds: Vec<String>,
    pub address: String,
    #[tsify(optional)]
    pub feeRateSatPerVb: Option<u64>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct CheckLightningPaymentArgs {
    pub paymentHash: String,
    pub wait: bool,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct GetExitStatusArgs {
    pub vtxoId: String,
    pub includeHistory: bool,
    pub includeTransactions: bool,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct TryClaimLightningReceiveArgs {
    pub paymentHash: String,
    pub wait: bool,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct TryClaimAllLightningReceivesArgs {
    pub wait: bool,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct WalletCreateArgs {
    pub mnemonic: String,
    pub config: Config,
    pub dbName: String,
    pub forceRescan: bool,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct WalletOpenArgs {
    pub mnemonic: String,
    pub config: Config,
    pub dbName: String,
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

    pub async fn create(args: WalletCreateArgs) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&args.dbName).await.map_err(bark_err)?;
        let core = CoreWallet::create(args.mnemonic, args.config, db, args.forceRescan)
            .await
            .map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    pub async fn open(args: WalletOpenArgs) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&args.dbName).await.map_err(bark_err)?;
        let core = CoreWallet::open(args.mnemonic, args.config, db).await.map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    #[wasm_bindgen(js_name = createWithOnchain)]
    pub async fn create_with_onchain(
        onchainWallet: &OnchainWallet,
        args: WalletCreateArgs,
    ) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&args.dbName).await.map_err(bark_err)?;
        let onchain = onchainWallet.inner();
        let core = CoreWallet::create_with_onchain(
            args.mnemonic,
            args.config,
            db,
            onchain,
            args.forceRescan,
        )
        .await
        .map_err(bark_err)?;
        Ok(Self::wrap(core))
    }

    #[wasm_bindgen(js_name = openWithOnchain)]
    pub async fn open_with_onchain(
        onchainWallet: &OnchainWallet,
        args: WalletOpenArgs,
    ) -> Result<Wallet, JsError> {
        let db = indexed_db_client(&args.dbName).await.map_err(bark_err)?;
        let onchain = onchainWallet.inner();
        let core = CoreWallet::open_with_onchain(args.mnemonic, args.config, db, onchain)
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
        onchainWallet: &OnchainWallet,
    ) -> Result<(), JsError> {
        self.core.maintenance_with_onchain(onchainWallet.inner()).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceDelegated)]
    pub async fn maintenance_delegated(&self) -> Result<(), JsError> {
        self.core.maintenance_delegated().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceWithOnchainDelegated)]
    pub async fn maintenance_with_onchain_delegated(
        &self,
        onchainWallet: &OnchainWallet,
    ) -> Result<(), JsError> {
        self.core
            .maintenance_with_onchain_delegated(onchainWallet.inner())
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
    pub async fn get_vtxo_by_id(&self, vtxoId: String) -> Result<Vtxo, JsError> {
        self.core.get_vtxo_by_id(vtxoId).await.map_err(bark_err)
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
    pub async fn get_expiring_vtxos(&self, thresholdBlocks: u32) -> Result<Vec<Vtxo>, JsError> {
        self.core.get_expiring_vtxos(thresholdBlocks).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = getVtxosToRefresh)]
    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<Vtxo>, JsError> {
        self.core.get_vtxos_to_refresh().await.map_err(bark_err)
    }

    // -- Offboarding ----------------------------------------------------------

    #[wasm_bindgen(js_name = offboardAll)]
    pub async fn offboard_all(&self, bitcoinAddress: String) -> Result<OffboardResult, JsError> {
        self.core.offboard_all(bitcoinAddress).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = offboardVtxos)]
    pub async fn offboard_vtxos(
        &self,
        vtxoIds: Vec<String>,
        bitcoinAddress: String,
    ) -> Result<String, JsError> {
        self.core.offboard_vtxos(vtxoIds, bitcoinAddress).await.map_err(bark_err)
    }

    // -- Lightning send -------------------------------------------------------

    #[wasm_bindgen(js_name = payLightningInvoice)]
    pub async fn pay_lightning_invoice(
        &self,
        args: PayLightningInvoiceArgs,
    ) -> Result<LightningSend, JsError> {
        self.core
            .pay_lightning_invoice(args.invoice, args.amountSats)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = payLightningOffer)]
    pub async fn pay_lightning_offer(
        &self,
        args: PayLightningOfferArgs,
    ) -> Result<LightningSend, JsError> {
        self.core
            .pay_lightning_offer(args.offer, args.amountSats)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = checkLightningPayment)]
    pub async fn check_lightning_payment(
        &self,
        args: CheckLightningPaymentArgs,
    ) -> Result<Option<String>, JsError> {
        self.core
            .check_lightning_payment(args.paymentHash, args.wait)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingLightningSends)]
    pub async fn pending_lightning_sends(&self) -> Result<Vec<LightningSend>, JsError> {
        self.core.pending_lightning_sends().await.map_err(bark_err)
    }

    // -- Lightning receive ----------------------------------------------------

    #[wasm_bindgen(js_name = bolt11Invoice)]
    pub async fn bolt11_invoice(
        &self,
        args: Bolt11InvoiceArgs,
    ) -> Result<LightningInvoice, JsError> {
        self.core
            .bolt11_invoice(args.amountSats, args.description)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = tryClaimAllLightningReceives)]
    pub async fn try_claim_all_lightning_receives(
        &self,
        args: TryClaimAllLightningReceivesArgs,
    ) -> Result<Vec<LightningReceive>, JsError> {
        self.core
            .try_claim_all_lightning_receives(args.wait)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = pendingLightningReceives)]
    pub async fn pending_lightning_receives(&self) -> Result<Vec<LightningReceive>, JsError> {
        self.core.pending_lightning_receives().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = claimableLightningReceiveBalanceSats)]
    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<f64, JsError> {
        self.core
            .claimable_lightning_receive_balance_sats()
            .await
            .map(|v| v as f64)
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = lightningReceiveStatus)]
    pub async fn lightning_receive_status(
        &self,
        paymentHash: String,
    ) -> Result<Option<LightningReceive>, JsError> {
        self.core.lightning_receive_status(paymentHash).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = tryClaimLightningReceive)]
    pub async fn try_claim_lightning_receive(
        &self,
        args: TryClaimLightningReceiveArgs,
    ) -> Result<(), JsError> {
        self.core
            .try_claim_lightning_receive(args.paymentHash, args.wait)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = cancelLightningReceive)]
    pub async fn cancel_lightning_receive(&self, paymentHash: String) -> Result<(), JsError> {
        self.core.cancel_lightning_receive(paymentHash).await.map_err(bark_err)
    }

    // -- Arkoor ---------------------------------------------------------------

    #[wasm_bindgen(js_name = sendArkoorPayment)]
    pub async fn send_arkoor_payment(
        &self,
        arkAddress: String,
        amountSats: f64,
    ) -> Result<String, JsError> {
        self.core
            .send_arkoor_payment(arkAddress, amountSats as u64)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = validateArkoorAddress)]
    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, JsError> {
        self.core.validate_arkoor_address(address).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = sendOnchain)]
    pub async fn send_onchain(
        &self,
        address: String,
        amountSats: f64,
    ) -> Result<String, JsError> {
        self.core
            .send_onchain(address, amountSats as u64)
            .await
            .map_err(bark_err)
    }

    // -- History --------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<Movement>, JsError> {
        self.core.history().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = historyByPaymentMethod)]
    pub async fn history_by_payment_method(
        &self,
        paymentMethodType: String,
        paymentMethodValue: String,
    ) -> Result<Vec<Movement>, JsError> {
        self.core
            .history_by_payment_method(paymentMethodType, paymentMethodValue)
            .await
            .map_err(bark_err)
    }

    // -- Refresh --------------------------------------------------------------

    #[wasm_bindgen(js_name = refreshVtxos)]
    pub async fn refresh_vtxos(
        &self,
        vtxoIds: Vec<String>,
    ) -> Result<Option<String>, JsError> {
        self.core.refresh_vtxos(vtxoIds).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = maintenanceRefresh)]
    pub async fn maintenance_refresh(&self) -> Result<Option<String>, JsError> {
        self.core.maintenance_refresh().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = refreshVtxosDelegated)]
    pub async fn refresh_vtxos_delegated(
        &self,
        vtxoIds: Vec<String>,
    ) -> Result<Option<RoundState>, JsError> {
        self.core.refresh_vtxos_delegated(vtxoIds).await.map_err(bark_err)
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
    pub async fn next_round_start_time(&self) -> Result<f64, JsError> {
        self.core
            .next_round_start_time()
            .await
            .map(|v| v as f64)
            .map_err(bark_err)
    }

    // -- Boarding -------------------------------------------------------------

    #[wasm_bindgen(js_name = boardAmount)]
    pub async fn board_amount(
        &self,
        onchainWallet: &OnchainWallet,
        amountSats: f64,
    ) -> Result<PendingBoard, JsError> {
        self.core
            .board_amount(onchainWallet.inner(), amountSats as u64)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = boardAll)]
    pub async fn board_all(&self, onchainWallet: &OnchainWallet) -> Result<PendingBoard, JsError> {
        self.core.board_all(onchainWallet.inner()).await.map_err(bark_err)
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
    pub async fn sync_exits(&self, onchainWallet: &OnchainWallet) -> Result<(), JsError> {
        self.core.sync_exits(onchainWallet.inner()).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = progressExits)]
    pub async fn progress_exits(
        &self,
        onchainWallet: &OnchainWallet,
        args: ProgressExitsArgs,
    ) -> Result<Vec<ExitProgressStatus>, JsError> {
        self.core
            .progress_exits(onchainWallet.inner(), args.feeRateSatPerVb)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = startExitForVtxos)]
    pub async fn start_exit_for_vtxos(&self, vtxoIds: Vec<String>) -> Result<(), JsError> {
        self.core.start_exit_for_vtxos(vtxoIds).await.map_err(bark_err)
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
    pub async fn pending_exits_total_sats(&self) -> Result<f64, JsError> {
        self.core
            .pending_exits_total_sats()
            .await
            .map(|v| v as f64)
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = drainExits)]
    pub async fn drain_exits(
        &self,
        args: DrainExitsArgs,
    ) -> Result<ExitClaimTransaction, JsError> {
        self.core
            .drain_exits(args.vtxoIds, args.address, args.feeRateSatPerVb)
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
        args: GetExitStatusArgs,
    ) -> Result<Option<ExitTransactionStatus>, JsError> {
        self.core
            .get_exit_status(args.vtxoId, args.includeHistory, args.includeTransactions)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = signExitClaimInputs)]
    pub async fn sign_exit_claim_inputs(&self, psbtBase64: String) -> Result<String, JsError> {
        self.core.sign_exit_claim_inputs(psbtBase64).await.map_err(bark_err)
    }

    // -- Rounds ---------------------------------------------------------------

    #[wasm_bindgen(js_name = pendingRoundStates)]
    pub async fn pending_round_states(&self) -> Result<Vec<RoundState>, JsError> {
        self.core.pending_round_states().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = cancelPendingRound)]
    pub async fn cancel_pending_round(&self, roundId: u32) -> Result<(), JsError> {
        self.core.cancel_pending_round(roundId).await.map_err(bark_err)
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
    pub async fn broadcast_tx(&self, txHex: String) -> Result<String, JsError> {
        self.core.broadcast_tx(txHex).await.map_err(bark_err)
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
    pub async fn import_vtxo(&self, vtxoBase64: String) -> Result<(), JsError> {
        self.core.import_vtxo(vtxoBase64).await.map_err(bark_err)
    }

    // -- Fee Estimation -------------------------------------------------------

    #[wasm_bindgen(js_name = estimateBoardFee)]
    pub async fn estimate_board_fee(&self, amountSats: f64) -> Result<FeeEstimate, JsError> {
        self.core
            .estimate_board_fee(amountSats as u64)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateOffboardFee)]
    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxoIds: Vec<String>,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_offboard_fee(address, vtxoIds).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateRefreshFee)]
    pub async fn estimate_refresh_fee(
        &self,
        vtxoIds: Vec<String>,
    ) -> Result<FeeEstimate, JsError> {
        self.core.estimate_refresh_fee(vtxoIds).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateLightningSendFee)]
    pub async fn estimate_lightning_send_fee(
        &self,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        self.core
            .estimate_lightning_send_fee(amountSats as u64)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateLightningReceiveFee)]
    pub async fn estimate_lightning_receive_fee(
        &self,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        self.core
            .estimate_lightning_receive_fee(amountSats as u64)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateArkoorPaymentFee)]
    pub async fn estimate_arkoor_payment_fee(
        &self,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        self.core
            .estimate_arkoor_payment_fee(amountSats as u64)
            .await
            .map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateOffboardAllFee)]
    pub async fn estimate_offboard_all_fee(&self, address: String) -> Result<FeeEstimate, JsError> {
        self.core.estimate_offboard_all_fee(address).await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = estimateSendOnchainFee)]
    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        self.core
            .estimate_send_onchain_fee(address, amountSats as u64)
            .await
            .map_err(bark_err)
    }

    // -- Notifications --------------------------------------------------------

    pub fn notifications(&self) -> NotificationHolder {
        NotificationHolder::new(&self.core.inner())
    }
}
