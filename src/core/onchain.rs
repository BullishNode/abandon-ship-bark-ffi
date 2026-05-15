use std::sync::Arc;
use tokio::sync::RwLock;

use bark::chain::{ChainSource, ChainSourceSpec};
use bark::onchain::{ChainSync, OnchainWallet as BarkOnchainWallet};
use bark::persist::BarkPersister;
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;

use crate::config::Config;
use crate::error::BarkError;
use crate::types::OnchainBalance;

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
        mnemonic: String,
        config: Config,
        db: Arc<dyn BarkPersister>,
    ) -> Result<Self, BarkError> {
        let mnemonic = Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
            error_message: e.to_string(),
        })?;

        let seed = mnemonic.to_seed("");
        let btc_network: BtcNetwork = config.network.into();

        log::info!("[ONCHAIN] Creating onchain wallet for {:?} network", btc_network);

        let onchain = BarkOnchainWallet::load_or_create(btc_network, seed, db.clone()).await?;

        let chain_spec = if let Some(url) = config.bitcoind_address.as_ref() {
            use bark_bitcoin_ext::rpc::Auth;
            let auth = if let Some(cookie) = config.bitcoind_cookiefile {
                Auth::CookieFile(std::path::PathBuf::from(cookie))
            } else if let (Some(user), Some(pass)) = (config.bitcoind_user, config.bitcoind_pass) {
                Auth::UserPass(user, pass)
            } else {
                Auth::None
            };
            log::info!("[ONCHAIN] Using Bitcoin Core RPC at {}", url);
            ChainSourceSpec::Bitcoind { url: url.clone(), auth }
        } else if let Some(url) = config.esplora_address {
            log::info!("[ONCHAIN] Using Esplora at {}", url);
            ChainSourceSpec::Esplora { url }
        } else {
            return Err(BarkError::InvalidAddress {
                error_message: "Config must specify either esplora_address or bitcoind_address"
                    .to_string(),
            });
        };

        let chain = Arc::new(
            ChainSource::new(chain_spec, btc_network, None)
                .await
                .map_err(|e| BarkError::Network {
                    error_message: format!("Failed to create chain source: {}", e),
                })?,
        );

        Ok(Self {
            wallet: Arc::new(RwLock::new(onchain)),
            chain,
        })
    }

    pub async fn sync(&self) -> Result<u64, BarkError> {
        let mut w = self.wallet.write().await;
        w.sync(&self.chain).await.map_err(|e| BarkError::Network {
            error_message: format!("Sync failed: {}", e),
        })?;
        let balance = w.balance();
        Ok(balance.total().to_sat())
    }

    pub async fn balance(&self) -> Result<OnchainBalance, BarkError> {
        let w = self.wallet.write().await;
        Ok(w.balance().into())
    }

    pub async fn new_address(&self) -> Result<String, BarkError> {
        let mut w = self.wallet.write().await;
        let addr = w.address().await.map_err(|e| BarkError::Internal {
            error_message: format!("Failed to generate address: {}", e),
        })?;
        Ok(addr.to_string())
    }

    pub async fn send(
        &self,
        address: String,
        amount_sats: u64,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, BarkError> {
        let addr = address
            .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
            .map_err(|e| BarkError::InvalidAddress { error_message: e.to_string() })?
            .assume_checked();

        let amount = bitcoin::Amount::from_sat(amount_sats);

        let fee_rate = bitcoin::FeeRate::from_sat_per_vb(fee_rate_sat_per_vb)
            .ok_or_else(|| BarkError::Internal {
                error_message: "Invalid fee rate".to_string(),
            })?;

        let mut w = self.wallet.write().await;
        let txid = w.send(&self.chain, addr, amount, fee_rate).await.map_err(|e| BarkError::Internal {
            error_message: format!("Send failed: {}", e),
        })?;

        Ok(txid.to_string())
    }

    pub(crate) fn inner(&self) -> Arc<RwLock<BarkOnchainWallet>> {
        self.wallet.clone()
    }
}
