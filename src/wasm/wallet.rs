#![allow(non_snake_case)]

use std::sync::Arc;
use std::time::Duration;

use bark::onchain::OnchainWalletTrait;
use bark::{Wallet as InnerWallet};
use log::{info, warn};
use serde::{Deserialize, Serialize};
use tokio_util::sync::CancellationToken;
use tsify::Tsify;
use wasm_bindgen::prelude::*;

use crate::config::Config;
use crate::core::onchain::OnchainWallet as CoreOnchainWallet;
use crate::core::wallet::{seed_from_str, OpenArgs as CoreOpenArgs, Wallet as CoreWallet};
use crate::error::Error;
use crate::types::{
    AddressWithIndex, ArkInfo, Balance, ExitClaimTransaction, ExitProgressStatus,
    ExitTransactionStatus, ExitVtxo, FeeEstimate, LightningInvoice, LightningReceive,
    LightningSend, LightningSendStatus, Movement, Network, OffboardResult, PendingBoard,
    RecoveryReport, RoundState, Vtxo, WalletProperties,
};
use crate::wasm::db::indexed_db_client;
use crate::wasm::notification::NotificationHolder;
use crate::wasm::onchain::OnchainWallet;

fn js_err(e: impl Into<Error>) -> JsError {
    JsError::new(&e.into().message())
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct PayLightningInvoiceArgs {
    pub invoice: String,
    #[tsify(optional)]
    pub amountSats: Option<u64>,
    #[tsify(optional)]
    pub wait: Option<bool>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct PayLightningOfferArgs {
    pub offer: String,
    #[tsify(optional)]
    pub amountSats: Option<u64>,
    #[tsify(optional)]
    pub wait: Option<bool>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct PayLightningAddressArgs {
    pub lightningAddress: String,
    pub amountSats: u64,
    #[tsify(optional)]
    pub comment: Option<String>,
    #[tsify(optional)]
    pub wait: Option<bool>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct PayLnurlArgs {
    pub lnurl: String,
    pub amountSats: u64,
    #[tsify(optional)]
    pub comment: Option<String>,
    #[tsify(optional)]
    pub wait: Option<bool>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct Bolt11InvoiceArgs {
    pub amountSats: u64,
    #[tsify(optional)]
    pub description: Option<String>,
    #[tsify(optional)]
    pub token: Option<String>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct Bolt11InvoiceForAddressArgs {
    pub amountSats: u64,
    /// Ark address the claimed VTXO is delivered to.
    pub claimDestination: String,
    #[tsify(optional)]
    pub description: Option<String>,
    #[tsify(optional)]
    pub token: Option<String>,
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
    #[tsify(optional)]
    pub wait: Option<bool>,
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
    #[tsify(optional)]
    pub wait: Option<bool>,
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct TryClaimAllLightningReceivesArgs {
    #[tsify(optional)]
    pub wait: Option<bool>,
}

/// Optional arguments for [`Wallet::open`]
///
/// Every field has a default, so callers only set what they need.
#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct OpenWalletArgs {
    /// Whether to run the background daemon
    ///
    /// When disabled, you must manually call `Wallet::sync` to sync the wallet.
    ///
    /// Default: true
    #[tsify(optional)]
    #[serde(default = "default_true")]
    pub run_daemon: bool,

    /// Optional name for IndexedDb
    ///
    /// Default: name based on wallet fingerprint
    #[tsify(optional)]
    #[serde(default)]
    pub indexed_db_name: Option<String>,

    /// Whether to create a new wallet if no wallet exists
    ///
    ///  Default: true
    #[tsify(optional)]
    #[serde(default = "default_true")]
    pub create_if_not_exists: bool,

    /// Whether to create a new wallet even if the Ark server cannot be reached
    ///
    /// Default: false
    #[tsify(optional)]
    #[serde(default)]
    pub create_without_server: bool,

    /// Whether to skip the seed-recovery mailbox scan
    ///
    /// The scan runs on the open that creates the wallet locally and makes
    /// network calls; its result is available from `recoveryReport()`. Set this
    /// to open without it.
    ///
    /// Default: false
    #[tsify(optional)]
    #[serde(default)]
    pub skip_recovery: bool,
}

fn default_true() -> bool { true }

#[wasm_bindgen]
pub struct Wallet {
    core: CoreWallet,
    /// The onchain wallet supplied at open time, if any. Kept so JS can
    /// recover a usable handle via [`Wallet::onchain_wallet`] after `open`
    /// consumed the one it was given.
    onchain: Option<Arc<CoreOnchainWallet>>,
    #[allow(dead_code)]
    mailbox_cancel: CancellationToken,
}

impl Wallet {
    fn wrap(core: CoreWallet, onchain: Option<Arc<CoreOnchainWallet>>) -> Self {
        let inner = core.inner().clone();
        let cancel = CancellationToken::new();
        Self::start_mailbox_processor(inner, cancel.clone());
        Self {
            core,
            onchain,
            mailbox_cancel: cancel,
        }
    }

    async fn open_impl(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        onchain: Option<Arc<CoreOnchainWallet>>,
        args: OpenWalletArgs,
    ) -> Result<Wallet, JsError> {
        let btc_network = network.into();
        let seed = seed_from_str(btc_network, &mnemonic_or_seed)?;
        let db = if let Some(db) = args.indexed_db_name {
            indexed_db_client(&db).await?
        } else {
            bark::persist::platform_default(Option::<&str>::None, Some(seed.fingerprint())).await
                .map_err(js_err)?
        };
        let core = CoreWallet::open(network, mnemonic_or_seed, config, CoreOpenArgs {
            run_daemon: args.run_daemon,
            persister: Some(db),
            onchain: onchain.as_ref().map(|w| {
                w.inner() as Arc::<tokio::sync::RwLock<dyn OnchainWalletTrait>>
            }),
            create_if_not_exists: args.create_if_not_exists,
            create_without_server: args.create_without_server,
            skip_recovery: args.skip_recovery,
        }).await?;
        Ok(Self::wrap(core, onchain))
    }

    fn start_mailbox_processor(inner: InnerWallet, cancel: CancellationToken) {
        wasm_bindgen_futures::spawn_local(async move {
            let mut retry_delay: u64 = 1;

            loop {
                match inner
                    .subscribe_process_mailbox_messages(None, cancel.clone())
                    .await
                {
                    Ok(_) => {
                        info!("[MAILBOX] stream ended, restarting...");
                        retry_delay = 1;
                    }
                    Err(e) => {
                        if cancel.is_cancelled() {
                            info!("[MAILBOX] shutting down");
                            return;
                        }
                        warn!("[MAILBOX] error: {:?}, retrying in {}s", e, retry_delay);
                        tokio::select! {
                            _ = cancel.cancelled() => {
                                info!("[MAILBOX] shutting down");
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
                        info!("[MAILBOX] shutting down");
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

    /// Open a wallet, mirroring [`bark::Wallet::open`]: a single entry point
    /// with everything optional. Set `createIfNotExists` to create the wallet
    /// if it doesn't exist yet (replacing the old `create` constructor).
    ///
    /// The onchain wallet is supplied here at open time; onchain operations
    /// (boarding, exits, ...) use it internally and no longer take it per-call.
    ///
    /// NOTE: passing `onchain` here CONSUMES the JS handle (wasm-bindgen moves
    /// exported types passed by value): after this call its methods throw
    /// `null pointer passed to rust`. Prefer `openWithOnchain`, which borrows
    /// the handle and leaves it usable, or recover a fresh handle with
    /// `onchainWallet()` after opening.
    pub async fn open(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        onchain: Option<OnchainWallet>,
        args: OpenWalletArgs,
    ) -> Result<Wallet, JsError> {
        Self::open_impl(network, mnemonic_or_seed, config, onchain.map(|w| w.inner), args).await
    }

    /// Like [`Wallet::open`], but borrows the onchain wallet handle instead of
    /// consuming it: the same `OnchainWallet` instance stays valid for
    /// `balance()` / `newAddress()` / `send()` / `sync()`, and it and the
    /// wallet share one underlying bdk wallet (no persister divergence).
    ///
    /// Both handles should still be `free()`d on teardown; each drop only
    /// releases its own reference.
    #[wasm_bindgen(js_name = openWithOnchain)]
    pub async fn open_with_onchain(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        onchain: &OnchainWallet,
        args: OpenWalletArgs,
    ) -> Result<Wallet, JsError> {
        Self::open_impl(network, mnemonic_or_seed, config, Some(onchain.inner.clone()), args).await
    }

    /// A handle to the onchain wallet this wallet was opened with, or
    /// `undefined` if it was opened without one. The returned handle shares
    /// the underlying bdk wallet with this wallet and must be `free()`d by the
    /// caller when no longer needed.
    #[wasm_bindgen(js_name = onchainWallet)]
    pub fn onchain_wallet(&self) -> Option<OnchainWallet> {
        self.onchain.as_ref().map(|inner| OnchainWallet { inner: inner.clone() })
    }

    /// Low-level function to initialize a wallet
    ///
    /// You probably want to use [`Wallet::open`] instead.
    pub async fn create(
        network: Network,
        mnemonic_or_seed: String,
        config: Config,
        indexedDbName: Option<String>,
        createWithoutServer: bool,
    ) -> Result<(), JsError> {
        let btc_network = network.into();
        let seed = seed_from_str(btc_network, &mnemonic_or_seed)?;
        let db = if let Some(db) = indexedDbName {
            indexed_db_client(&db).await?
        } else {
            bark::persist::platform_default(Option::<&str>::None, Some(seed.fingerprint())).await
                .map_err(js_err)?
        };
        CoreWallet::create(
            network, mnemonic_or_seed, config, &*db, createWithoutServer,
        ).await?;
        Ok(())
    }

    // -- Sync & Maintenance ---------------------------------------------------

    pub async fn sync(&self) -> Result<(), JsError> {
        Ok(self.core.sync().await?)
    }

    /// Scan for VTXOs that were force-exited on-chain without the user asking
    /// and route them into the unilateral-exit flow so the funds can be claimed.
    /// This already runs automatically as part of `sync`.
    #[wasm_bindgen(js_name = syncForceExitedVtxos)]
    pub async fn sync_force_exited_vtxos(&self) -> Result<(), JsError> {
        Ok(self.core.sync_force_exited_vtxos().await?)
    }

    pub async fn maintenance(&self) -> Result<(), JsError> {
        Ok(self.core.maintenance().await?)
    }

    #[wasm_bindgen(js_name = maintenanceDelegated)]
    pub async fn maintenance_delegated(&self) -> Result<(), JsError> {
        Ok(self.core.maintenance_delegated().await?)
    }

    // -- Address --------------------------------------------------------------

    #[wasm_bindgen(js_name = newAddress)]
    pub async fn new_address(&self) -> Result<String, JsError> {
        Ok(self.core.new_address().await?)
    }

    #[wasm_bindgen(js_name = newAddressWithIndex)]
    pub async fn new_address_with_index(&self) -> Result<AddressWithIndex, JsError> {
        Ok(self.core.new_address_with_index().await?)
    }

    #[wasm_bindgen(js_name = peekAddress)]
    pub async fn peek_address(&self, index: u32) -> Result<String, JsError> {
        Ok(self.core.peek_address(index).await?)
    }

    // -- Balance & VTXOs ------------------------------------------------------

    pub async fn balance(&self) -> Result<Balance, JsError> {
        Ok(self.core.balance().await?)
    }

    pub async fn vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.vtxos().await?)
    }

    #[wasm_bindgen(js_name = getVtxoById)]
    pub async fn get_vtxo_by_id(&self, vtxoId: String) -> Result<Vtxo, JsError> {
        Ok(self.core.get_vtxo_by_id(vtxoId).await?)
    }

    #[wasm_bindgen(js_name = spendableVtxos)]
    pub async fn spendable_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.spendable_vtxos().await?)
    }

    #[wasm_bindgen(js_name = allVtxos)]
    pub async fn all_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.all_vtxos().await?)
    }

    #[wasm_bindgen(js_name = getExpiringVtxos)]
    pub async fn get_expiring_vtxos(&self, thresholdBlocks: u32) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.get_expiring_vtxos(thresholdBlocks).await?)
    }

    #[wasm_bindgen(js_name = getVtxosToRefresh)]
    pub async fn get_vtxos_to_refresh(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.get_vtxos_to_refresh().await?)
    }

    // -- Offboarding ----------------------------------------------------------

    #[wasm_bindgen(js_name = offboardAll)]
    pub async fn offboard_all(&self, bitcoinAddress: String) -> Result<OffboardResult, JsError> {
        Ok(self.core.offboard_all(bitcoinAddress).await?)
    }

    #[wasm_bindgen(js_name = offboardVtxos)]
    pub async fn offboard_vtxos(
        &self,
        vtxoIds: Vec<String>,
        bitcoinAddress: String,
    ) -> Result<OffboardResult, JsError> {
        Ok(self.core.offboard_vtxos(vtxoIds, bitcoinAddress).await?)
    }

    // -- Lightning send -------------------------------------------------------

    #[wasm_bindgen(js_name = payLightningInvoice)]
    pub async fn pay_lightning_invoice(
        &self,
        args: PayLightningInvoiceArgs,
    ) -> Result<LightningSendStatus, JsError> {
        Ok(self.core.pay_lightning_invoice(args.invoice, args.amountSats, args.wait.unwrap_or(false)).await?)
    }

    #[wasm_bindgen(js_name = payLightningOffer)]
    pub async fn pay_lightning_offer(
        &self,
        args: PayLightningOfferArgs,
    ) -> Result<LightningSendStatus, JsError> {
        Ok(self.core.pay_lightning_offer(args.offer, args.amountSats, args.wait.unwrap_or(false)).await?)
    }

    /// Pay to a Lightning Address (`user@domain`), resolved via LNURL-pay.
    ///
    /// The LNURL endpoint is fetched with the browser's `fetch`, so it must
    /// allow cross-origin requests (and the page's CSP `connect-src` must
    /// permit it).
    #[wasm_bindgen(js_name = payLightningAddress)]
    pub async fn pay_lightning_address(
        &self,
        args: PayLightningAddressArgs,
    ) -> Result<LightningSendStatus, JsError> {
        Ok(self
            .core
            .pay_lightning_address(
                args.lightningAddress,
                args.amountSats,
                args.comment,
                args.wait.unwrap_or(false),
            )
            .await?)
    }

    /// Pay a raw LNURL-pay link (`lnurl1…`). Errors if the link decodes to a
    /// non-pay LNURL (auth, withdraw, channel).
    ///
    /// Same cross-origin caveat as `payLightningAddress`.
    #[wasm_bindgen(js_name = payLnurl)]
    pub async fn pay_lnurl(&self, args: PayLnurlArgs) -> Result<LightningSendStatus, JsError> {
        Ok(self
            .core
            .pay_lnurl(
                args.lnurl,
                args.amountSats,
                args.comment,
                args.wait.unwrap_or(false),
            )
            .await?)
    }

    #[wasm_bindgen(js_name = checkLightningPayment)]
    pub async fn check_lightning_payment(
        &self,
        args: CheckLightningPaymentArgs,
    ) -> Result<LightningSendStatus, JsError> {
        Ok(self.core.check_lightning_payment(args.paymentHash, args.wait.unwrap_or(false)).await?)
    }

    #[wasm_bindgen(js_name = lightningSendState)]
    pub async fn lightning_send_state(
        &self,
        paymentHash: String,
    ) -> Result<LightningSendStatus, JsError> {
        Ok(self.core.lightning_send_state(paymentHash).await?)
    }

    #[wasm_bindgen(js_name = isInvoicePaid)]
    pub async fn is_invoice_paid(&self, paymentHash: String) -> Result<bool, JsError> {
        Ok(self.core.is_invoice_paid(paymentHash).await?)
    }

    #[wasm_bindgen(js_name = pendingLightningSends)]
    pub async fn pending_lightning_sends(&self) -> Result<Vec<LightningSend>, JsError> {
        Ok(self.core.pending_lightning_sends().await?)
    }

    #[wasm_bindgen(js_name = stuckFailedLightningSends)]
    pub async fn stuck_failed_lightning_sends(&self) -> Result<Vec<LightningSend>, JsError> {
        Ok(self.core.stuck_failed_lightning_sends().await?)
    }

    #[wasm_bindgen(js_name = allowLightningSendToExit)]
    pub async fn allow_lightning_send_to_exit(
        &self,
        paymentHash: String,
    ) -> Result<(), JsError> {
        Ok(self.core.allow_lightning_send_to_exit(paymentHash).await?)
    }

    // -- Lightning receive ----------------------------------------------------

    #[wasm_bindgen(js_name = bolt11Invoice)]
    pub async fn bolt11_invoice(
        &self,
        args: Bolt11InvoiceArgs,
    ) -> Result<LightningInvoice, JsError> {
        Ok(self.core.bolt11_invoice(args.amountSats, args.description, args.token).await?)
    }

    /// Create an invoice whose claimed VTXO is delivered to `claimDestination`
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
    /// A `claimDestination` owned by this wallet is claimed locally instead of
    /// going through its mailbox.
    #[wasm_bindgen(js_name = bolt11InvoiceForAddress)]
    pub async fn bolt11_invoice_for_address(
        &self,
        args: Bolt11InvoiceForAddressArgs,
    ) -> Result<LightningInvoice, JsError> {
        Ok(self.core.bolt11_invoice_for_address(
            args.amountSats, args.claimDestination, args.description, args.token,
        ).await?)
    }

    #[wasm_bindgen(js_name = tryClaimAllLightningReceives)]
    pub async fn try_claim_all_lightning_receives(
        &self,
        args: TryClaimAllLightningReceivesArgs,
    ) -> Result<Vec<LightningReceive>, JsError> {
        Ok(self.core.try_claim_all_lightning_receives(args.wait.unwrap_or(false)).await?)
    }

    #[wasm_bindgen(js_name = pendingLightningReceives)]
    pub async fn pending_lightning_receives(&self) -> Result<Vec<LightningReceive>, JsError> {
        Ok(self.core.pending_lightning_receives().await?)
    }

    #[wasm_bindgen(js_name = claimableLightningReceiveBalanceSats)]
    pub async fn claimable_lightning_receive_balance_sats(&self) -> Result<f64, JsError> {
        Ok(self.core.claimable_lightning_receive_balance_sats().await? as f64)
    }

    /// Triage a payment hash: settled or in-progress. Errors if no lightning
    /// receive is known for this payment hash.
    #[wasm_bindgen(js_name = lightningReceiveState)]
    pub async fn lightning_receive_state(
        &self,
        paymentHash: String,
    ) -> Result<LightningReceive, JsError> {
        Ok(self.core.lightning_receive_state(paymentHash).await?)
    }

    #[wasm_bindgen(js_name = tryClaimLightningReceive)]
    pub async fn try_claim_lightning_receive(
        &self,
        args: TryClaimLightningReceiveArgs,
    ) -> Result<LightningReceive, JsError> {
        Ok(self.core.try_claim_lightning_receive(args.paymentHash, args.wait.unwrap_or(false)).await?)
    }

    #[wasm_bindgen(js_name = cancelLightningReceive)]
    pub async fn cancel_lightning_receive(&self, paymentHash: String) -> Result<(), JsError> {
        Ok(self.core.cancel_lightning_receive(paymentHash).await?)
    }

    #[wasm_bindgen(js_name = attemptLightningReceiveExit)]
    pub async fn attempt_lightning_receive_exit(
        &self,
        paymentHash: String,
    ) -> Result<(), JsError> {
        Ok(self.core.attempt_lightning_receive_exit(paymentHash).await?)
    }

    // -- Arkoor ---------------------------------------------------------------

    #[wasm_bindgen(js_name = sendArkoorPayment)]
    pub async fn send_arkoor_payment(
        &self,
        arkAddress: String,
        amountSats: f64,
    ) -> Result<(), JsError> {
        Ok(self.core.send_arkoor_payment(arkAddress, amountSats as u64).await?)
    }

    #[wasm_bindgen(js_name = validateArkoorAddress)]
    pub async fn validate_arkoor_address(&self, address: String) -> Result<bool, JsError> {
        Ok(self.core.validate_arkoor_address(address).await?)
    }

    #[wasm_bindgen(js_name = sendOnchain)]
    pub async fn send_onchain(&self, address: String, amountSats: f64) -> Result<String, JsError> {
        Ok(self.core.send_onchain(address, amountSats as u64).await?)
    }

    // -- History --------------------------------------------------------------

    pub async fn history(&self) -> Result<Vec<Movement>, JsError> {
        Ok(self.core.history().await?)
    }

    #[wasm_bindgen(js_name = historyByPaymentMethod)]
    pub async fn history_by_payment_method(
        &self,
        paymentMethodType: String,
        paymentMethodValue: String,
    ) -> Result<Vec<Movement>, JsError> {
        Ok(self.core.history_by_payment_method(paymentMethodType, paymentMethodValue).await?)
    }

    // -- Refresh --------------------------------------------------------------

    #[wasm_bindgen(js_name = refreshVtxos)]
    pub async fn refresh_vtxos(&self, vtxoIds: Vec<String>) -> Result<Option<String>, JsError> {
        Ok(self.core.refresh_vtxos(vtxoIds).await?)
    }

    #[wasm_bindgen(js_name = maintenanceRefresh)]
    pub async fn maintenance_refresh(&self) -> Result<Option<String>, JsError> {
        Ok(self.core.maintenance_refresh().await?)
    }

    #[wasm_bindgen(js_name = refreshVtxosDelegated)]
    pub async fn refresh_vtxos_delegated(
        &self,
        vtxoIds: Vec<String>,
    ) -> Result<Option<RoundState>, JsError> {
        Ok(self.core.refresh_vtxos_delegated(vtxoIds).await?)
    }

    /// Schedule a delegated refresh for `scheduledHeight` instead of the next
    /// round. The refresh fee is priced against the VTXO's remaining lifetime at
    /// that height, and the server charges less the closer a VTXO is to expiry,
    /// so scheduling further out never costs more than refreshing now.
    #[wasm_bindgen(js_name = refreshVtxosScheduled)]
    pub async fn refresh_vtxos_scheduled(
        &self,
        vtxoIds: Vec<String>,
        scheduledHeight: u32,
    ) -> Result<Option<RoundState>, JsError> {
        Ok(self.core.refresh_vtxos_scheduled(vtxoIds, scheduledHeight).await?)
    }

    // -- Recovery -------------------------------------------------------------

    /// Recover the given VTXO ids from the server, importing the ones this
    /// wallet owns that are still spendable. Use it to retry ids a previous scan
    /// reported as `failed`.
    #[wasm_bindgen(js_name = recoverVtxos)]
    pub async fn recover_vtxos(&self, vtxoIds: Vec<String>) -> Result<RecoveryReport, JsError> {
        Ok(self.core.recover_vtxos(vtxoIds).await?)
    }

    /// Result of the seed-recovery scan that ran during `open`, or `undefined`
    /// if no report was produced.
    ///
    /// Recovery only runs on the open that creates the wallet locally, and not
    /// at all when `skipRecovery` is set, so this is `undefined` on every
    /// subsequent open. It is also `undefined` when the scan itself failed
    /// outright — bark logs that and lets open succeed, so `undefined` does not
    /// prove no funds are missing. `isComplete === false` means funds may still
    /// be missing; retry the report's `failed` ids with `recoverVtxos`.
    #[wasm_bindgen(js_name = recoveryReport)]
    pub fn recovery_report(&self) -> Option<RecoveryReport> {
        self.core.recovery_report()
    }

    // -- Info -----------------------------------------------------------------

    pub async fn properties(&self) -> Result<WalletProperties, JsError> {
        Ok(self.core.properties().await?)
    }

    pub fn fingerprint(&self) -> String {
        self.core.fingerprint()
    }

    pub async fn network(&self) -> Result<Network, JsError> {
        Ok(self.core.network().await?)
    }

    pub fn config(&self) -> Config {
        self.core.config()
    }

    #[wasm_bindgen(js_name = arkInfo)]
    pub async fn ark_info(&self) -> Option<ArkInfo> {
        self.core.ark_info().await
    }

    #[wasm_bindgen(js_name = nextRoundStartTime)]
    pub async fn next_round_start_time(&self) -> Result<f64, JsError> {
        Ok(self.core.next_round_start_time().await? as f64)
    }

    // -- Boarding -------------------------------------------------------------

    #[wasm_bindgen(js_name = boardAmount)]
    pub async fn board_amount(&self, amountSats: f64) -> Result<PendingBoard, JsError> {
        Ok(self.core.board_amount(amountSats as u64).await?)
    }

    #[wasm_bindgen(js_name = boardAll)]
    pub async fn board_all(&self) -> Result<PendingBoard, JsError> {
        Ok(self.core.board_all().await?)
    }

    #[wasm_bindgen(js_name = syncPendingBoards)]
    pub async fn sync_pending_boards(&self) -> Result<(), JsError> {
        Ok(self.core.sync_pending_boards().await?)
    }

    #[wasm_bindgen(js_name = pendingBoards)]
    pub async fn pending_boards(&self) -> Result<Vec<PendingBoard>, JsError> {
        Ok(self.core.pending_boards().await?)
    }

    #[wasm_bindgen(js_name = pendingBoardVtxos)]
    pub async fn pending_board_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.pending_board_vtxos().await?)
    }

    #[wasm_bindgen(js_name = pendingRoundInputVtxos)]
    pub async fn pending_round_input_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.pending_round_input_vtxos().await?)
    }

    #[wasm_bindgen(js_name = pendingLightningSendVtxos)]
    pub async fn pending_lightning_send_vtxos(&self) -> Result<Vec<Vtxo>, JsError> {
        Ok(self.core.pending_lightning_send_vtxos().await?)
    }

    // -- Exits ----------------------------------------------------------------

    #[wasm_bindgen(js_name = startExitForEntireWallet)]
    pub async fn start_exit_for_entire_wallet(&self) -> Result<(), JsError> {
        Ok(self.core.start_exit_for_entire_wallet().await?)
    }

    #[wasm_bindgen(js_name = syncExits)]
    pub async fn sync_exits(&self) -> Result<(), JsError> {
        Ok(self.core.sync_exits().await?)
    }

    #[wasm_bindgen(js_name = progressExits)]
    pub async fn progress_exits(
        &self,
        args: ProgressExitsArgs,
    ) -> Result<Vec<ExitProgressStatus>, JsError> {
        Ok(self.core.progress_exits(args.feeRateSatPerVb).await?)
    }

    #[wasm_bindgen(js_name = startExitForVtxos)]
    pub async fn start_exit_for_vtxos(&self, vtxoIds: Vec<String>) -> Result<(), JsError> {
        Ok(self.core.start_exit_for_vtxos(vtxoIds).await?)
    }

    #[wasm_bindgen(js_name = listClaimableExits)]
    pub async fn list_claimable_exits(&self) -> Result<Vec<ExitVtxo>, JsError> {
        Ok(self.core.list_claimable_exits().await?)
    }

    #[wasm_bindgen(js_name = getExitVtxos)]
    pub async fn get_exit_vtxos(&self) -> Result<Vec<ExitVtxo>, JsError> {
        Ok(self.core.get_exit_vtxos().await?)
    }

    #[wasm_bindgen(js_name = hasPendingExits)]
    pub async fn has_pending_exits(&self) -> Result<bool, JsError> {
        Ok(self.core.has_pending_exits().await?)
    }

    #[wasm_bindgen(js_name = pendingExitsTotalSats)]
    pub async fn pending_exits_total_sats(&self) -> Result<f64, JsError> {
        Ok(self.core.pending_exits_total_sats().await? as f64)
    }

    #[wasm_bindgen(js_name = drainExits)]
    pub async fn drain_exits(&self, args: DrainExitsArgs) -> Result<ExitClaimTransaction, JsError> {
        Ok(self.core.drain_exits(args.vtxoIds, args.address, args.feeRateSatPerVb).await?)
    }

    #[wasm_bindgen(js_name = allExitsClaimableAtHeight)]
    pub async fn all_exits_claimable_at_height(&self) -> Result<Option<u32>, JsError> {
        Ok(self.core.all_exits_claimable_at_height().await?)
    }

    #[wasm_bindgen(js_name = getExitStatus)]
    pub async fn get_exit_status(
        &self,
        args: GetExitStatusArgs,
    ) -> Result<Option<ExitTransactionStatus>, JsError> {
        Ok(self.core.get_exit_status(args.vtxoId, args.includeHistory, args.includeTransactions).await?)
    }

    #[wasm_bindgen(js_name = signExitClaimInputs)]
    pub async fn sign_exit_claim_inputs(&self, psbtBase64: String) -> Result<String, JsError> {
        Ok(self.core.sign_exit_claim_inputs(psbtBase64).await?)
    }

    // -- Rounds ---------------------------------------------------------------

    #[wasm_bindgen(js_name = pendingRoundStates)]
    pub async fn pending_round_states(&self) -> Result<Vec<RoundState>, JsError> {
        Ok(self.core.pending_round_states().await?)
    }

    #[wasm_bindgen(js_name = cancelPendingRound)]
    pub async fn cancel_pending_round(&self, roundId: u32) -> Result<(), JsError> {
        Ok(self.core.cancel_pending_round(roundId).await?)
    }

    #[wasm_bindgen(js_name = cancelAllPendingRounds)]
    pub async fn cancel_all_pending_rounds(&self) -> Result<(), JsError> {
        Ok(self.core.cancel_all_pending_rounds().await?)
    }

    #[wasm_bindgen(js_name = progressPendingRounds)]
    pub async fn progress_pending_rounds(&self) -> Result<(), JsError> {
        Ok(self.core.progress_pending_rounds().await?)
    }

    // -- Server ---------------------------------------------------------------

    #[wasm_bindgen(js_name = refreshServer)]
    pub async fn refresh_server(&self) -> Result<(), JsError> {
        Ok(self.core.refresh_server().await?)
    }

    // -- VTXO Expiry & Refresh Scheduling ------------------------------------

    #[wasm_bindgen(js_name = getFirstExpiringVtxoBlockheight)]
    pub async fn get_first_expiring_vtxo_blockheight(&self) -> Result<Option<u32>, JsError> {
        Ok(self.core.get_first_expiring_vtxo_blockheight().await?)
    }

    #[wasm_bindgen(js_name = getNextRequiredRefreshBlockheight)]
    pub async fn get_next_required_refresh_blockheight(&self) -> Result<Option<u32>, JsError> {
        Ok(self.core.get_next_required_refresh_blockheight().await?)
    }

    // -- Broadcast ------------------------------------------------------------

    #[wasm_bindgen(js_name = broadcastTx)]
    pub async fn broadcast_tx(&self, txHex: String) -> Result<String, JsError> {
        Ok(self.core.broadcast_tx(txHex).await?)
    }

    // -- Mailbox --------------------------------------------------------------

    #[wasm_bindgen(js_name = mailboxIdentifier)]
    pub fn mailbox_identifier(&self) -> Result<String, JsError> {
        Ok(self.core.mailbox_identifier()?)
    }

    #[wasm_bindgen(js_name = mailboxAuthorization)]
    pub fn mailbox_authorization(&self) -> Result<String, JsError> {
        Ok(self.core.mailbox_authorization()?)
    }

    // -- VTXO Import / Export -------------------------------------------------

    /// Import a VTXO from its serialized form (hex or base64).
    #[wasm_bindgen(js_name = importVtxo)]
    pub async fn import_vtxo(&self, encodedVtxo: String) -> Result<(), JsError> {
        Ok(self.core.import_vtxo(encodedVtxo).await?)
    }

    /// Hex-encoded serialization of the full VTXO (genesis chain included),
    /// re-importable via `importVtxo`. Mirrors bark-rest `GET /vtxos/{id}/encoded`.
    #[wasm_bindgen(js_name = vtxoEncoded)]
    pub async fn vtxo_encoded(&self, vtxoId: String) -> Result<String, JsError> {
        Ok(self.core.vtxo_encoded(vtxoId).await?)
    }

    // -- Fee Estimation -------------------------------------------------------

    #[wasm_bindgen(js_name = estimateBoardFee)]
    pub async fn estimate_board_fee(&self, amountSats: f64) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_board_fee(amountSats as u64).await?)
    }

    #[wasm_bindgen(js_name = estimateOffboardFee)]
    pub async fn estimate_offboard_fee(
        &self,
        address: String,
        vtxoIds: Vec<String>,
    ) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_offboard_fee(address, vtxoIds).await?)
    }

    #[wasm_bindgen(js_name = estimateRefreshFee)]
    pub async fn estimate_refresh_fee(&self, vtxoIds: Vec<String>) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_refresh_fee(vtxoIds).await?)
    }

    #[wasm_bindgen(js_name = estimateLightningSendFee)]
    pub async fn estimate_lightning_send_fee(
        &self,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_lightning_send_fee(amountSats as u64).await?)
    }

    #[wasm_bindgen(js_name = estimateLightningReceiveFee)]
    pub async fn estimate_lightning_receive_fee(
        &self,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_lightning_receive_fee(amountSats as u64).await?)
    }

    #[wasm_bindgen(js_name = estimateArkoorPaymentFee)]
    pub async fn estimate_arkoor_payment_fee(
        &self,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_arkoor_payment_fee(amountSats as u64).await?)
    }

    #[wasm_bindgen(js_name = estimateOffboardAllFee)]
    pub async fn estimate_offboard_all_fee(&self, address: String) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_offboard_all_fee(address).await?)
    }

    #[wasm_bindgen(js_name = estimateSendOnchainFee)]
    pub async fn estimate_send_onchain_fee(
        &self,
        address: String,
        amountSats: f64,
    ) -> Result<FeeEstimate, JsError> {
        Ok(self.core.estimate_send_onchain_fee(address, amountSats as u64).await?)
    }

    // -- Notifications --------------------------------------------------------

    pub fn notifications(&self) -> NotificationHolder {
        NotificationHolder::new(self.core.inner())
    }
}
