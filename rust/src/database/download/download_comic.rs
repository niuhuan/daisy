use crate::database::create_table_if_not_exists;
use crate::database::download::DOWNLOAD_DATABASE;
use flutter_rust_bridge::frb;
use sea_orm::entity::prelude::*;
use sea_orm::sea_query::{Expr, IntoColumnRef, SimpleExpr};
use sea_orm::EntityTrait;
use sea_orm::{ConnectionTrait, DeleteResult};
use sea_orm::{DatabaseTransaction, QuerySelect};
use serde_derive::{Deserialize, Serialize};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "download_comic")]
#[frb(dart_metadata = ("download_comic"))]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: i32,
    pub title: String,
    pub authors: String,
    pub types: String,
    pub status: String,
    pub direction: i32,
    pub is_long: i32,
    pub is_anime_home: i32,
    pub cover: String,
    pub description: String,
    pub copyright: i32,
    pub first_letter: String,
    pub comic_py: String,
    pub cover_download_status: i32,
    pub cover_format: String,
    pub cover_width: u32,
    pub cover_height: u32,
    pub download_status: i32,
    pub image_count: i32,
    pub image_count_download: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
}

pub(crate) async fn load_first_need_delete_comic(db: &DatabaseConnection) -> Option<Model> {
    Entity::find()
        .filter(Column::DownloadStatus.eq(3))
        .limit(1)
        .one(db)
        .await
        .unwrap()
}

pub(crate) async fn delete_by_comic_id(
    db: &impl ConnectionTrait,
    album_id: i32,
) -> Result<DeleteResult, DbErr> {
    Entity::delete_many()
        .filter(Column::Id.eq(album_id))
        .exec(db)
        .await
}

pub(crate) async fn load_first_need_download_comic(db: &DatabaseConnection) -> Option<Model> {
    Entity::find()
        .filter(Column::DownloadStatus.eq(0))
        .limit(1)
        .one(db)
        .await
        .unwrap()
}

pub(crate) async fn set_download_status(db: &impl ConnectionTrait, id: i32, status: i32) {
    Entity::update_many()
        .col_expr(Column::DownloadStatus, Expr::value(status))
        .filter(Column::Id.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn set_cover_download_status(
    db: &impl ConnectionTrait,
    id: i32,
    status: i32,
    format: String,
    width: u32,
    height: u32,
) {
    Entity::update_many()
        .col_expr(Column::CoverDownloadStatus, Expr::value(status))
        .col_expr(Column::CoverFormat, Expr::value(format))
        .col_expr(Column::CoverWidth, Expr::value(width))
        .col_expr(Column::CoverHeight, Expr::value(height))
        .filter(Column::Id.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn find_by_id(db: &impl ConnectionTrait, id: i32) -> Option<Model> {
    Entity::find()
        .filter(Column::Id.eq(id))
        .limit(1)
        .one(db)
        .await
        .unwrap()
}

pub(crate) async fn inc_image_count(db: &DatabaseTransaction, id: i32, count: i32) {
    Entity::update_many()
        .col_expr(
            Column::ImageCount,
            SimpleExpr::Column(Column::ImageCount.into_column_ref()).add(count),
        )
        .filter(Column::Id.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn download_one_image(db: &DatabaseTransaction, id: i32) {
    Entity::update_many()
        .col_expr(
            Column::ImageCountDownload,
            SimpleExpr::Column(Column::ImageCountDownload.into_column_ref()).add(1),
        )
        .filter(Column::Id.eq(id))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn renew_failed(db: &impl ConnectionTrait) {
    Entity::update_many()
        .col_expr(Column::DownloadStatus, Expr::value(0))
        .filter(Column::DownloadStatus.eq(2))
        .exec(db)
        .await
        .unwrap();
}

pub(crate) async fn all(db: &impl ConnectionTrait) -> Vec<Model> {
    Entity::find().all(db).await.unwrap()
}
