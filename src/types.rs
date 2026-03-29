use bark::persist::models::PendingBoard as BarkPendingBoard;
use bark::WalletVtxo as BarkWalletVtxo;
use bark::{Balance as BarkBalance, WalletProperties as BarkWalletProperties};
use bark_bitcoin_ext::AmountExt;
use bitcoin::Network as BtcNetwork;

// ============================================================================
// Network
// ============================================================================

#[derive(Clone, Copy, Debug)]
pub enum Network {
    Bitcoin,
    Testnet,
    Signet,
    Regtest,
}

impl From<Network> for BtcNetwork {
    fn from(n: Network) -> Self {
        match n {
            Network::Bitcoin => BtcNetwork::Bitcoin,
            Network::Testnet => BtcNetwork::Testnet,
            Network::Signet => BtcNetwork::Signet,
            Network::Regtest => BtcNetwork::Regtest,
        }
    }
}

impl From<BtcNetwork> for Network {
    fn from(n: BtcNetwork) -> Self {
        match n {
            BtcNetwork::Bitcoin => Network::Bitcoin,
            BtcNetwork::Testnet => Network::Testnet,
            BtcNetwork::Testnet4 => Network::Testnet, // Map Testnet4 to Testnet
            BtcNetwork::Signet => Network::Signet,
            BtcNetwork::Regtest => Network::Regtest,
        }
    }
}

// ============================================================================
// Config
// ============================================================================

#[derive(Clone, Debug)]
pub struct Config {
    pub server_address: String,
    pub esplora_address: Option<String>,
    pub bitcoind_address: Option<String>,
    pub bitcoind_cookiefile: Option<String>,
    pub bitcoind_user: Option<String>,
    pub bitcoind_pass: Option<String>,
    pub network: Network,
    pub vtxo_refresh_expiry_threshold: Option<u32>,
    pub vtxo_exit_margin: Option<u16>,
    pub htlc_recv_claim_delta: Option<u16>,
    pub fallback_fee_rate: Option<u64>,
    pub round_tx_required_confirmations: Option<u32>,
}

impl From<Config> for bark::Config {
    fn from(c: Config) -> Self {
        let network: BtcNetwork = c.network.into();
        let mut cfg = bark::Config::network_default(network);

        cfg.server_address = c.server_address;
        cfg.esplora_address = c.esplora_address;
        cfg.bitcoind_address = c.bitcoind_address;
        cfg.bitcoind_cookiefile = c.bitcoind_cookiefile.map(std::path::PathBuf::from);
        cfg.bitcoind_user = c.bitcoind_user;
        cfg.bitcoind_pass = c.bitcoind_pass;

        if let Some(threshold) = c.vtxo_refresh_expiry_threshold {
            cfg.vtxo_refresh_expiry_threshold = threshold;
        }
        if let Some(margin) = c.vtxo_exit_margin {
            cfg.vtxo_exit_margin = margin;
        }
        if let Some(delta) = c.htlc_recv_claim_delta {
            cfg.htlc_recv_claim_delta = delta;
        }
        if let Some(rate) = c.fallback_fee_rate {
            cfg.fallback_fee_rate = Some(bitcoin::FeeRate::from_sat_per_kwu(rate));
        }
        if let Some(confs) = c.round_tx_required_confirmations {
            cfg.round_tx_required_confirmations = confs;
        }

        cfg
    }
}

// ============================================================================
// WalletProperties
// ============================================================================

#[derive(Clone, Debug)]
pub struct WalletProperties {
    pub network: Network,
    pub fingerprint: String,
}

impl From<BarkWalletProperties> for WalletProperties {
    fn from(p: BarkWalletProperties) -> Self {
        Self {
            network: p.network.into(),
            fingerprint: p.fingerprint.to_string(),
        }
    }
}

// ============================================================================
// Balance
// ============================================================================

#[derive(Clone, Debug)]
pub struct Balance {
    pub spendable_sats: u64,
    pub pending_in_round_sats: u64,
    pub pending_exit_sats: u64,
    pub pending_lightning_send_sats: u64,
    pub claimable_lightning_receive_sats: u64,
    pub pending_board_sats: u64,
}

impl From<BarkBalance> for Balance {
    fn from(b: BarkBalance) -> Self {
        Self {
            spendable_sats: b.spendable.to_sat(),
            pending_in_round_sats: b.pending_in_round.to_sat(),
            pending_exit_sats: b.pending_exit.unwrap_or_default().to_sat(),
            pending_lightning_send_sats: b.pending_lightning_send.to_sat(),
            // Note: Bark's Balance only has claimable_lightning_receive field.
            // There is no separate "total pending receive" field in upstream.
            claimable_lightning_receive_sats: b.claimable_lightning_receive.to_sat(),
            pending_board_sats: b.pending_board.to_sat(),
        }
    }
}

