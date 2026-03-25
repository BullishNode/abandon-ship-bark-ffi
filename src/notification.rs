use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use crate::runtime::TOKIO_RT;
use crate::types::WalletNotification;

/// Callback interface for receiving wallet notifications.
///
/// Implement this in your language (Swift, Kotlin, Dart, Go, etc.)
/// to receive real-time wallet events.
pub trait WalletNotificationListener: Send + Sync + 'static {
    /// Called when a new movement is created
    fn on_movement_created(&self, movement: crate::types::Movement);

    /// Called when an existing movement is updated
    fn on_movement_updated(&self, movement: crate::types::Movement);

    /// Called when the notification channel is lagging (some notifications were dropped)
    fn on_channel_lagging(&self);

    /// Called when an error occurs in the notification stream
    fn on_error(&self, error: String);
}

/// Handle to a notification subscription.
///
/// Drop or call `cancel()` to stop receiving notifications.
pub struct NotificationSubscription {
    cancelled: Arc<AtomicBool>,
}

impl NotificationSubscription {
    pub(crate) fn new(cancelled: Arc<AtomicBool>) -> Self {
        Self { cancelled }
    }

    /// Cancel the notification subscription
    pub fn cancel(&self) {
        self.cancelled.store(true, Ordering::Relaxed);
    }

    /// Check if the subscription is still active
    pub fn is_active(&self) -> bool {
        !self.cancelled.load(Ordering::Relaxed)
    }
}

impl Drop for NotificationSubscription {
    fn drop(&mut self) {
        self.cancel();
    }
}

/// Start a notification subscription on the given wallet.
///
/// Spawns a background tokio task that reads from the wallet's
/// notification stream and dispatches events to the listener.
pub(crate) fn spawn_notification_listener(
    wallet: &bark::Wallet,
    listener: Box<dyn WalletNotificationListener>,
) -> Arc<NotificationSubscription> {
    use futures_util::StreamExt;

    let cancelled = Arc::new(AtomicBool::new(false));
    let cancelled_clone = cancelled.clone();

    let mut stream = wallet.subscribe_notifications();

    TOKIO_RT.spawn(async move {
        while !cancelled_clone.load(Ordering::Relaxed) {
            match stream.next().await {
                Some(notification) => {
                    let ffi_notification = WalletNotification::from(notification);
                    match ffi_notification {
                        WalletNotification::MovementCreated { movement } => {
                            listener.on_movement_created(movement);
                        },
                        WalletNotification::MovementUpdated { movement } => {
                            listener.on_movement_updated(movement);
                        },
                        WalletNotification::ChannelLagging => {
                            listener.on_channel_lagging();
                        },
                    }
                },
                // Stream ended
                None => break,
            }
        }
    });

    Arc::new(NotificationSubscription::new(cancelled))
}
