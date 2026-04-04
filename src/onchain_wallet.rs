use std::sync::Arc;
use tokio::sync::Mutex;

use bark::chain::{ChainSource, ChainSourceSpec};
use bark::onchain::{ChainSync, OnchainWallet as BarkOnchainWallet};
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;

use crate::custom_onchain_wallet::CallbackWalletAdapter;
use crate::error::BarkError;
use crate::runtime::run_async;
use crate::types::{Config, OnchainBalance};

/// Enum to support both BDK and callback-based wallets
#[derive(Clone)]
enum OnchainWalletInner {
    Bdk {
        wallet: Arc<Mutex<BarkOnchainWallet>>,
        chain: Arc<ChainSource>,
    },
    Callback {
        adapter: Arc<Mutex<CallbackWalletAdapter>>,
    },
}

/// BDK-based onchain Bitcoin wallet for boarding and exits
pub struct OnchainWallet {
    inner: OnchainWalletInner,
}

impl OnchainWallet {
    /// Create or load an onchain wallet using BDK
    ///
    /// # Arguments
    ///
    /// * `mnemonic` - BIP39 mnemonic phrase
    /// * `config` - Wallet configuration (includes network and chain source settings)
    /// * `datadir` - Directory for wallet data (shares database with Bark wallet)
    pub async fn default(
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<Self, BarkError> {
        run_async(async move {
            let mnemonic =
                Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                    error_message: e.to_string(),
                })?;

            let seed = mnemonic.to_seed("");
            let btc_network: BtcNetwork = config.network.into();

            // Use shared database cache
            let db = crate::db::get_or_open_db(&datadir)?;

            eprintln!(
                "[ONCHAIN] Creating onchain wallet for {:?} network",
                btc_network
            );

            // Create the onchain wallet
            let onchain = BarkOnchainWallet::load_or_create(btc_network, seed, db.clone()).await?;

            // Build ChainSource from config - prioritize same as Bark wallet
            let chain_spec = if let Some(url) = config.bitcoind_address.as_ref() {
                use bark_bitcoin_ext::rpc::Auth;
                let auth = if let Some(cookie) = config.bitcoind_cookiefile {
                    Auth::CookieFile(std::path::PathBuf::from(cookie))
                } else if let (Some(user), Some(pass)) =
                    (config.bitcoind_user, config.bitcoind_pass)
                {
                    Auth::UserPass(user, pass)
                } else {
                    Auth::None
                };
                eprintln!("[ONCHAIN] Using Bitcoin Core RPC at {}", url);
                ChainSourceSpec::Bitcoind {
                    url: url.clone(),
                    auth,
                }
            } else if let Some(url) = config.esplora_address {
                eprintln!("[ONCHAIN] Using Esplora at {}", url);
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

            eprintln!("[ONCHAIN] Onchain wallet created successfully");

            Ok(Self {
                inner: OnchainWalletInner::Bdk {
                    wallet: Arc::new(Mutex::new(onchain)),
                    chain,
                },
            })
        })
        .await
    }

    /// Create an onchain wallet from custom callbacks
    ///
    /// This allows using your own wallet implementation (e.g., from Dart/Swift/Kotlin)
    /// instead of the built-in BDK wallet.
    ///
    /// # Arguments
    ///
    /// * `callbacks` - Implementation of CustomOnchainWalletCallbacks trait
    pub fn custom(
        callbacks: Box<dyn crate::custom_onchain_wallet::CustomOnchainWalletCallbacks>,
    ) -> Result<Self, BarkError> {
        eprintln!("[ONCHAIN] Creating callback-based onchain wallet");

        let adapter = CallbackWalletAdapter::new(callbacks);

        Ok(Self {
            inner: OnchainWalletInner::Callback {
                adapter: std::sync::Arc::new(tokio::sync::Mutex::new(adapter)),
            },
        })
    }