// ============================================================================
// Vtxo
// ============================================================================

#[derive(Clone, Debug)]
pub struct Vtxo {
    pub id: String,
    pub amount_sats: u64,
    pub expiry_height: u32,
    pub kind: String,
    pub state: String,
}

impl From<BarkWalletVtxo> for Vtxo {
    fn from(v: BarkWalletVtxo) -> Self {
        Self {
            id: v.vtxo.id().to_string(),
            amount_sats: v.vtxo.amount().to_sat(),
            expiry_height: v.vtxo.expiry_height(),
            kind: format!("{:?}", v.vtxo.policy_type()),
            state: format!("{:?}", v.state.kind()),
        }
    }
}

// ============================================================================
// LightningInvoice
// ============================================================================

#[derive(Clone, Debug)]
pub struct LightningInvoice {
    pub invoice: String,
    pub amount_sats: u64,
}

// ============================================================================
// OffboardResult
// ============================================================================

#[derive(Clone, Debug)]
pub struct OffboardResult {
    pub round_id: String,
}

// ============================================================================
// AddressWithIndex
// ============================================================================

#[derive(Clone, Debug)]
pub struct AddressWithIndex {
    pub address: String,
    pub index: u32,
}

// ============================================================================
// LightningReceive
// ============================================================================

#[derive(Clone, Debug)]
pub struct LightningReceive {
    pub payment_hash: String,
    pub invoice: String,
    pub amount_sats: u64,
    pub has_htlc_vtxos: bool,
    pub preimage_revealed: bool,
}

impl From<bark::persist::models::LightningReceive> for LightningReceive {
    fn from(r: bark::persist::models::LightningReceive) -> Self {
        use bitcoin::hex::DisplayHex;
        Self {
            payment_hash: r.payment_hash.as_hex().to_string(),
            invoice: r.invoice.to_string(),
            amount_sats: r
                .invoice
                .amount_milli_satoshis()
                .map(|a| bitcoin::Amount::from_msat_floor(a).to_sat())
                .unwrap_or(0),
            has_htlc_vtxos: !r.htlc_vtxos.is_empty(),
            preimage_revealed: r.preimage_revealed_at.is_some(),
        }
    }
}

// ============================================================================
// LightningSend
// ============================================================================

#[derive(Clone, Debug)]
pub struct LightningSend {
    pub invoice: String,
    pub amount_sats: u64,
    pub htlc_vtxo_count: u32,
    pub preimage: Option<String>,
}

impl From<bark::persist::models::LightningSend> for LightningSend {
    fn from(s: bark::persist::models::LightningSend) -> Self {
        Self {
            invoice: s.invoice.to_string(),
            amount_sats: s.amount.to_sat(),
            htlc_vtxo_count: s.htlc_vtxos.len() as u32,
            preimage: s.preimage.map(|p| p.to_string()),
        }
    }
}

// ============================================================================
// Movement
// ============================================================================

#[derive(Clone, Debug)]
pub struct Movement {
    pub id: u32,
    pub status: String,
    pub subsystem_name: String,
    pub subsystem_kind: String,
    pub metadata_json: String,
    pub intended_balance_sats: i64,
    pub effective_balance_sats: i64,
    pub offchain_fee_sats: u64,
    pub sent_to_addresses: Vec<String>,
    pub received_on_addresses: Vec<String>,
    pub input_vtxo_ids: Vec<String>,
    pub output_vtxo_ids: Vec<String>,
    pub exited_vtxo_ids: Vec<String>,
    pub created_at: String,
    pub updated_at: String,
    pub completed_at: Option<String>,
}

