#![allow(non_snake_case)]

use std::sync::Arc;

use serde::{Deserialize, Serialize};
use tsify::Tsify;
use tsify::Ts;
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
    pub async fn default(args: Ts<OnchainWalletDefaultArgs>) -> Result<OnchainWallet, JsError> {
        let args = args.to_rust()?;
        let db = indexed_db_client(&args.db_name).await.map_err(bark_err)?;
        let core = CoreOnchainWallet::default(args.network, args.mnemonic, args.config, db)
            .await
            .map_err(bark_err)?;
        Ok(Self { inner: Arc::new(core) })
    }

    pub async fn sync(&self) -> Result<f64, JsError> {
        self.inner.sync().await.map(|v| v as f64).map_err(bark_err)
    }

    /// Discover the wallet's pre-existing on-chain history. Run once after
    /// restoring a wallet from a mnemonic: `sync` only covers addresses this
    /// wallet instance has already revealed, so it never finds transactions
    /// made by a previous incarnation. Gap-limited full scan on esplora
    /// (`birthdayHeight` is ignored there), block scan from `birthdayHeight`
    /// on bitcoind. Returns the total balance in sats afterwards.
    #[wasm_bindgen(js_name = initialScan)]
    pub async fn initial_scan(&self, birthdayHeight: Option<u32>) -> Result<f64, JsError> {
        self.inner
            .initial_scan(birthdayHeight)
            .await
            .map(|v| v as f64)
            .map_err(bark_err)
    }

    pub async fn balance(&self) -> Result<Ts<OnchainBalance>, JsError> {
        Ok(self.inner.balance().await.map_err(bark_err)?.into_ts()?)
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

    /// Mark a wallet-known transaction as evicted from the mempool, so its
    /// inputs return to coin selection immediately. Only for a tx that has
    /// definitively been superseded on-chain (e.g. an RBF-replaced exit CPFP);
    /// evicting a still-in-flight tx invites a self-inflicted double-spend.
    #[wasm_bindgen(js_name = evictTx)]
    pub async fn evict_tx(&self, txid: String) -> Result<(), JsError> {
        self.inner.evict_tx(txid).await.map_err(bark_err)
    }

    /// Current chain tip height from the wallet's chain source.
    #[wasm_bindgen(js_name = tipHeight)]
    pub async fn tip_height(&self) -> Result<u32, JsError> {
        self.inner.tip_height().await.map_err(bark_err)
    }

    /// Cached network fee-rate estimates from the wallet's chain source.
    #[wasm_bindgen(js_name = feeRates)]
    pub async fn fee_rates(&self) -> Result<Ts<crate::types::FeeRates>, JsError> {
        Ok(self.inner.fee_rates().await.map_err(bark_err)?.into_ts()?)
    }

    /// Every wallet transaction with fee, balance change, confirmation and
    /// CPFP flag. Requires a prior `sync` to be meaningful.
    pub async fn transactions(&self) -> Result<Vec<Ts<crate::types::WalletTransaction>>, JsError> {
        Ok(self.inner.transactions().await.map_err(bark_err)?
            .into_iter().map(|v| v.into_ts()).collect::<Result<Vec<_>, _>>()?)
    }

    /// The wallet's unspent outputs. Requires a prior `sync` to be meaningful.
    pub async fn utxos(&self) -> Result<Vec<Ts<crate::types::OnchainUtxo>>, JsError> {
        Ok(self.inner.utxos().await.map_err(bark_err)?
            .into_iter().map(|v| v.into_ts()).collect::<Result<Vec<_>, _>>()?)
    }
}
