use std::sync::Arc;
use tokio::sync::RwLock;

use bark::chain::{ChainSource, ChainSourceSpec};
use bark::onchain::{OnchainWalletTrait, OnchainWallet as BarkOnchainWallet};
use bark::persist::BarkPersister;
use bip39::Mnemonic;

use anyhow::Context;
use log::info;

use crate::config::Config;
use crate::error::Error;
use crate::types::{self, OnchainBalance};
use crate::Network;

/// BDK-based onchain Bitcoin wallet for boarding and exits.
///
/// Core type, shared between uniffi and wasm bindings. Holds only the
/// BDK case — callback-backed wallets are a uniffi-only concept layered
/// on top of the core inner `bark::Wallet`.
pub struct OnchainWallet {
    wallet: Arc<RwLock<BarkOnchainWallet>>,
    chain: Arc<ChainSource>,
}

impl OnchainWallet {
    pub async fn default(
        network: Network,
        mnemonic: String,
        config: Config,
        db: Arc<dyn BarkPersister>,
    ) -> Result<Self, Error> {
        let mnemonic = Mnemonic::parse(mnemonic.trim()).context("invalid mnemonic")?;

        let seed = mnemonic.to_seed("");
        let network = network.into();

        info!("[ONCHAIN] Creating onchain wallet for {:?} network", network);

        let onchain = BarkOnchainWallet::load_or_create(network, seed, db.clone()).await?;

        let chain_spec = if let Some(url) = config.bitcoind_address.as_ref() {
            use bark_bitcoin_ext::rpc::Auth;
            let auth = if let Some(cookie) = config.bitcoind_cookiefile {
                Auth::CookieFile(std::path::PathBuf::from(cookie))
            } else if let (Some(user), Some(pass)) = (config.bitcoind_user, config.bitcoind_pass) {
                Auth::UserPass(user, pass)
            } else {
                Auth::None
            };
            info!("[ONCHAIN] Using Bitcoin Core RPC at {}", url);
            ChainSourceSpec::Bitcoind { url: url.clone(), auth }
        } else if let Some(url) = config.esplora_address {
            info!("[ONCHAIN] Using Esplora at {}", url);
            ChainSourceSpec::Esplora { url }
        } else {
            return Err(anyhow::anyhow!(
                "Config must specify either esplora_address or bitcoind_address"
            )
            .into());
        };

        let chain = Arc::new(
            ChainSource::new(chain_spec, network, None)
                .await
                .context("Failed to create chain source")?,
        );

        Ok(Self {
            wallet: Arc::new(RwLock::new(onchain)),
            chain,
        })
    }

    pub async fn sync(&self) -> Result<u64, Error> {
        let mut w = self.wallet.write().await;
        w.sync(&self.chain).await.context("Sync failed")?;
        let balance = w.balance();
        Ok(balance.total().to_sat())
    }

    pub async fn balance(&self) -> Result<OnchainBalance, Error> {
        let w = self.wallet.write().await;
        Ok(w.balance().into())
    }

    pub async fn new_address(&self) -> Result<String, Error> {
        let mut w = self.wallet.write().await;
        let addr = w.address().await.context("Failed to generate address")?;
        Ok(addr.to_string())
    }

    pub async fn send(
        &self,
        address: String,
        amount_sats: u64,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, Error> {
        let addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .context("invalid address")?
            .assume_checked();

        let amount = bitcoin::Amount::from_sat(amount_sats);

        let fee_rate = bitcoin::FeeRate::from_sat_per_vb(fee_rate_sat_per_vb)
            .context("Invalid fee rate")?;

        let mut w = self.wallet.write().await;
        let txid = w.send(&self.chain, addr, amount, fee_rate).await.context("Send failed")?;

        Ok(txid.to_string())
    }

    /// Current chain tip height, from the wallet's chain source (cached
    /// upstream with a short TTL).
    pub async fn tip_height(&self) -> Result<u32, Error> {
        let height = self.chain.tip().await.context("Failed to fetch tip")?;
        Ok(height)
    }

    /// Cached network fee-rate estimates from the wallet's chain source.
    pub async fn fee_rates(&self) -> Result<types::FeeRates, Error> {
        Ok(self.chain.fee_rates().await.into())
    }

    /// Every wallet transaction with fee, balance change, confirmation and
    /// CPFP flag. Requires a prior `sync` to be meaningful.
    pub async fn transactions(&self) -> Result<Vec<types::WalletTransaction>, Error> {
        let w = self.wallet.read().await;
        let infos = w
            .list_transaction_infos()
            .context("Failed to list transactions")?;
        Ok(infos.iter().map(Into::into).collect())
    }

    /// The wallet's unspent outputs. Requires a prior `sync` to be meaningful.
    pub async fn utxos(&self) -> Result<Vec<types::OnchainUtxo>, Error> {
        let w = self.wallet.read().await;
        Ok(w.utxos().iter().map(Into::into).collect())
    }

    pub(crate) fn inner(&self) -> Arc<RwLock<BarkOnchainWallet>> {
        self.wallet.clone()
    }
}
