use std::path::PathBuf;
use std::sync::Arc;

use anyhow::Context;
use bark::{SqliteClient, Wallet as InnerWallet};
use bip39::Mnemonic;
use bitcoin::Network as BtcNetwork;
use lightning_invoice::Bolt11Invoice;
use lnurl::lightning_address::LightningAddress;

use crate::error::BarkError;
use crate::runtime::TOKIO_RT;
use crate::types::*;

/// The main Bark wallet interface
pub struct Wallet {
    inner: InnerWallet,
}

impl Wallet {
    /// Create a new Bark wallet
    pub fn create(
        mnemonic: String,
        config: Config,
        datadir: String,
        force_rescan: bool,
    ) -> Result<Self, BarkError> {
        let inner =
            TOKIO_RT.block_on(Self::create_async(mnemonic, config, datadir, force_rescan))?;
        Ok(Self { inner })
    }

    async fn create_async(
        mnemonic: String,
        config: Config,
        datadir: String,
        force_rescan: bool,
    ) -> Result<InnerWallet, BarkError> {
        let network: BtcNetwork = config.network.into();
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        let datadir = PathBuf::from(datadir);
        let db_path = datadir.join("bark.sqlite");

        let db = Arc::new(
            SqliteClient::open(&db_path)
                .with_context(|| format!("opening sqlite at {}", db_path.display()))?,
        );

        let inner = InnerWallet::create(&mnemonic, network, cfg, db, force_rescan)
            .await
            .map_err(BarkError::from)?;

        Ok(inner)
    }

    /// Open an existing Bark wallet
    pub fn open(mnemonic: String, config: Config, datadir: String) -> Result<Self, BarkError> {
        let inner = TOKIO_RT.block_on(Self::open_async(mnemonic, config, datadir))?;
        Ok(Self { inner })
    }

    async fn open_async(
        mnemonic: String,
        config: Config,
        datadir: String,
    ) -> Result<InnerWallet, BarkError> {
        let cfg: bark::Config = config.into();

        let mnemonic =
            Mnemonic::parse(mnemonic.trim()).map_err(|e| BarkError::InvalidMnemonic {
                error_message: e.to_string(),
            })?;

        let datadir = PathBuf::from(datadir);
        let db_path = datadir.join("bark.sqlite");

        let db = Arc::new(
            SqliteClient::open(&db_path)
                .with_context(|| format!("opening sqlite at {}", db_path.display()))?,
        );

        let inner = InnerWallet::open(&mnemonic, db, cfg)
            .await
            .map_err(BarkError::from)?;

        // Check if server connection was established
        if inner.ark_info().await.ok().flatten().is_some() {
            eprintln!("[OPEN] ✅ Server connection established");
        } else {
            eprintln!("[OPEN] ⚠️  WARNING: Server connection FAILED - Lightning and Ark operations will not work!");
        }

        Ok(inner)
    }

    // ------------------------------------------------------------------------
    // Wallet Properties
    // ------------------------------------------------------------------------

    /// Get read-only wallet properties
    pub fn properties(&self) -> Result<WalletProperties, BarkError> {
        Ok(self.inner.properties()?.into())
    }

    // ------------------------------------------------------------------------
    // Synchronization & Maintenance
    // ------------------------------------------------------------------------

