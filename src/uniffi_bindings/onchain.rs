use std::sync::Arc;
use tokio::sync::RwLock;

use bark::onchain::OnchainWallet as BarkOnchainWallet;

use crate::config::Config;
use crate::core::onchain::OnchainWallet as CoreOnchainWallet;
use crate::error::BarkError;
use crate::types::OnchainBalance;
use crate::uniffi_bindings::custom_onchain_wallet::{
    CallbackWalletAdapter, CustomOnchainWalletCallbacks,
};
use crate::uniffi_bindings::db::get_or_open_db;
use crate::uniffi_bindings::runtime::run_async;

/// UniFFI-facing onchain wallet. Supports two backends:
/// - BDK (real onchain wallet via `bark::onchain::OnchainWallet`)
/// - Callback (foreign-language implementation)
#[derive(uniffi::Object)]
pub struct OnchainWallet {
    inner: OnchainWalletInner,
}

enum OnchainWalletInner {
    Bdk(Arc<CoreOnchainWallet>),
    Callback(Arc<RwLock<CallbackWalletAdapter>>),
}

#[uniffi::export(async_runtime = "tokio")]
impl OnchainWallet {
    /// BDK-backed wallet. Opens the shared sqlite cache.
    #[uniffi::constructor]
    pub async fn default(
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<Arc<Self>, BarkError> {
        run_async(async move {
            let db = get_or_open_db(&datadir)?;
            let core = CoreOnchainWallet::default(mnemonic, config, db).await?;
            Ok(Arc::new(Self { inner: OnchainWalletInner::Bdk(Arc::new(core)) }))
        })
        .await
    }

    /// Callback-backed wallet for foreign-language implementations.
    #[uniffi::constructor]
    pub fn custom(
        callbacks: Arc<dyn CustomOnchainWalletCallbacks>,
    ) -> Result<Arc<Self>, BarkError> {
        log::info!("[ONCHAIN] Creating callback-based onchain wallet");
        let adapter = CallbackWalletAdapter::new(callbacks);
        Ok(Arc::new(Self {
            inner: OnchainWalletInner::Callback(Arc::new(RwLock::new(adapter))),
        }))
    }

    pub async fn sync(&self) -> Result<u64, BarkError> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.sync().await }).await
            }
            OnchainWalletInner::Callback(_) => {
                log::info!("[ONCHAIN] Callback wallets manage their own sync");
                Ok(0)
            }
        }
    }

    pub async fn balance(&self) -> Result<OnchainBalance, BarkError> {
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

    pub async fn new_address(&self) -> Result<String, BarkError> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.new_address().await }).await
            }
            OnchainWalletInner::Callback(_) => Err(BarkError::Internal {
                error_message: "new_address() not supported for callback wallets".to_string(),
            }),
        }
    }

    pub async fn send(
        &self,
        address: String,
        amount_sats: u64,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, BarkError> {
        match &self.inner {
            OnchainWalletInner::Bdk(core) => {
                let core = core.clone();
                run_async(async move { core.send(address, amount_sats, fee_rate_sat_per_vb).await })
                    .await
            }
            OnchainWalletInner::Callback(_) => Err(BarkError::Internal {
                error_message: "send() not supported for callback wallets".to_string(),
            }),
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
}
