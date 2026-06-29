use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
#[cfg_attr(
    feature = "wasm-web",
    derive(tsify::Tsify),
    tsify(from_wasm_abi, into_wasm_abi),
    serde(rename_all = "camelCase")
)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
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
    pub daemon_sync_interval_secs: Option<u64>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub offboard_required_confirmations: Option<u32>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub daemon_manual_sync: Option<bool>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub lightning_receive_claim_retries: Option<u8>,
    #[cfg_attr(feature = "wasm-web", tsify(optional))]
    pub user_agent: Option<String>,
}

/// Compile-time default user-agent. Each language wrapper sets
/// `BARK_FFI_DEFAULT_LANG` in its `.cargo/config.toml [env]` (e.g. `"swift"`,
/// `"wasm"`); cargo propagates it to dependency builds, and bark-ffi composes
/// `bark-{lang}/{bark-ffi-version}` from it. Returns `None` when bark-ffi is
/// built standalone.
fn default_user_agent() -> Option<String> {
    let lang = option_env!("BARK_FFI_DEFAULT_LANG")?;
    Some(format!("bark-{}/{}", lang, env!("CARGO_PKG_VERSION")))
}

impl Config {
    pub(crate) fn into_bark(self, network: bitcoin::Network) -> bark::Config {
        let mut ret = bark::Config::network_default(network);
        
        ret.server_address = self.server_address;
        ret.server_access_token = self.server_access_token;
        ret.user_agent = self.user_agent.or_else(default_user_agent);
        ret.esplora_address = self.esplora_address;
        ret.bitcoind_address = self.bitcoind_address;
        ret.bitcoind_cookiefile = self.bitcoind_cookiefile.map(std::path::PathBuf::from);
        ret.bitcoind_user = self.bitcoind_user;
        ret.bitcoind_pass = self.bitcoind_pass;

        if let Some(threshold) = self.vtxo_refresh_expiry_threshold {
            ret.vtxo_refresh_expiry_threshold = threshold;
        }
        if let Some(margin) = self.vtxo_exit_margin {
            ret.vtxo_exit_margin = margin;
        }
        if let Some(delta) = self.htlc_recv_claim_delta {
            ret.htlc_recv_claim_delta = delta;
        }
        if let Some(rate) = self.fallback_fee_rate {
            ret.fallback_fee_rate = Some(bitcoin::FeeRate::from_sat_per_kwu(rate));
        }
        if let Some(confs) = self.round_tx_required_confirmations {
            ret.round_tx_required_confirmations = confs;
        }
        if let Some(secs) = self.daemon_sync_interval_secs {
            ret.daemon_sync_interval_secs = secs;
        }
        if let Some(confs) = self.offboard_required_confirmations {
            ret.offboard_required_confirmations = confs;
        }
        if let Some(manual) = self.daemon_manual_sync {
            ret.daemon_manual_sync = manual;
        }
        if let Some(retries) = self.lightning_receive_claim_retries {
            ret.lightning_receive_claim_retries = retries;
        }

        ret
    }
}
