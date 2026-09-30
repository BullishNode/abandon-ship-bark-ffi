//! Opt-in bridge from the `log` crate to JS.
//!
//! Silent by default: until `setLogger` or `barkAttachConsoleLogger` is
//! called, the max level stays `Off`, so bark's log macros return before
//! formatting anything.
//!
//! State lives in `thread_local!`s: the browser build is single-threaded, and
//! the JS logger handle is neither `Send` nor `Sync`.
#![allow(non_snake_case)]

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use log::{LevelFilter, Log, Metadata, Record};
use tsify::Ts;
use wasm_bindgen::prelude::*;

use crate::types::LogLevel;

#[wasm_bindgen(typescript_custom_section)]
const BARK_LOGGER_TS: &str = r#"
/**
 * Receives bark's log records: `level` is at or above the `maxLevel` given to
 * `setLogger`, `target` is the Rust module the record comes from.
 *
 * Called synchronously while bark runs, so keep it cheap and don't call back
 * into bark from it. Anything it throws is ignored.
 */
export interface BarkLogger {
    log(level: LogLevel, target: string, message: string): void;
}
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "BarkLogger")]
    pub type BarkLogger;

    // Read to check that `log` is callable before installing the logger.
    #[wasm_bindgen(method, getter = log, catch)]
    fn log_member(this: &BarkLogger) -> Result<JsValue, JsValue>;

    // `catch` turns an exception thrown by the logger into an `Err`, instead
    // of letting it unwind through bark's frames.
    #[wasm_bindgen(method, catch)]
    fn log(this: &BarkLogger, level: &str, target: &str, message: &str) -> Result<(), JsValue>;

    // `catch` for the same reason: hosts wrap `console` (error trackers, test
    // spies), and the wrapper can throw.
    #[wasm_bindgen(js_namespace = console, js_name = error, catch)]
    fn console_error(line: &str) -> Result<(), JsValue>;

    #[wasm_bindgen(js_namespace = console, js_name = warn, catch)]
    fn console_warn(line: &str) -> Result<(), JsValue>;

    #[wasm_bindgen(js_namespace = console, js_name = info, catch)]
    fn console_info(line: &str) -> Result<(), JsValue>;

    #[wasm_bindgen(js_namespace = console, js_name = debug, catch)]
    fn console_debug(line: &str) -> Result<(), JsValue>;
}

enum Sink {
    Console,
    Js(BarkLogger),
}

impl Sink {
    fn write(&self, record: &Record) {
        let level = LogLevel::from(record.level());
        match self {
            Sink::Console => {
                let line = format!(
                    "[bark][{}][{}] {}",
                    level.as_str(),
                    record.target(),
                    record.args()
                );
                // Ignored like the JS logger's errors below.
                let _ = match level {
                    LogLevel::Error => console_error(&line),
                    LogLevel::Warn => console_warn(&line),
                    LogLevel::Info => console_info(&line),
                    // `console.trace` would print a stack trace with every record.
                    LogLevel::Debug | LogLevel::Trace => console_debug(&line),
                };
            }
            Sink::Js(logger) => {
                // A failing logger must not break the bark call that logged.
                let _ = logger.log(level.as_str(), record.target(), &record.args().to_string());
            }
        }
    }
}

thread_local! {
    static SINK: RefCell<Option<Rc<Sink>>> = const { RefCell::new(None) };
    /// Set while a record is written, so records emitted by a logger that calls
    /// back into bark are dropped instead of recursing.
    static WRITING: Cell<bool> = const { Cell::new(false) };
    /// Whether `BRIDGE` is installed as the `log` crate's logger.
    static INSTALLED: Cell<bool> = const { Cell::new(false) };
}

struct Bridge;

static BRIDGE: Bridge = Bridge;

impl Log for Bridge {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= log::max_level()
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) || WRITING.get() {
            return;
        }
        // Cloned out of the cell, so the logger can call `setLogger` or
        // `clearLogger` without hitting a held borrow.
        let Some(sink) = SINK.with_borrow(Option::clone) else {
            return;
        };
        WRITING.set(true);
        sink.write(record);
        WRITING.set(false);
    }

    fn flush(&self) {}
}

fn install(sink: Sink, max_level: LogLevel) -> Result<(), JsError> {
    if !INSTALLED.get() {
        log::set_logger(&BRIDGE)
            .map_err(|_| JsError::new("another logger is already installed"))?;
        INSTALLED.set(true);
    }
    SINK.set(Some(Rc::new(sink)));
    log::set_max_level(max_level.into());
    Ok(())
}

/// Send bark's log records at or above `maxLevel` to `logger`.
///
/// Logging is off until this or `barkAttachConsoleLogger` is called. Calling
/// either again replaces the current logger; `clearLogger` turns logging off.
#[wasm_bindgen(js_name = setLogger)]
pub fn set_logger(logger: BarkLogger, maxLevel: Ts<LogLevel>) -> Result<(), JsError> {
    if !logger.log_member().is_ok_and(|log| log.is_function()) {
        return Err(JsError::new(
            "logger must have a log(level, target, message) method",
        ));
    }
    install(Sink::Js(logger), maxLevel.to_rust()?)
}

/// Log bark's records at or above `maxLevel` (default `"info"`) to the console.
///
/// `debug` and `trace` go to `console.debug`, which Chrome DevTools hides
/// unless the Verbose level is enabled. Replaces the current logger;
/// `clearLogger` turns logging off.
#[wasm_bindgen(js_name = barkAttachConsoleLogger)]
pub fn bark_attach_console_logger(maxLevel: Option<Ts<LogLevel>>) -> Result<(), JsError> {
    let max_level = match maxLevel {
        Some(level) => level.to_rust()?,
        None => LogLevel::Info,
    };
    install(Sink::Console, max_level)
}

/// Turn logging off and drop the current logger.
#[wasm_bindgen(js_name = clearLogger)]
pub fn clear_logger() {
    log::set_max_level(LevelFilter::Off);
    SINK.set(None);
}
