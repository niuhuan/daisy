use crate::database::connect_db;
use once_cell::sync::OnceCell;
use sea_orm::{ConnectionTrait, DatabaseConnection, ExecResult, Statement};
use tokio::sync::Mutex;

pub(crate) mod image_cache;
pub(crate) mod web_cache;

pub(crate) static CACHE_DATABASE: OnceCell<Mutex<DatabaseConnection>> = OnceCell::new();

pub(crate) async fn init() {
    let db = connect_db("cache.db").await;
    CACHE_DATABASE.set(Mutex::new(db)).unwrap();
    // init tables
    image_cache::init().await;
    web_cache::init().await;
}

pub(crate) async fn vacuum() -> anyhow::Result<()> {
    let db = CACHE_DATABASE.get().unwrap().lock().await;
    let backend = db.get_database_backend();
    let _: ExecResult = db
        .execute(Statement::from_string(backend, "VACUUM".to_owned()))
        .await?;
    Ok(())
}
