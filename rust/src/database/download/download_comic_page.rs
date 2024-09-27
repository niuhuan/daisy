use crate::database::download::{download_comic_chapter, DOWNLOAD_DATABASE};
use crate::database::{create_index, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::sea_query::Expr;
use sea_orm::{ConnectionTrait, DeleteResult, QueryOrder};
use sea_orm::{EntityTrait, QuerySelect};
use serde_derive::{Deserialize, Serialize};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "download_comic_page")]
pub struct Model {
    pub comic_id: i32,
    #[sea_orm(primary_key, auto_increment = false)]
    pub chapter_id: i32,
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_index: i32,
    pub url: String,
    pub download_status: i32,
    pub width: i32,
    pub height: i32,
    pub format: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
    if !index_exists(
        db.deref(),
        "download_comic_page",
        "download_comic_page_idx_comic_id",
    )
    .await
    {
        create_index(
            db.deref(),
            "download_comic_page",
            vec!["comic_id"],
            "download_comic_page_idx_comic_id",
        )
        .await;
    }
    if !index_exists(
        db.deref(),
        "download_comic_page",
        "download_comic_page_idx_chapter_id",
    )
    .await
    {
        create_index(
            db.deref(),
            "download_comic_page",
            vec!["chapter_id"],
            "download_comic_page_idx_chapter_id",
        )
        .await;
    }
    if !index_exists(
        db.deref(),
        "download_comic_page",
        "download_comic_page_idx_url",
    )
    .await
    {
        create_index(
            db.deref(),
            "download_comic_page",
            vec!["url"],
            "download_comic_page_idx_url",
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

pub(crate) async fn load_all_need_download_image(
    db: &impl ConnectionTrait,
    chapter: &download_comic_chapter::Model,
) -> Vec<Model> {
    Entity::find()
        .filter(Column::ChapterId.eq(chapter.chapter_id))
        .filter(Column::DownloadStatus.eq(0))
        .all(db)
        .await
        .unwrap()
}

pub(crate) async fn has_not_success_images(db: &impl ConnectionTrait, chapter_id: i32) -> bool {
    Entity::find()
        .filter(Column::ChapterId.eq(chapter_id))
        .filter(Column::DownloadStatus.ne(1))
        .count(db)
        .await
        .unwrap()
        > 0
}

pub(crate) async fn set_download_status(
    db: &impl ConnectionTrait,
    chapter_id: i32,
    image_index: i32,
    status: i32,
    width: u32,
    height: u32,
    format: String,
) {
    Entity::update_many()
        .col_expr(Column::DownloadStatus, Expr::value(status))
        .col_expr(Column::Format, Expr::value(format))
        .col_expr(Column::Width, Expr::value(width))
        .col_expr(Column::Height, Expr::value(height))
        .filter(Column::ChapterId.eq(chapter_id))
        .filter(Column::ImageIndex.eq(image_index))
        .exec(db)
        .await
        .unwrap();
}

// pub(crate) async fn find_by_id(
//     db: &DatabaseConnection,
//     id: i32,
//     image_index: i32,
// ) -> Option<Model> {
//     Entity::find()
//         .filter(Column::ChapterId.eq(id))
//         .filter(Column::ImageIndex.eq(image_index))
//         .limit(1)
//         .one(db)
//         .await
//         .unwrap()
// }

pub(crate) async fn renew_failed(db: &impl ConnectionTrait) {
    Entity::update_many()
        .col_expr(Column::DownloadStatus, Expr::value(0))
        .filter(Column::DownloadStatus.eq(2))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn find_by_chapter_id(db: &impl ConnectionTrait, chapter_id: i32) -> Vec<Model> {
    Entity::find()
        .filter(Column::ChapterId.eq(chapter_id))
        .order_by_asc(Column::ImageIndex)
        .all(db)
        .await
        .unwrap()
}

pub(crate) async fn find_by_url_ok(db: &impl ConnectionTrait, url: String) -> Option<Model> {
    Entity::find()
        .filter(Column::Url.eq(url))
        .filter(Column::DownloadStatus.eq(1))
        .limit(1)
        .one(db)
        .await
        .unwrap()
}