    /// Lightweight sync with Ark server and blockchain
    pub fn sync(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            eprintln!("[SYNC] Starting sync...");
            self.inner.sync().await;
            eprintln!("[SYNC] Sync completed");

            // Log balance after sync
            if let Ok(balance) = self.inner.balance() {
                eprintln!(
                    "[SYNC] Balance after sync: spendable={}, pending_board={}",
                    balance.spendable.to_sat(),
                    balance.pending_board.to_sat()
                );
            }

            // Log VTXO count
            if let Ok(vtxos) = self.inner.vtxos() {
                eprintln!("[SYNC] VTXOs after sync: {} total", vtxos.len());
                for (i, vtxo) in vtxos.iter().enumerate().take(3) {
                    eprintln!(
                        "[SYNC]   VTXO {}: {} sats, state={:?}",
                        i,
                        vtxo.vtxo.amount().to_sat(),
                        vtxo.state.kind()
                    );
                }
            }

            Ok(())
        })
    }

    /// Full maintenance: sync + refresh VTXOs if necessary
    pub fn maintenance(&self) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.maintenance().await?;
            Ok(())
        })
    }

    // ------------------------------------------------------------------------
    // Address Generation
    // ------------------------------------------------------------------------

    /// Generate a new Ark address for receiving payments
    pub fn new_address(&self) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = self.inner.new_address().await?;
            Ok(addr.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Balance & VTXOs
    // ------------------------------------------------------------------------

    /// Get detailed wallet balance
    pub fn balance(&self) -> Result<Balance, BarkError> {
        Ok(self.inner.balance()?.into())
    }

    /// List all unspent VTXOs in the wallet
    pub fn vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        Ok(self.inner.vtxos()?.into_iter().map(Into::into).collect())
    }

    // ------------------------------------------------------------------------
    // Offboarding
    // ------------------------------------------------------------------------

    /// Offboard all spendable VTXOs to a Bitcoin address
    pub fn offboard_all(&self, bitcoin_address: String) -> Result<OffboardResult, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = bitcoin_address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let status = self.inner.offboard_all(addr).await?;

            // Convert RoundStatus to a displayable round ID
            let round_id = format!("{:?}", status);

            Ok(OffboardResult { round_id })
        })
    }
    // ------------------------------------------------------------------------
    // Lightning Payments (Send)
    // ------------------------------------------------------------------------

    /// Pay a BOLT11 Lightning invoice
    pub fn pay_lightning_invoice(
        &self,
        invoice: String,
        amount_sats: Option<u64>,
    ) -> Result<LightningPaymentResult, BarkError> {
        TOKIO_RT.block_on(async {
            let invoice: Bolt11Invoice =
                invoice.parse().map_err(|e| BarkError::InvalidInvoice {
                    error_message: format!("invalid invoice: {}", e),
                })?;

            let amount = amount_sats.map(bitcoin::Amount::from_sat);

            let preimage = self
                .inner
                .pay_lightning_invoice(invoice.clone(), amount)
                .await?;

            Ok(LightningPaymentResult {
                invoice: invoice.to_string(),
                preimage: preimage.to_string(),
            })
        })
    }

    /// Pay to a Lightning Address (LNURL)
    pub fn pay_lightning_address(
        &self,
        lightning_address: String,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<LightningPaymentResult, BarkError> {
        TOKIO_RT.block_on(async {
            let addr: LightningAddress =
                lightning_address
                    .parse()
                    .map_err(|e| BarkError::InvalidAddress {
                        error_message: format!("invalid lightning address: {}", e),
                    })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let (invoice, preimage) = self
                .inner
                .pay_lightning_address(&addr, amount, comment.as_deref())
                .await?;

            Ok(LightningPaymentResult {
                invoice: invoice.to_string(),
                preimage: preimage.to_string(),
            })
        })
    }

    // ------------------------------------------------------------------------
    // Lightning Payments (Receive)
    // ------------------------------------------------------------------------

    /// Create a BOLT11 invoice to receive Lightning payment
    pub fn bolt11_invoice(&self, amount_sats: u64) -> Result<LightningInvoice, BarkError> {
        TOKIO_RT.block_on(async {
            let amount = bitcoin::Amount::from_sat(amount_sats);
            let invoice = self.inner.bolt11_invoice(amount).await?;

            Ok(LightningInvoice {
                invoice: invoice.to_string(),
                amount_sats,
            })
        })
    }

    /// Try to claim all pending Lightning receives
    pub fn try_claim_all_lightning_receives(&self, wait: bool) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            self.inner.try_claim_all_lightning_receives(wait).await?;
            Ok(())
        })
    }

    // ------------------------------------------------------------------------
    // Arkoor Payments
    // ------------------------------------------------------------------------

    /// Send an out-of-round payment to an Ark address
    pub fn send_arkoor_payment(
        &self,
        ark_address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr: ark_lib::Address =
                ark_address.parse().map_err(|e| BarkError::InvalidAddress {
                    error_message: format!("invalid ark address: {}", e),
                })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            let vtxos = self.inner.send_arkoor_payment(&addr, amount).await?;
            Ok(vtxos
                .first()
                .ok_or_else(|| anyhow::anyhow!("Payment succeeded but returned no vtxos"))?
                .point()
                .txid
                .to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Extended Address Management
    // ------------------------------------------------------------------------

    /// Generate a new address and return it with its index
    pub fn new_address_with_index(&self) -> Result<AddressWithIndex, BarkError> {
        TOKIO_RT.block_on(async {
            let (addr, index) = self.inner.new_address_with_index().await?;
            Ok(AddressWithIndex {
                address: addr.to_string(),
                index,
            })
        })
    }

    /// Peek at an address at a specific index
    pub fn peak_address(&self, index: u32) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = self.inner.peak_address(index).await?;
            Ok(addr.to_string())
        })
    }

    // ------------------------------------------------------------------------
    // Movement History
    // ------------------------------------------------------------------------

    /// Get all wallet movements (transaction history)
    pub fn movements(&self) -> Result<Vec<Movement>, BarkError> {
        Ok(self
            .inner
            .movements()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    // ------------------------------------------------------------------------
    // Extended VTXO Queries
    // ------------------------------------------------------------------------

    /// Get a specific VTXO by ID
    pub fn get_vtxo_by_id(&self, vtxo_id: String) -> Result<Vtxo, BarkError> {
        let id = vtxo_id.parse().map_err(|e| BarkError::InvalidAddress {
            error_message: format!("invalid vtxo id: {}", e),
        })?;
        Ok(self.inner.get_vtxo_by_id(id)?.into())
    }

    /// Get all spendable VTXOs
    pub fn spendable_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        Ok(self
            .inner
            .spendable_vtxos()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get all VTXOs (including spent)
    pub fn all_vtxos(&self) -> Result<Vec<Vtxo>, BarkError> {
        Ok(self
            .inner
            .all_vtxos()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get VTXOs expiring within threshold blocks
    pub fn get_expiring_vtxos(&self, threshold_blocks: u32) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .get_expiring_vtxos(threshold_blocks)
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    /// Get VTXOs that should be refreshed
    pub fn get_vtxos_to_refresh(&self) -> Result<Vec<Vtxo>, BarkError> {
        TOKIO_RT.block_on(async {
            Ok(self
                .inner
                .get_vtxos_to_refresh()
                .await?
                .into_iter()
                .map(Into::into)
                .collect())
        })
    }

    // ------------------------------------------------------------------------
    // Extended Offboarding
    // ------------------------------------------------------------------------

    /// Offboard specific VTXOs to a Bitcoin address
    pub fn offboard_vtxos(
        &self,
        vtxo_ids: Vec<String>,
        bitcoin_address: String,
    ) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = bitcoin_address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();

            let status = self.inner.offboard_vtxos(ids?, addr).await?;
            Ok(format!("{:?}", status))
        })
    }

    // ------------------------------------------------------------------------
    // VTXO Refresh
    // ------------------------------------------------------------------------

    /// Refresh specific VTXOs
    pub fn refresh_vtxos(&self, vtxo_ids: Vec<String>) -> Result<Option<String>, BarkError> {
        TOKIO_RT.block_on(async {
            let ids: Result<Vec<_>, _> = vtxo_ids
                .iter()
                .map(|id| {
                    id.parse::<ark_lib::VtxoId>()
                        .map_err(|e| BarkError::InvalidAddress {
                            error_message: format!("invalid vtxo id: {}", e),
                        })
                })
                .collect();

            let result = self.inner.refresh_vtxos(ids?).await?;
            Ok(result.map(|s| format!("{:?}", s)))
        })
    }

    /// Perform maintenance refresh
    pub fn maintenance_refresh(&self) -> Result<Option<String>, BarkError> {
        TOKIO_RT.block_on(async {
            let result = self.inner.maintenance_refresh().await?;
            Ok(result.map(|s| format!("{:?}", s)))
        })
    }

    // ------------------------------------------------------------------------
    // Extended Lightning
    // ------------------------------------------------------------------------

    /// Get all pending lightning sends
    pub fn pending_lightning_sends(&self) -> Result<Vec<LightningSendStatus>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_sends()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get all pending lightning receives
    pub fn pending_lightning_receives(&self) -> Result<Vec<LightningReceiveStatus>, BarkError> {
        Ok(self
            .inner
            .pending_lightning_receives()?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    /// Get claimable lightning receive balance
    pub fn claimable_lightning_receive_balance_sats(&self) -> Result<u64, BarkError> {
        Ok(self.inner.claimable_lightning_receive_balance()?.to_sat())
    }

    // ------------------------------------------------------------------------
    // Onchain Payments
    // ------------------------------------------------------------------------

    /// Send an onchain payment during a round
    pub fn send_round_onchain_payment(
        &self,
        address: String,
        amount_sats: u64,
    ) -> Result<String, BarkError> {
        TOKIO_RT.block_on(async {
            let addr = address
                .parse::<bitcoin::Address<bitcoin::address::NetworkUnchecked>>()
                .map_err(|e| BarkError::InvalidAddress {
                    error_message: e.to_string(),
                })?
                .assume_checked();

            let amount = bitcoin::Amount::from_sat(amount_sats);
            let status = self.inner.send_round_onchain_payment(addr, amount).await?;

            Ok(format!("{:?}", status))
        })
    }

    // ------------------------------------------------------------------------
    // Info
    // ------------------------------------------------------------------------
    /// Get Ark server info
    pub fn ark_info(&self) -> Option<ArkInfo> {
        TOKIO_RT.block_on(async {
            match self.inner.ark_info().await {
                Ok(Some(info)) => Some((&info).into()),
                _ => None,
            }
        })
    }

    /// Get wallet config
    pub fn config(&self) -> Config {
        let cfg = self.inner.config();
        let props = self.inner.properties().unwrap();
        Config {
            server_address: cfg.server_address.clone(),
            esplora_address: cfg.esplora_address.clone(),
            bitcoind_address: cfg.bitcoind_address.clone(),
            bitcoind_cookiefile: cfg
                .bitcoind_cookiefile
                .as_ref()
                .map(|p| p.to_string_lossy().to_string()),
            bitcoind_user: cfg.bitcoind_user.clone(),
            bitcoind_pass: cfg.bitcoind_pass.clone(),
            network: props.network.into(),
            vtxo_refresh_expiry_threshold: Some(cfg.vtxo_refresh_expiry_threshold),
            vtxo_exit_margin: Some(cfg.vtxo_exit_margin),
            htlc_recv_claim_delta: Some(cfg.htlc_recv_claim_delta),
            fallback_fee_rate: cfg.fallback_fee_rate.map(|r| r.to_sat_per_kwu()),
            round_tx_required_confirmations: Some(cfg.round_tx_required_confirmations),
        }
    }
}
