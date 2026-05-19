use bitcoin::Network as BtcNetwork;
use serde::{Deserialize, Serialize};

use crate::types::Network;

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(from_wasm_abi, into_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi-bindings", derive(uniffi::Record))]
pub struct Config {
    pub server_address: String,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub server_access_token: Option<String>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub esplora_address: Option<String>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub bitcoind_address: Option<String>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub bitcoind_cookiefile: Option<String>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub bitcoind_user: Option<String>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub bitcoind_pass: Option<String>,
    pub network: Network,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub vtxo_refresh_expiry_threshold: Option<u32>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub vtxo_exit_margin: Option<u16>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub htlc_recv_claim_delta: Option<u16>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub fallback_fee_rate: Option<u64>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub round_tx_required_confirmations: Option<u32>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub daemon_fast_sync_interval_secs: Option<u64>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub daemon_slow_sync_interval_secs: Option<u64>,
}

impl From<Config> for bark::Config {
    fn from(c: Config) -> Self {
        let network: BtcNetwork = c.network.into();
        let mut cfg = bark::Config::network_default(network);

        cfg.server_address = c.server_address;
        cfg.server_access_token = c.server_access_token;
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
        if let Some(secs) = c.daemon_fast_sync_interval_secs {
            cfg.daemon_fast_sync_interval_secs = secs;
        }
        if let Some(secs) = c.daemon_slow_sync_interval_secs {
            cfg.daemon_slow_sync_interval_secs = secs;
        }

        cfg
    }
}
