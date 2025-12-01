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

        let mnemonic = Mnemonic::parse(mnemonic.trim())
            .map_err(|e| BarkError::InvalidMnemonic { message: e.to_string() })?;

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

        let mnemonic = Mnemonic::parse(mnemonic.trim())
            .map_err(|e| BarkError::InvalidMnemonic { message: e.to_string() })?;

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
                .map_err(|e| BarkError::InvalidAddress { message: e.to_string() })?
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
            let invoice: Bolt11Invoice = invoice
                .parse()
                .map_err(|e| BarkError::InvalidInvoice { message: format!("invalid invoice: {}", e) })?;

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
            let addr: LightningAddress = lightning_address.parse().map_err(|e| {
                BarkError::InvalidAddress { message: format!("invalid lightning address: {}", e) }
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
    ) -> Result<(), BarkError> {
        TOKIO_RT.block_on(async {
            let addr: ark_lib::Address = ark_address
                .parse()
                .map_err(|e| BarkError::InvalidAddress { message: format!("invalid ark address: {}", e) })?;

            let amount = bitcoin::Amount::from_sat(amount_sats);

            self.inner.send_arkoor_payment(&addr, amount).await?;
            Ok(())
        })
    }
}
