use once_cell::sync::Lazy;
use tokio::runtime::Runtime;

/// Global multi-threaded Tokio runtime for all Bark async work
pub static TOKIO_RT: Lazy<Runtime> = Lazy::new(|| {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_name("bark-ffi-runtime")
        .build()
        .expect("Failed to create Tokio runtime")
});
