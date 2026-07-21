#![allow(non_snake_case)]

use std::sync::Arc;

use serde::{Deserialize, Serialize};
use tsify::Tsify;
use wasm_bindgen::prelude::*;

use crate::config::Config;
use crate::core::onchain::OnchainWallet as CoreOnchainWallet;
use crate::error::Error;
use crate::types::OnchainBalance;
use crate::wasm::db::indexed_db_client;
use crate::Network;

fn bark_err(e: Error) -> JsError {
    JsError::new(&e.message())
}

#[derive(Serialize, Deserialize, Tsify)]
#[tsify(from_wasm_abi, into_wasm_abi)]
#[serde(rename_all = "camelCase")]
pub struct OnchainWalletDefaultArgs {
    pub network: Network,
    pub mnemonic: String,
    pub config: Config,
    pub db_name: String,
}

#[wasm_bindgen]
pub struct OnchainWallet {
    pub(crate) inner: Arc<CoreOnchainWallet>,
}

#[wasm_bindgen]
impl OnchainWallet {
    /// Open (or create) the onchain wallet against an IndexedDB-backed persister.
    pub async fn default(args: OnchainWalletDefaultArgs) -> Result<OnchainWallet, JsError> {
        let db = indexed_db_client(&args.db_name).await.map_err(bark_err)?;
        let core = CoreOnchainWallet::default(args.network, args.mnemonic, args.config, db)
            .await
            .map_err(bark_err)?;
        Ok(Self { inner: Arc::new(core) })
    }

    pub async fn sync(&self) -> Result<f64, JsError> {
        self.inner.sync().await.map(|v| v as f64).map_err(bark_err)
    }

    pub async fn balance(&self) -> Result<OnchainBalance, JsError> {
        self.inner.balance().await.map_err(bark_err)
    }

    #[wasm_bindgen(js_name = newAddress)]
    pub async fn new_address(&self) -> Result<String, JsError> {
        self.inner.new_address().await.map_err(bark_err)
    }

    pub async fn send(
        &self,
        address: String,
        amountSats: f64,
        feeRateSatPerVb: f64,
    ) -> Result<String, JsError> {
        self.inner
            .send(address, amountSats as u64, feeRateSatPerVb as u64)
            .await
            .map_err(bark_err)
    }
}
