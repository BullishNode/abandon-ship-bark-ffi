
use std::fmt;

/// The single error type surfaced across the Bark FFI.
///
/// It is a thin, single-variant wrapper around [`anyhow::Error`]. uniffi error
/// types must be enums (callback interfaces require `ConvertError`, which
/// objects cannot provide), and `flat_error` tells uniffi to carry only the
/// `Display` string across the boundary — so the rich anyhow context collapses
/// to a single message on the foreign side.
#[derive(Debug)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Error))]
#[cfg_attr(feature = "uniffi", uniffi(flat_error))]
pub enum Error {
    Inner(anyhow::Error),
}

impl Error {
    /// Wrap any error (or [`anyhow::Error`]) into a [`Error`].
    pub fn new(err: impl Into<anyhow::Error>) -> Self {
        Error::Inner(err.into())
    }

    /// The flattened error message (full anyhow cause chain, single line).
    pub fn message(&self) -> String {
        self.to_string()
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let Error::Inner(e) = self;
        // Alternate form joins the whole anyhow cause chain on one line.
        write!(f, "{:#}", e)
    }
}

impl std::error::Error for Error {}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Inner(e)
    }
}

impl From<&str> for Error {
    fn from(s: &str) -> Self {
        Error::Inner(anyhow::Error::msg(s.to_owned()))
    }
}

impl From<String> for Error {
    fn from(s: String) -> Self {
        Error::Inner(anyhow::Error::msg(s))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preserves_message() {
        let err = Error::from(anyhow::anyhow!("something broke"));
        assert_eq!(err.message(), "something broke");
    }

    #[test]
    fn shows_full_cause_chain() {
        // Display uses the alternate `{:#}` form, which joins the anyhow chain.
        let err = Error::from(anyhow::anyhow!("root cause").context("outer context"));
        let msg = err.message();
        assert!(msg.contains("outer context"), "{msg}");
        assert!(msg.contains("root cause"), "{msg}");
    }
}
