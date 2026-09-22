use std::sync::Arc;

use tsify::{Ts, Tsify};
use wasm_bindgen::prelude::*;

use crate::core::notification::NotificationHolder as CoreHolder;
use crate::error::Error;
use crate::types::WalletNotification;

fn bark_err(e: Error) -> JsError {
    JsError::new(&e.message())
}

/// Pull-based notification handle exposed to JS.
///
/// Obtain via `wallet.notifications()`. Loop on `await notif.nextNotification()`.
/// Each call to `wallet.notifications()` creates an independent stream — existing
/// holders are unaffected.
///
/// Single-consumer per holder: concurrent `nextNotification()` calls reject with
/// an `Internal` error.
#[wasm_bindgen]
pub struct NotificationHolder {
    inner: Arc<CoreHolder>,
}

impl NotificationHolder {
    pub(crate) fn new(wallet: &bark::Wallet) -> Self {
        Self { inner: CoreHolder::new(wallet) }
    }
}

#[wasm_bindgen]
impl NotificationHolder {
    /// Wait for the next wallet notification.
    ///
    /// Resolves to a `WalletNotification` object, or `null` if:
    /// - `cancelNextNotificationWait()` was called while pending, or
    /// - the wallet's notification source was shut down.
    #[wasm_bindgen(js_name = nextNotification)]
    pub async fn next_notification(&self) -> Result<Option<Ts<WalletNotification>>, JsError> {
        Ok(self
            .inner
            .clone()
            .next_notification()
            .await
            .map_err(bark_err)?
            .map(|v| v.into_ts())
            .transpose()?)
    }

    /// Cancel the currently pending `nextNotification()` wait.
    ///
    /// Causes a blocked `nextNotification()` to resolve to `null`. Does NOT
    /// destroy the underlying stream — a subsequent call resumes normally.
    #[wasm_bindgen(js_name = cancelNextNotificationWait)]
    pub fn cancel_next_notification_wait(&self) {
        self.inner.cancel_next_notification_wait();
    }
}