impl From<bark::movement::Movement> for Movement {
    fn from(m: bark::movement::Movement) -> Self {
        Self {
            id: m.id.0,
            status: m.status.to_string(),
            subsystem_name: m.subsystem.name.clone(),
            subsystem_kind: m.subsystem.kind.clone(),
            metadata_json: serde_json::to_string(&m.metadata).unwrap_or_else(|_| "{}".to_string()),
            intended_balance_sats: m.intended_balance.to_sat(),
            effective_balance_sats: m.effective_balance.to_sat(),
            offchain_fee_sats: m.offchain_fee.to_sat(),
            sent_to_addresses: m
                .sent_to
                .iter()
                .map(|d| {
                    // Serialize PaymentMethod to JSON string for FFI
                    serde_json::to_string(&d.destination)
                        .unwrap_or_else(|_| format!("{:?}", d.destination))
                })
                .collect(),
            received_on_addresses: m
                .received_on
                .iter()
                .map(|d| {
                    // Serialize PaymentMethod to JSON string for FFI
                    serde_json::to_string(&d.destination)
                        .unwrap_or_else(|_| format!("{:?}", d.destination))
                })
                .collect(),
            input_vtxo_ids: m.input_vtxos.iter().map(|v| v.to_string()).collect(),
            output_vtxo_ids: m.output_vtxos.iter().map(|v| v.to_string()).collect(),
            exited_vtxo_ids: m.exited_vtxos.iter().map(|v| v.to_string()).collect(),
            created_at: m.time.created_at.to_rfc3339(),
            updated_at: m.time.updated_at.to_rfc3339(),
            completed_at: m.time.completed_at.map(|t| t.to_rfc3339()),
        }
    }
}

// ============================================================================
// OnchainBalance
// ============================================================================

#[derive(Clone, Debug)]
pub struct OnchainBalance {
    pub confirmed_sats: u64,
    pub pending_sats: u64,
    pub total_sats: u64,
}

impl From<bark::onchain::bdk_wallet::Balance> for OnchainBalance {
    fn from(b: bark::onchain::bdk_wallet::Balance) -> Self {
        Self {
            confirmed_sats: b.confirmed.to_sat(),
            pending_sats: b.untrusted_pending.to_sat() + b.trusted_pending.to_sat(),
            total_sats: b.total().to_sat(),
        }
    }
}

// ============================================================================
// PendingBoard
// ============================================================================

#[derive(Clone, Debug)]
pub struct PendingBoard {
    pub vtxo_id: String,
    pub amount_sats: u64,
    pub txid: String,
}

impl From<BarkPendingBoard> for PendingBoard {
    fn from(pb: BarkPendingBoard) -> Self {
        Self {
            vtxo_id: pb.vtxos.first().map(|v| v.to_string()).unwrap_or_default(),
            amount_sats: pb.amount.to_sat(),
            txid: pb.funding_tx.compute_txid().to_string(),
        }
    }
}

// ============================================================================
// ArkInfo
// ============================================================================

#[derive(Clone, Debug)]
pub struct ArkInfo {
    pub network: Network,
    pub server_pubkey: String,
    pub round_interval_secs: u64,
    pub nb_round_nonces: u32,
    pub vtxo_exit_delta: u32,
    pub vtxo_expiry_delta: u32,
    pub htlc_send_expiry_delta: u32,
    pub htlc_expiry_delta: u32,
    pub max_vtxo_amount_sats: Option<u64>,
    pub required_board_confirmations: u32,
    pub max_user_invoice_cltv_delta: u16,
    pub min_board_amount_sats: u64,
    pub offboard_feerate_sat_per_vb: u64,
    pub ln_receive_anti_dos_required: bool,
    /// Fee schedule as JSON string (contains board, offboard, refresh, lightning fees)
    pub fee_schedule_json: String,
}

impl From<&bark::ark::ArkInfo> for ArkInfo {
    fn from(info: &bark::ark::ArkInfo) -> Self {
        use bitcoin::hex::DisplayHex;

        let fee_schedule_json =
            serde_json::to_string(&info.fees).unwrap_or_else(|_| "{}".to_string());

        Self {
            network: match info.network {
                BtcNetwork::Bitcoin => Network::Bitcoin,
                BtcNetwork::Testnet => Network::Testnet,
                BtcNetwork::Signet => Network::Signet,
                BtcNetwork::Regtest => Network::Regtest,
                _ => Network::Testnet,
            },
            server_pubkey: info.server_pubkey.serialize().as_hex().to_string(),
            round_interval_secs: info.round_interval.as_secs(),
            nb_round_nonces: info.nb_round_nonces as u32,
            vtxo_exit_delta: info.vtxo_exit_delta as u32,
            vtxo_expiry_delta: info.vtxo_expiry_delta as u32,
            htlc_send_expiry_delta: info.htlc_send_expiry_delta as u32,
            htlc_expiry_delta: info.htlc_expiry_delta as u32,
            max_vtxo_amount_sats: info.max_vtxo_amount.map(|a| a.to_sat()),
            required_board_confirmations: info.required_board_confirmations as u32,
            max_user_invoice_cltv_delta: info.max_user_invoice_cltv_delta,
            min_board_amount_sats: info.min_board_amount.to_sat(),
            offboard_feerate_sat_per_vb: info.offboard_feerate.to_sat_per_vb_ceil(),
            ln_receive_anti_dos_required: info.ln_receive_anti_dos_required,
            fee_schedule_json,
        }
    }
}

