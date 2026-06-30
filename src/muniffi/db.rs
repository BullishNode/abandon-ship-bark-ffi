
use std::path::PathBuf;
use std::sync::Arc;

use anyhow::Context;
use log::info;

use bark::persist::sqlite::SqliteClient;


/// Open a SQLite database connection.
///
/// # Arguments
///
/// * `datadir` - The directory containing the wallet data
///
/// # Returns
///
/// An `Arc<SqliteClient>` that can be shared across multiple wallet instances.
pub fn open_sqlite_db(datadir: &str) -> anyhow::Result<Arc<SqliteClient>> {
    let datadir_path = PathBuf::from(datadir);

    // Ensure the directory exists
    std::fs::create_dir_all(&datadir_path)
        .with_context(|| format!("Failed to create datadir {}", datadir_path.display(),))?;

    let db_path = datadir_path.join("bark.sqlite");

    // Open new connection
    info!("[DB] Opening new connection for {}", db_path.display());
    let db = Arc::new(
        SqliteClient::open(&db_path)
            .with_context(|| format!("Failed to open database at {}", db_path.display(),))?,
    );

    Ok(db)
}
