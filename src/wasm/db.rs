use std::sync::Arc;

use anyhow::Context;
use bark::persist::adaptor::indexed_db::IndexedDbClient;
use bark::persist::adaptor::StorageAdaptorWrapper;

/// Open (or create) an IndexedDB-backed persister for the wallet.
pub(crate) async fn indexed_db_client(
    db_name: &str,
) -> Result<Arc<StorageAdaptorWrapper<IndexedDbClient>>, crate::error::Error> {
    let idb = IndexedDbClient::open(db_name).await
        .context("failed to open IndexedDB")?;
    Ok(Arc::new(StorageAdaptorWrapper::new(idb)))
}
