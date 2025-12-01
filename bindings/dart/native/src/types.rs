use bark::WalletVtxo as BarkWalletVtxo;
use bark::{Balance as BarkBalance, WalletProperties as BarkWalletProperties};
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
    pub network: Network,
    pub vtxo_refresh_expiry_threshold: Option<u32>,
    pub vtxo_exit_margin: Option<u16>,
    pub htlc_recv_claim_delta: Option<u16>,
}

impl From<Config> for bark::Config {
    fn from(c: Config) -> Self {
        let network: BtcNetwork = c.network.into();
        let mut cfg = bark::Config::network_default(network);

        cfg.server_address = c.server_address;
        cfg.esplora_address = c.esplora_address;

        if let Some(threshold) = c.vtxo_refresh_expiry_threshold {
            cfg.vtxo_refresh_expiry_threshold = threshold;
        }
        if let Some(margin) = c.vtxo_exit_margin {
            cfg.vtxo_exit_margin = margin;
        }
        if let Some(delta) = c.htlc_recv_claim_delta {
            cfg.htlc_recv_claim_delta = delta;
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
    pub pending_lightning_receive_total_sats: u64,
    pub pending_lightning_receive_claimable_sats: u64,
    pub pending_board_sats: u64,
}

impl From<BarkBalance> for Balance {
    fn from(b: BarkBalance) -> Self {
        Self {
            spendable_sats: b.spendable.to_sat(),
            pending_in_round_sats: b.pending_in_round.to_sat(),
            pending_exit_sats: b.pending_exit.unwrap_or_default().to_sat(),
            pending_lightning_send_sats: b.pending_lightning_send.to_sat(),
            pending_lightning_receive_total_sats: b.claimable_lightning_receive.to_sat(),
            pending_lightning_receive_claimable_sats: b.claimable_lightning_receive.to_sat(),
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
// LightningPaymentResult
// ============================================================================

#[derive(Clone, Debug)]
pub struct LightningPaymentResult {
    pub invoice: String,
    pub preimage: String,
}

// ============================================================================
// OffboardResult
// ============================================================================

#[derive(Clone, Debug)]
pub struct OffboardResult {
    pub round_id: String,
}
