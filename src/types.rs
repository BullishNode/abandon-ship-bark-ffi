use bark::persist::models::PendingBoard as BarkPendingBoard;
use bark::WalletVtxo as BarkWalletVtxo;
use bark::{Balance as BarkBalance, WalletProperties as BarkWalletProperties};
use bark_bitcoin_ext::AmountExt;
use bitcoin::Network as BtcNetwork;
use serde::{Deserialize, Serialize};

// ============================================================================
// Network
// ============================================================================

#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(from_wasm_abi, into_wasm_abi)
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
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
// WalletProperties
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Vtxo {
    pub id: String,
    pub amount_sats: u64,
    pub expiry_height: u32,
    pub kind: String,
    pub state: String,
    /// Genesis chain length. Compare against `ArkInfo.max_vtxo_exit_depth` to
    /// detect VTXOs nearing the server's OOR-cosign refusal threshold.
    pub exit_depth: u32,
    /// Weight units of the unilateral exit transaction chain. Lets clients
    /// estimate exit cost without loading the full genesis.
    pub exit_tx_weight_wu: u64,
}

impl From<BarkWalletVtxo> for Vtxo {
    fn from(v: BarkWalletVtxo) -> Self {
        Self {
            id: v.vtxo.id().to_string(),
            amount_sats: v.vtxo.amount().to_sat(),
            expiry_height: v.vtxo.expiry_height(),
            kind: format!("{:?}", v.vtxo.policy_type()),
            state: format!("{:?}", v.state.kind()),
            exit_depth: v.exit_depth as u32,
            exit_tx_weight_wu: v.exit_tx_weight.to_wu(),
        }
    }
}

// ============================================================================
// LightningInvoice
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct LightningInvoice {
    pub invoice: String,
    pub payment_hash: String,
    pub amount_sats: u64,
}

// ============================================================================
// OffboardResult
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct OffboardResult {
    pub round_id: String,
}

// ============================================================================
// AddressWithIndex
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct AddressWithIndex {
    pub address: String,
    pub index: u32,
}

// ============================================================================
// LightningReceive
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct LightningReceive {
    pub payment_hash: String,
    pub invoice: String,
    pub amount_sats: u64,
    /// Receive progress: "awaiting-payment" | "htlcs-ready" |
    /// "preimage-revealed" | "settled"
    pub state: String,
    /// Known while in-progress; present when settled.
    pub payment_preimage: Option<String>,
    /// Unix timestamp (seconds), set only when the receive is settled.
    pub settled_at: Option<i64>,
}

impl From<bark::actions::lightning::receive::LightningReceive> for LightningReceive {
    fn from(r: bark::actions::lightning::receive::LightningReceive) -> Self {
        use bark::actions::lightning::receive::Progress;
        let state = match r.progress {
            Progress::AwaitingPayment => "awaiting-payment",
            Progress::HtlcsReady(_) => "htlcs-ready",
            Progress::PreimageRevealed(_) => "preimage-revealed",
        };
        Self {
            payment_hash: r.payment_hash.to_string(),
            invoice: r.invoice.to_string(),
            amount_sats: r
                .invoice
                .amount_milli_satoshis()
                .map(|a| bitcoin::Amount::from_msat_floor(a).to_sat())
                .unwrap_or(0),
            state: state.to_string(),
            payment_preimage: Some(r.payment_preimage.to_string()),
            settled_at: None,
        }
    }
}

impl From<bark::persist::models::SettledLightningReceive> for LightningReceive {
    fn from(r: bark::persist::models::SettledLightningReceive) -> Self {
        Self {
            payment_hash: r.payment_hash.to_string(),
            invoice: r.invoice.to_string(),
            amount_sats: r.amount.to_sat(),
            state: "settled".to_string(),
            payment_preimage: Some(r.preimage.to_string()),
            settled_at: Some(r.settled_at.timestamp()),
        }
    }
}

impl From<bark::actions::lightning::receive::LightningReceiveState> for LightningReceive {
    fn from(s: bark::actions::lightning::receive::LightningReceiveState) -> Self {
        use bark::actions::lightning::receive::LightningReceiveState;
        match s {
            LightningReceiveState::InProgress(r) => r.into(),
            LightningReceiveState::Settled(r) => r.into(),
        }
    }
}

// ============================================================================
// LightningSend
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct LightningSend {
    pub invoice: String,
    /// Amount being paid, in sats (`payment_amount`).
    pub amount_sats: u64,
    /// Routing/ark fee for the send, in sats.
    pub fee_sats: u64,
    /// Number of input VTXOs locked into the in-flight HTLC.
    pub htlc_vtxo_count: u32,
    /// Whether the send is stuck in the revocation-failed state: the payment
    /// failed but revoking the HTLC also failed
    pub has_failed_revocation: bool,
}

