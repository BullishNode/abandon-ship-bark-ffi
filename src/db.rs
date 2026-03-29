use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, Mutex, Weak};

use bark::persist::sqlite::SqliteClient;

/// Global cache of database connections keyed by database path.
/// Uses weak references to allow connections to be dropped when no longer in use.
static DB_CACHE: Lazy<Mutex<HashMap<PathBuf, Weak<SqliteClient>>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

/// Get or open a SQLite database connection.
///
/// This function maintains a cache of database connections per path to ensure
/// that multiple wallet instances in the same process share the same underlying
/// database connection. This prevents SQLite locking issues and ensures data
/// consistency.
///
/// # Arguments
///
/// * `datadir` - The directory containing the wallet data
///
/// # Returns
///
/// An `Arc<SqliteClient>` that can be shared across multiple wallet instances.
pub fn get_or_open_db(datadir: &str) -> anyhow::Result<Arc<SqliteClient>> {
    let datadir_path = PathBuf::from(datadir);

    // Ensure the directory exists
    std::fs::create_dir_all(&datadir_path).map_err(|e| {
        anyhow::anyhow!("Failed to create datadir {}: {}", datadir_path.display(), e)
    })?;

    let db_path = datadir_path.join("bark.sqlite");

    let mut cache = DB_CACHE.lock().unwrap();

    // Try to reuse existing connection
    if let Some(weak_db) = cache.get(&db_path) {
        if let Some(db) = weak_db.upgrade() {
            eprintln!("[DB] Reusing existing connection for {}", db_path.display());
            return Ok(db);
        }
    }

    // Open new connection
    eprintln!("[DB] Opening new connection for {}", db_path.display());
    let db =
        Arc::new(SqliteClient::open(&db_path).map_err(|e| {
            anyhow::anyhow!("Failed to open database at {}: {}", db_path.display(), e)
        })?);

    // Store weak reference in cache
    cache.insert(db_path, Arc::downgrade(&db));

    Ok(db)
}
