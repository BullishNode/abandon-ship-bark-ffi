#![allow(non_snake_case)]

use wasm_bindgen::prelude::*;

use crate::error::Error;
use crate::functions as core_fns;

fn bark_err(e: Error) -> JsError {
    JsError::new(&e.message())
}

#[wasm_bindgen(js_name = generateMnemonic)]
pub fn generate_mnemonic() -> Result<String, JsError> {
    core_fns::generate_mnemonic().map_err(bark_err)
}

#[wasm_bindgen(js_name = validateMnemonic)]
pub fn validate_mnemonic(mnemonic: String) -> Result<bool, JsError> {
    core_fns::validate_mnemonic(mnemonic).map_err(bark_err)
}

#[wasm_bindgen(js_name = validateArkAddress)]
pub fn validate_ark_address(address: String) -> Result<bool, JsError> {
    core_fns::validate_ark_address(address).map_err(bark_err)
}

#[wasm_bindgen(js_name = extractTxFromPsbt)]
pub fn extract_tx_from_psbt(psbtBase64: String) -> Result<String, JsError> {
    core_fns::extract_tx_from_psbt(psbtBase64).map_err(bark_err)
}

#[wasm_bindgen(js_name = defaultVtxoKeyGapLimit)]
pub fn default_vtxo_key_gap_limit() -> u32 {
    core_fns::default_vtxo_key_gap_limit()
}

#[wasm_bindgen(js_name = maxVtxoKeyGapLimit)]
pub fn max_vtxo_key_gap_limit() -> u32 {
    core_fns::max_vtxo_key_gap_limit()
}
