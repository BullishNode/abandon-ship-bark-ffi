use std::sync::Arc;

use bark::persist::adaptor::indexed_db::IndexedDbClient;
use bark::persist::adaptor::StorageAdaptorWrapper;

use crate::error::BarkError;

/// Open (or create) an IndexedDB-backed persister for the wallet.
pub async fn indexed_db_client(
    db_name: &str,
) -> Result<Arc<StorageAdaptorWrapper<IndexedDbClient>>, BarkError> {
    let idb = IndexedDbClient::open(db_name)
        .await
        .map_err(|e| BarkError::Database { error_message: e.to_string() })?;
    Ok(Arc::new(StorageAdaptorWrapper::new(idb)))
}
