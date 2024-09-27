use crate::database::download::{download_comic, DOWNLOAD_DATABASE};
use crate::database::{create_index, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::sea_query::{Expr, IntoColumnRef, SimpleExpr};
use sea_orm::EntityTrait;
use sea_orm::{ConnectionTrait, DeleteResult, QuerySelect};
use serde_derive::{Deserialize, Serialize};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "download_comic_chapter")]
pub struct Model {
    pub comic_id: i32,
    pub chapter_coll: String,
    #[sea_orm(primary_key, auto_increment = false)]
    pub chapter_id: i32,
    pub chapter_title: String,
    pub update_time: i64,
    pub file_size: i32,
    pub chapter_order: i32,
    pub load_images: i32,
    pub image_count: i32,
    pub image_count_download: i32,
    pub download_status: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
    if !index_exists(
        db.deref(),
        "download_comic_chapter",
        "download_comic_chapter_idx_comic_id",
    )
    .await
    {
        create_index(
            db.deref(),
            "download_comic_chapter",
            vec!["comic_id"],
            "download_comic_chapter_idx_comic_id",
        )
        .await;
    }
}

pub(crate) async fn delete_by_comic_id(
    db: &impl ConnectionTrait,
    album_id: i32,
) -> Result<DeleteResult, DbErr> {
    Entity::delete_many()
        .filter(Column::ComicId.eq(album_id))
        .exec(db)
        .await
}

pub(crate) async fn load_all_need_download_chapter(
    db: &impl ConnectionTrait,
    album: &download_comic::Model,
) -> Vec<Model> {
    Entity::find()
        .filter(Column::ComicId.eq(album.id))
        .filter(Column::DownloadStatus.eq(0))
        .all(db)
        .await
        .unwrap()
}

pub(crate) async fn set_download_status(db: &impl ConnectionTrait, id: i32, status: i32) {
    Entity::update_many()
        .col_expr(Column::DownloadStatus, Expr::value(status))
        .filter(Column::ChapterId.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn save_image_count(db: &impl ConnectionTrait, id: i32, count: i32) {
    Entity::update_many()
        .col_expr(Column::LoadImages, Expr::value(1))
        .col_expr(Column::ImageCount, Expr::value(count))
        .filter(Column::ChapterId.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn has_not_success_chapter(db: &impl ConnectionTrait, album_id: i32) -> bool {
    Entity::find()
        .filter(Column::ComicId.eq(album_id))
        .filter(Column::DownloadStatus.ne(1))
        .count(db)
        .await
        .unwrap()
        > 0
}

pub(crate) async fn find_by_id(db: &impl ConnectionTrait, id: i32) -> Option<Model> {
    Entity::find()
        .filter(Column::ChapterId.eq(id))
        .limit(1)
        .one(db)
        .await
        .unwrap()
}

pub(crate) async fn download_one_image(db: &impl ConnectionTrait, id: i32) {
    Entity::update_many()
        .col_expr(
            Column::ImageCountDownload,
            SimpleExpr::Column(Column::ImageCountDownload.into_column_ref()).add(1),
        )
        .filter(Column::ChapterId.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn list_by_comic_id(db: &impl ConnectionTrait, id: i32) -> Vec<Model> {
    Entity::find()
        .filter(Column::ComicId.eq(id))
        .all(db)
        .await
        .unwrap()
}

pub(crate) async fn renew_failed(db: &impl ConnectionTrait) {
    Entity::update_many()
        .col_expr(Column::DownloadStatus, Expr::value(0))
        .filter(Column::DownloadStatus.eq(2))
        .exec(db)
        .await
        .unwrap();
}
