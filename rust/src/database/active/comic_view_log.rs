use crate::database::active::ACTIVE_DATABASE;
use crate::database::{create_index, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::QueryOrder;
use sea_orm::QuerySelect;
use sea_orm::{EntityTrait, IntoActiveModel, Set};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "comic_view_log")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub comic_id: i32,
    pub comic_title: String,
    pub comic_authors: String,
    pub comic_status: String,
    pub comic_cover: String,
    pub comic_types: String,
    pub comic_last_update_time: i64,
    pub comic_last_update_chapter_name: String,
    pub chapter_id: i32,
    pub chapter_title: String,
    pub chapter_order: i32,
    pub page_rank: i32,
    pub view_time: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
    if !index_exists(db.deref(), "comic_view_log", "comic_view_log_idx_view_time").await {
        create_index(
            db.deref(),
            "comic_view_log",
            vec!["view_time"],
            "comic_view_log_idx_view_time",
        )
        .await;
    }
}

pub(crate) async fn view_info(mut model: Model) -> anyhow::Result<()> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(model.comic_id.clone())
        .one(db.deref())
        .await?
    {
        let mut in_db = in_db.into_active_model();
        in_db.comic_id = Set(model.comic_id);
        in_db.comic_title = Set(model.comic_title);
        in_db.comic_authors = Set(model.comic_authors);
        in_db.comic_status = Set(model.comic_status);
        in_db.comic_cover = Set(model.comic_cover);
        in_db.comic_types = Set(model.comic_types);
        in_db.comic_last_update_time = Set(model.comic_last_update_time);
        in_db.comic_last_update_chapter_name = Set(model.comic_last_update_chapter_name);
        in_db.view_time = Set(chrono::Local::now().timestamp_millis());
        in_db.update(db.deref()).await?;
    } else {
        model.view_time = chrono::Local::now().timestamp_millis();
        model.into_active_model().insert(db.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn view_page(model: Model) -> anyhow::Result<()> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(model.comic_id.clone())
        .one(db.deref())
        .await?
    {
        let mut in_db = in_db.into_active_model();
        in_db.chapter_id = Set(model.chapter_id);
        in_db.chapter_title = Set(model.chapter_title);
        in_db.chapter_order = Set(model.chapter_order);
        in_db.page_rank = Set(model.page_rank);
        in_db.view_time = Set(chrono::Local::now().timestamp_millis());
        in_db.update(db.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn load_view_logs(page: i64) -> anyhow::Result<Vec<Model>> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    Ok(Entity::find()
        .order_by_desc(Column::ViewTime)
        .offset(page as u64 * 20)
        .limit(20)
        .all(db.deref())
        .await?)
}

pub(crate) async fn view_log_by_comic_id(comic_id: i32) -> anyhow::Result<Option<Model>> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    Ok(Entity::find_by_id(comic_id).one(db.deref()).await?)
}
