use crate::database::connect_db;
use once_cell::sync::OnceCell;
use sea_orm::DatabaseConnection;
use tokio::sync::Mutex;

pub(crate) mod property;

pub(crate) static PROPERTIES_DATABASE: OnceCell<Mutex<DatabaseConnection>> = OnceCell::new();

pub(crate) async fn init() {
    let db = connect_db("properties.db").await;
    PROPERTIES_DATABASE.set(Mutex::new(db)).unwrap();
    // init tables
    property::init().await;
}
