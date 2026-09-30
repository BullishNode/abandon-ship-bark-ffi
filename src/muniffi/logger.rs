//! Foreign-callback bridge into the `log` crate.
//!
//! Foreign code (Dart/Swift/Kotlin) implements [`BarkLogger`] and registers
//! the implementation via [`set_logger`]. All `log::info!` / `warn!` / etc.
//! calls in this crate (and in `bark`/`ark`) are then forwarded to the foreign
//! callback.
//!
//! The bridge should be installed once per process

use std::sync::Arc;

use log::LevelFilter;
use once_cell::sync::OnceCell;

use crate::error::Error;
use crate::types::LogLevel;

/// Foreign-implemented sink for log records.
///
/// IMPORTANT: implementations must not call back into bark APIs that
/// themselves emit log records, or the foreign runtime may stack-overflow
/// or deadlock.
#[uniffi::export(with_foreign)]
pub trait BarkLogger: Send + Sync {
    fn log(&self, level: LogLevel, target: String, message: String);
}

struct Bridge {
    sink: Arc<dyn BarkLogger>,
    filter: LevelFilter,
}

static BRIDGE: OnceCell<Bridge> = OnceCell::new();

impl log::Log for Bridge {
    fn enabled(&self, metadata: &log::Metadata) -> bool {
        metadata.level() <= self.filter
    }

    fn log(&self, record: &log::Record) {
        if !self.enabled(record.metadata()) {
            return;
        }
        self.sink.log(
            record.level().into(),
            record.target().to_string(),
            format!("{}", record.args()),
        );
    }

    fn flush(&self) {}
}

/// Install the foreign logger.
///
/// On first call, installs the bridge with `log::set_logger`. Subsequent calls
/// will return an error.
#[uniffi::export]
pub fn set_logger(
    logger: Arc<dyn BarkLogger>,
    max_level: LogLevel,
) -> Result<(), Error> {
    let filter: LevelFilter = max_level.into();

    let bridge = BRIDGE.try_insert(Bridge { sink: logger, filter })
        .map_err(|_| Error::from("logger already installed"))?;

    log::set_logger(bridge)
        .map_err(|_| Error::from("could not set logger"))?;
    log::set_max_level(filter);

    Ok(())
}