// ============================================================================
// Exit Types
// ============================================================================

use bark::exit::ExitProgressStatus as BarkExitProgressStatus;
use bark::exit::ExitVtxo as BarkExitVtxo;

/// A VTXO that is being unilaterally exited
#[derive(Clone, Debug)]
pub struct ExitVtxo {
    pub vtxo_id: String,
    pub amount_sats: u64,
    pub state: String,
    pub is_claimable: bool,
}

impl From<&BarkExitVtxo> for ExitVtxo {
    fn from(ev: &BarkExitVtxo) -> Self {
        Self {
            vtxo_id: ev.id().to_string(),
            amount_sats: ev.amount().to_sat(),
            state: format!("{:?}", ev.state()),
            is_claimable: ev.is_claimable(),
        }
    }
}

/// Status of an exit progression
#[derive(Clone, Debug)]
pub struct ExitProgressStatus {
    pub vtxo_id: String,
    pub state: String,
    pub error: Option<String>,
}

impl From<BarkExitProgressStatus> for ExitProgressStatus {
    fn from(eps: BarkExitProgressStatus) -> Self {
        Self {
            vtxo_id: eps.vtxo_id.to_string(),
            state: format!("{:?}", eps.state),
            error: eps.error.map(|e| e.to_string()),
        }
    }
}

/// Claim transaction for exited funds
#[derive(Clone, Debug)]
pub struct ExitClaimTransaction {
    pub psbt_base64: String,
    pub fee_sats: u64,
}

/// Detailed status of an exit transaction
#[derive(Clone, Debug)]
pub struct ExitTransactionStatus {
    pub vtxo_id: String,
    pub state: String,
    pub history: Option<Vec<String>>,
    pub transaction_count: u32,
}

impl From<bark::exit::ExitTransactionStatus> for ExitTransactionStatus {
    fn from(ets: bark::exit::ExitTransactionStatus) -> Self {
        Self {
            vtxo_id: ets.vtxo_id.to_string(),
            state: format!("{:?}", ets.state),
            history: ets
                .history
                .map(|h| h.iter().map(|s| format!("{:?}", s)).collect()),
            transaction_count: ets.transactions.len() as u32,
        }
    }
}

// ============================================================================
// Round Types
// ============================================================================

use bark::persist::models::{StoredRoundState, Unlocked};

/// A pending round state
#[derive(Clone, Debug)]
pub struct RoundState {
    pub id: u32,
    /// Whether the round is ongoing
    pub ongoing: bool,
}

impl From<StoredRoundState<Unlocked>> for RoundState {
    fn from(rs: StoredRoundState<Unlocked>) -> Self {
        Self {
            id: rs.id().0,
            ongoing: rs.state().ongoing_participation(),
        }
    }
}

// ============================================================================
// Callback Wallet Types
// ============================================================================

/// A Bitcoin transaction output destination
#[derive(Clone, Debug)]
pub struct Destination {
    pub address: String,
    pub amount_sats: u64,
}

/// A Bitcoin transaction outpoint (reference to a previous output)
#[derive(Clone, Debug)]
pub struct OutPoint {
    pub txid: String,
    pub vout: u32,
}

/// Reference to a block in the blockchain
#[derive(Clone, Debug)]
pub struct BlockRef {
    pub height: u32,
    pub hash: String,
}

/// Parameters for creating a CPFP (Child Pays For Parent) transaction
#[derive(Clone, Debug)]
pub struct CpfpParams {
    pub tx_hex: String,
    pub fees_type: String,
    pub effective_fee_rate_sat_per_vb: u64,
    pub current_package_fee_sats: Option<u64>,
}

// ============================================================================
// WalletNotification
// ============================================================================

/// A notification event from the wallet
#[derive(Clone, Debug)]
pub enum WalletNotification {
    /// A new movement was created
    MovementCreated { movement: Movement },
    /// An existing movement was updated
    MovementUpdated { movement: Movement },
    /// The notification channel is lagging (notifications were dropped)
    ChannelLagging,
}

impl From<bark::WalletNotification> for WalletNotification {
    fn from(n: bark::WalletNotification) -> Self {
        match n {
            bark::WalletNotification::MovementCreated { movement } => {
                WalletNotification::MovementCreated {
                    movement: movement.into(),
                }
            }
            bark::WalletNotification::MovementUpdated { movement } => {
                WalletNotification::MovementUpdated {
                    movement: movement.into(),
                }
            }
            bark::WalletNotification::ChannelLagging => WalletNotification::ChannelLagging,
        }
    }
}
