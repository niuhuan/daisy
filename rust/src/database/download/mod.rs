use crate::database::connect_db;
use once_cell::sync::OnceCell;
use sea_orm::{DatabaseConnection, DbErr, TransactionTrait};
use tokio::sync::Mutex;

pub(crate) mod download_comic;
pub(crate) mod download_comic_chapter;
pub(crate) mod download_comic_page;

pub(crate) static DOWNLOAD_DATABASE: OnceCell<Mutex<DatabaseConnection>> = OnceCell::new();

pub(crate) async fn init() {
    let db = connect_db("download.db").await;
    DOWNLOAD_DATABASE.set(Mutex::new(db)).unwrap();
    // init tables
    download_comic::init().await;
    download_comic_chapter::init().await;
    download_comic_page::init().await;
}

pub(crate) async fn clear_download_comic(id: i32) {
    let db = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    db.transaction::<_, (), DbErr>(|db| {
        Box::pin(async move {
            download_comic::delete_by_comic_id(db, id.clone()).await?;
            download_comic_chapter::delete_by_comic_id(db, id.clone()).await?;
            download_comic_page::delete_by_comic_id(db, id.clone()).await?;
            Ok(())
        })
    })
    .await
    .unwrap();
}
