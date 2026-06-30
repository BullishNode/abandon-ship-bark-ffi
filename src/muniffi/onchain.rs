use std::sync::Arc;
use tokio::sync::RwLock;

use bark::onchain::{DaemonizableOnchainWallet, OnchainWallet as BarkOnchainWallet};
use log::info;

use crate::config::Config;
use crate::core::onchain::OnchainWallet as CoreOnchainWallet;
use crate::error::Error;
use crate::types::OnchainBalance;
use crate::muniffi::custom_onchain_wallet::{
    CallbackWalletAdapter, CustomOnchainWalletCallbacks,
};
use crate::muniffi::db::open_sqlite_db;
use crate::muniffi::runtime::run_async;
use crate::Network;

/// UniFFI-facing onchain wallet. Supports two backends:
/// - BDK (real onchain wallet via `bark::onchain::OnchainWallet`)
/// - Callback (foreign-language implementation)
#[derive(uniffi::Object)]
pub struct OnchainWallet {
    inner: OnchainWalletInner,
}

//TODO(stevenroose) try to un-Arc because wrapper is Arc
enum OnchainWalletInner {
    Bdk(Arc<CoreOnchainWallet>),
    Callback(Arc<RwLock<CallbackWalletAdapter>>),
}

#[uniffi::export(async_runtime = "tokio")]
impl OnchainWallet {
    /// BDK-backed wallet. Opens the shared sqlite cache.
    #[uniffi::constructor]
    pub async fn default(
        network: Network,
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<Arc<Self>, Error> {
        run_async(async move {
            let db = open_sqlite_db(&datadir)?;
            let core = CoreOnchainWallet::default(network, mnemonic, config, db).await?;
            Ok(Arc::new(Self { inner: OnchainWalletInner::Bdk(Arc::new(core)) }))
        })
        .await
    }

    /// Callback-backed wallet for foreign-language implementations.
    #[uniffi::constructor]
    pub fn custom(
        callbacks: Arc<dyn CustomOnchainWalletCallbacks>,
    ) -> Result<Arc<Self>, Error> {
        info!("[ONCHAIN] Creating callback-based onchain wallet");
        let adapter = CallbackWalletAdapter::new(callbacks);
        Ok(Arc::new(Self {
            inner: OnchainWalletInner::Callback(Arc::new(RwLock::new(adapter))),
        }))
    }

    pub async fn sync(&self) -> Result<u64, Error> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.sync().await }).await
            }
            OnchainWalletInner::Callback(_) => {
                info!("[ONCHAIN] Callback wallets manage their own sync");
                Ok(0)
            }
        }
    }

    pub async fn balance(&self) -> Result<OnchainBalance, Error> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.balance().await }).await
            }
            OnchainWalletInner::Callback(adapter) => {
                let adapter = adapter.clone();
                run_async(async move {
                    use bark::onchain::GetBalance;
                    let a = adapter.write().await;
                    let amount = a.get_balance();
                    Ok(OnchainBalance {
                        confirmed_sats: amount.to_sat(),
                        pending_sats: 0,
                        total_sats: amount.to_sat(),
                    })
                })
                .await
            }
        }
    }

    pub async fn new_address(&self) -> Result<String, Error> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.new_address().await }).await
            }
            OnchainWalletInner::Callback(_) => {
                Err("new_address() not supported for callback wallets".into())
            }
        }
    }

    pub async fn send(
        &self,
        address: String,
        amount_sats: u64,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, Error> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.send(address, amount_sats, fee_rate_sat_per_vb).await })
                    .await
            }
            OnchainWalletInner::Callback(_) => {
                Err("send() not supported for callback wallets".into())
            }
        }
    }
}

impl OnchainWallet {
    /// Returns the inner BDK wallet handle for use by `bark::Wallet` operations
    /// that require an `&mut OnchainWallet`. Used by daemon mode (which takes
    /// the handle directly) and the core-bypass callback dispatch in the
    /// Wallet wrapper.
    pub(crate) fn inner_bdk(&self) -> Option<Arc<RwLock<BarkOnchainWallet>>> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => Some(core.inner()),
            OnchainWalletInner::Callback(_) => None,
        }
    }

    /// Returns the `core::OnchainWallet` wrapper, for delegating to core
    /// `Wallet` methods that take `Arc<core::OnchainWallet>`.
    pub(crate) fn bdk_core(&self) -> Option<Arc<CoreOnchainWallet>> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => Some(core.clone()),
            OnchainWalletInner::Callback(_) => None,
        }
    }

    /// Returns the callback adapter handle for the Wallet wrapper's
    /// callback-onchain dispatch path.
    pub(crate) fn inner_callback(&self) -> Option<Arc<RwLock<CallbackWalletAdapter>>> {
        match &self.inner {
            OnchainWalletInner::Bdk(_) => None,
            OnchainWalletInner::Callback(adapter) => Some(adapter.clone()),
        }
    }

    pub(crate) fn inner_dyn(&self) -> Arc<RwLock<dyn DaemonizableOnchainWallet>> {
        match &self.inner {
            OnchainWalletInner::Bdk(v) => v.inner(),
            OnchainWalletInner::Callback(v) => v.clone(),
        }
    }
}
