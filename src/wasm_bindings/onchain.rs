use std::sync::Arc;

use wasm_bindgen::prelude::*;

use crate::config::Config;
use crate::core::onchain::OnchainWallet as CoreOnchainWallet;
use crate::error::BarkError;
use crate::types::OnchainBalance;
use crate::wasm_bindings::db::indexed_db_client;

fn bark_err(e: BarkError) -> JsError {
    JsError::new(&e.message())
}

#[wasm_bindgen]
pub struct OnchainWallet {
    inner: Arc<CoreOnchainWallet>,
}

#[wasm_bindgen]
impl OnchainWallet {
    /// Open (or create) the onchain wallet against an IndexedDB-backed persister.
    pub async fn default(
        mnemonic: String,
        config: Config,
        db_name: String,
    ) -> Result<OnchainWallet, JsError> {
        let db = indexed_db_client(&db_name).await.map_err(bark_err)?;
        let core = CoreOnchainWallet::default(mnemonic, config, db).await.map_err(bark_err)?;
        Ok(Self { inner: Arc::new(core) })
    }

    pub async fn sync(&self) -> Result<u64, JsError> {
        self.inner.sync().await.map_err(bark_err)
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
        amount_sats: u64,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, JsError> {
        self.inner.send(address, amount_sats, fee_rate_sat_per_vb).await.map_err(bark_err)
    }
}

impl OnchainWallet {
    pub(crate) fn inner(&self) -> Arc<CoreOnchainWallet> {
        self.inner.clone()
    }
}