impl From<bark::actions::lightning::pay::LightningSend> for LightningSend {
    fn from(s: bark::actions::lightning::pay::LightningSend) -> Self {
        Self {
            invoice: s.invoice.to_string(),
            amount_sats: s.payment_amount.to_sat(),
            fee_sats: s.fee.to_sat(),
            htlc_vtxo_count: s.input_vtxo_ids.len() as u32,
            has_failed_revocation: s.has_failed_revocation(),
        }
    }
}

// ============================================================================
// LightningSendStatus
// ============================================================================

/// Terminal/in-flight state of an outgoing lightning send.
///
/// Mirrors `bark`'s `LightningSendState`. `pay_lightning_*` and
/// `check_lightning_payment` now return this so callers can drive the
/// crash-safe send flow themselves (initiate with `wait = false`, then poll).
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi),
    serde(tag = "type", rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum LightningSendStatus {
    /// No record of this payment (never started, or already pruned).
    Unknown,
    /// Send is in flight; HTLC VTXOs are locked.
    InProgress { send: LightningSend },
    /// Send has settled; the preimage proves payment.
    Paid {
        payment_hash: String,
        preimage: String,
    },
}

impl From<bark::actions::lightning::pay::LightningSendState> for LightningSendStatus {
    fn from(state: bark::actions::lightning::pay::LightningSendState) -> Self {
        use bark::actions::lightning::pay::LightningSendState as State;
        match state {
            State::Unknown => Self::Unknown,
            State::InProgress(send) => Self::InProgress { send: send.into() },
            State::Paid(paid) => Self::Paid {
                payment_hash: paid.payment_hash.to_string(),
                preimage: paid.preimage.to_string(),
            },
        }
    }
}

// ============================================================================
// Movement
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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

    // calculated fields
    pub payment_hash: Option<String>,
    pub lightning_invoice: Option<String>,
    pub lightning_offer: Option<String>,
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

            payment_hash: m.lightning_payment_hash().map(|h| h.to_string()),
            lightning_invoice: m.lightning_invoice().map(|i| i.to_string()),
            lightning_offer: m.lightning_offer().map(|o| o.to_string()),
        }
    }
}

// ============================================================================
// FeeEstimate
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct FeeEstimate {
    pub gross_amount_sats: u64,
    pub fee_sats: u64,
    pub net_amount_sats: u64,
    pub vtxos_spent: Vec<String>,
}

impl From<bark::FeeEstimate> for FeeEstimate {
    fn from(f: bark::FeeEstimate) -> Self {
        Self {
            gross_amount_sats: f.gross_amount.to_sat(),
            fee_sats: f.fee.to_sat(),
            net_amount_sats: f.net_amount.to_sat(),
            vtxos_spent: f.vtxos_spent.iter().map(|v| v.to_string()).collect(),
        }
    }
}

// ============================================================================
// OnchainBalance
// ============================================================================

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
    pub ln_receive_anti_dos_required: bool,
    /// Fee schedule as JSON string (contains board, offboard, refresh, lightning fees)
    pub fee_schedule_json: String,
    /// Maximum exit depth (genesis chain length) allowed for a VTXO before the
    /// server refuses to cosign further OOR transactions spending it.
    pub max_vtxo_exit_depth: u16,
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
            ln_receive_anti_dos_required: info.ln_receive_anti_dos_required,
            fee_schedule_json,
            max_vtxo_exit_depth: info.max_vtxo_exit_depth,
        }
    }
}

// ============================================================================
// Exit Types
// ============================================================================

use bark::exit::ExitProgressStatus as BarkExitProgressStatus;
use bark::exit::ExitVtxo as BarkExitVtxo;

/// A VTXO that is being unilaterally exited
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct ExitClaimTransaction {
    pub psbt_base64: String,
    pub fee_sats: u64,
}

/// Detailed status of an exit transaction
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Destination {
    pub address: String,
    pub amount_sats: u64,
}

/// A Bitcoin transaction outpoint (reference to a previous output)
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct OutPoint {
    pub txid: String,
    pub vout: u32,
}

/// Reference to a block in the blockchain
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct BlockRef {
    pub height: u32,
    pub hash: String,
}

/// Parameters for creating a CPFP (Child Pays For Parent) transaction
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi, from_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(into_wasm_abi),
    serde(tag = "type")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
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