    /// Sync the onchain wallet with the blockchain
    ///
    /// Returns the amount synced in satoshis
    pub async fn sync(&self) -> Result<u64, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            match inner {
                OnchainWalletInner::Bdk { wallet, chain } => {
                    eprintln!("[ONCHAIN] Starting BDK sync...");
                    let mut w = wallet.lock().await;
                    w.sync(&chain).await.map_err(|e| BarkError::Network {
                        error_message: format!("Sync failed: {}", e),
                    })?;
                    let balance = w.balance();
                    eprintln!(
                        "[ONCHAIN] BDK sync completed, balance: {} sats",
                        balance.total().to_sat()
                    );
                    Ok(balance.total().to_sat())
                }
                OnchainWalletInner::Callback { .. } => {
                    eprintln!("[ONCHAIN] Callback wallets manage their own sync");
                    Ok(0)
                }
            }
        })
        .await
    }

    /// Get the onchain wallet balance
    pub async fn balance(&self) -> Result<OnchainBalance, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            match inner {
                OnchainWalletInner::Bdk { wallet, .. } => {
                    let w = wallet.lock().await;
                    let balance = w.balance();
                    Ok(balance.into())
                }
                OnchainWalletInner::Callback { adapter } => {
                    use bark::onchain::GetBalance;
                    let a = adapter.lock().await;
                    let amount = a.get_balance();
                    Ok(OnchainBalance {
                        confirmed_sats: amount.to_sat(),
                        pending_sats: 0,
                        total_sats: amount.to_sat(),
                    })
                }
            }
        })
        .await
    }

    /// Generate a new Bitcoin address
    pub async fn new_address(&self) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            match inner {
                OnchainWalletInner::Bdk { wallet, .. } => {
                    let mut w = wallet.lock().await;
                    let addr = w.address().await.map_err(|e| BarkError::Internal {
                        error_message: format!("Failed to generate address: {}", e),
                    })?;
                    Ok(addr.to_string())
                }
                OnchainWalletInner::Callback { .. } => Err(BarkError::Internal {
                    error_message: "new_address() not supported for callback wallets".to_string(),
                }),
            }
        })
        .await
    }

    /// Send Bitcoin to an address
    ///
    /// # Arguments
    ///
    /// * `address` - Destination Bitcoin address
    /// * `amount_sats` - Amount to send in satoshis
    /// * `fee_rate_sat_per_vb` - Fee rate in sats per vbyte
    ///
    /// Returns the transaction ID
    pub async fn send(
        &self,
        address: String,
        amount_sats: u64,
        fee_rate_sat_per_vb: u64,
    ) -> Result<String, BarkError> {
        let inner = self.inner.clone();
        run_async(async move {
            match inner {
                OnchainWalletInner::Bdk { wallet, chain } => {
                    let mut w = wallet.lock().await;

                    let addr = address
                        .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: e.to_string(),
                        })?
                        .assume_checked();

                    let amount = bitcoin::Amount::from_sat(amount_sats);

                    let fee_rate = bitcoin::FeeRate::from_sat_per_vb(fee_rate_sat_per_vb)
                        .ok_or_else(|| BarkError::Internal {
                            error_message: "Invalid fee rate".to_string(),
                        })?;

                    eprintln!(
                        "[ONCHAIN] Sending {} sats to {} with fee rate {} sat/vB",
                        amount_sats, addr, fee_rate_sat_per_vb
                    );

                    let txid = w.send(&chain, addr, amount, fee_rate).await.map_err(|e| {
                        BarkError::Internal {
                            error_message: format!("Send failed: {}", e),
                        }
                    })?;

                    eprintln!("[ONCHAIN] Transaction broadcast: {}", txid);

                    Ok(txid.to_string())
                }
                OnchainWalletInner::Callback { .. } => Err(BarkError::Internal {
                    error_message: "send() not supported for callback wallets".to_string(),
                }),
            }
        })
        .await
    }

    /// Internal method to get mutable reference to BDK wallet for Wallet operations
    ///
    /// This allows the Bark wallet to access the onchain wallet for boarding and exits.
    /// Only works with BDK-based wallets.
    pub(crate) fn inner_bdk(&self) -> Option<&Mutex<BarkOnchainWallet>> {
        match &self.inner {
            OnchainWalletInner::Bdk { wallet, .. } => Some(wallet),
            OnchainWalletInner::Callback { .. } => None,
        }
    }

    /// Internal method to get mutable reference to callback adapter for Wallet operations
    ///
    /// This allows the Bark wallet to access the onchain wallet for boarding and exits.
    /// Only works with callback-based wallets.
    pub(crate) fn inner_callback(&self) -> Option<&Mutex<CallbackWalletAdapter>> {
        match &self.inner {
            OnchainWalletInner::Bdk { .. } => None,
            OnchainWalletInner::Callback { adapter } => Some(adapter),
        }
    }
}
