use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use futures_util::StreamExt;
use tokio::sync::oneshot;

use crate::error::BarkError;
use crate::types::WalletNotification;

/// Pull-based notification handle exposed over FFI.
///
/// Obtain via `Wallet::notifications()`. Call `next_notification()` in a loop
/// to receive events. Call `cancel_next_notification_wait()` to unblock a
/// pending wait without destroying the underlying stream.
///
/// Each call to `Wallet::notifications()` creates an independent stream backed
/// by a new broadcast receiver — existing holders are unaffected.
///
/// This holder is intended for a single consumer loop. Concurrent calls to
/// `next_notification()` on the same holder are not supported and will return
/// `None` immediately.
#[cfg_attr(feature = "uniffi-bindings", derive(uniffi::Object))]
pub struct NotificationHolder {
    /// The bark notification stream. Held in a tokio Mutex because we need to
    /// hold it across the `.await` point inside `next_notification()`.
    stream: tokio::sync::Mutex<bark::NotificationStream>,

    /// Sender half of the per-wait cancellation one-shot channel.
    /// Replaced on every `next_notification()` call, so cancellation is scoped
    /// to exactly one wait cycle. A std Mutex suffices here because
    /// `cancel_next_notification_wait()` is synchronous and never held across
    /// an await point.
    cancel: Mutex<Option<oneshot::Sender<()>>>,

    /// Guards against concurrent `next_notification()` calls on the same holder.
    /// Reset via a RAII guard so it is always cleared even if the async body panics.
    wait_in_progress: AtomicBool,
}

/// RAII guard that clears `wait_in_progress` on drop, including on panic.
struct WaitGuard<'a>(&'a AtomicBool);

impl Drop for WaitGuard<'_> {
    fn drop(&mut self) {
        self.0.store(false, Ordering::Release);
    }
}

impl NotificationHolder {
    pub(crate) fn new(wallet: &bark::Wallet) -> Arc<Self> {
        Arc::new(Self {
            stream: tokio::sync::Mutex::new(wallet.subscribe_notifications()),
            cancel: Mutex::new(None),
            wait_in_progress: AtomicBool::new(false),
        })
    }
}

#[cfg_attr(feature = "uniffi-bindings", uniffi::export(async_runtime = "tokio"))]
impl NotificationHolder {
    /// Wait for the next wallet notification.
    ///
    /// Returns `None` when:
    /// - `cancel_next_notification_wait()` was called while this was pending
    ///   (cancellation only affects the current wait; the stream lives on)
    /// - The wallet's notification source was shut down permanently
    ///
    /// Returns `Err(BarkError::Internal)` if called concurrently on the same holder.
    ///
    /// After a cancellation this method can be called again normally — the
    /// underlying `NotificationStream` is preserved in `self.stream` and a
    /// fresh per-wait cancel channel is created on every entry.
    pub async fn next_notification(
        self: Arc<Self>,
    ) -> Result<Option<WalletNotification>, BarkError> {
        // Enforce single-consumer: reject concurrent calls with an explicit error.
        if self
            .wait_in_progress
            .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
            .is_err()
        {
            return Err(BarkError::Internal {
                error_message: "next_notification() called concurrently on the same holder".into(),
            });
        }

        // RAII guard resets wait_in_progress on exit, even on panic.
        let _guard = WaitGuard(&self.wait_in_progress);

        // Create a fresh one-shot cancel channel for this specific wait cycle.
        // Once consumed — either by cancellation or by next_notification
        // returning — it is discarded. The next call creates a new channel.
        let (tx, rx) = oneshot::channel::<()>();
        {
            let mut cancel = self.cancel.lock().unwrap();
            debug_assert!(cancel.is_none(), "cancel slot should be empty on entry");
            *cancel = Some(tx);
        }

        let result = {
            let mut stream = self.stream.lock().await;
            tokio::select! {
                // Normal case: a notification arrived on the stream.
                notification = stream.next() => {
                    notification.map(WalletNotification::from)
                }
                // Cancellation case: cancel_next_notification_wait() sent on
                // `tx`. The stream itself is completely unaffected — only this
                // wait is interrupted. The next call to next_notification()
                // acquires the lock again and waits from where the stream left off.
                _ = rx => None,
            }
        };

        // Clear the cancel slot. Safe: wait_in_progress ensures we are the
        // sole active waiter, so no concurrent call can own this slot.
        *self.cancel.lock().unwrap() = None;

        Ok(result)
    }

    /// Cancel the currently pending `next_notification()` wait.
    ///
    /// Causes a blocked `next_notification()` to return `None`.
    /// Has no effect if no wait is currently active.
    ///
    /// This does NOT destroy the underlying `NotificationStream`; a subsequent
    /// call to `next_notification()` will work normally and wait for new events.
    pub fn cancel_next_notification_wait(&self) {
        if let Some(tx) = self.cancel.lock().unwrap().take() {
            let _ = tx.send(());
        }
    }
}
