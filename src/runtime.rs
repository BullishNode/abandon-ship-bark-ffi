use once_cell::sync::Lazy;
use std::future::Future;
use tokio::runtime::Runtime;

/// Global multi-threaded Tokio runtime for all Bark async work
pub static TOKIO_RT: Lazy<Runtime> = Lazy::new(|| {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_name("bark-ffi-runtime")
        .build()
        .expect("Failed to create Tokio runtime")
});

/// Run an async closure on the runtime
///
/// This provides a single abstraction point for running async code,
/// making it easy to swap out the runtime implementation in the future
/// (e.g., for browser-based runtimes).
pub(crate) async fn run_async<F, T>(future: F) -> T
where
    F: Future<Output = T> + Send + 'static,
    T: Send + 'static,
{
    TOKIO_RT.spawn(future).await.expect("Task panicked")
}
