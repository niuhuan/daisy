use crate::database::active::ACTIVE_DATABASE;
use crate::database::{create_index, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::QueryOrder;
use sea_orm::QuerySelect;
use sea_orm::{EntityTrait, IntoActiveModel, Set};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "novel_view_log")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub novel_id: i32,
    pub novel_title: String,
    pub novel_zone: String,
    pub novel_status: String,
    pub novel_last_update_volume_name: String,
    pub novel_last_update_chapter_name: String,
    pub novel_last_update_volume_id: i32,
    pub novel_last_update_chapter_id: i32,
    pub novel_last_update_time: i64,
    pub novel_cover: String,
    pub novel_hot_hits: i32,
    pub novel_introduction: String,
    pub novel_types: String,
    pub novel_authors: String,
    pub novel_first_letter: String,
    pub novel_subscribe_num: i32,
    pub novel_redis_update_time: i64,
    pub volume_id: i32,
    pub volume_title: String,
    pub volume_order: i32,
    pub chapter_id: i32,
    pub chapter_title: String,
    pub chapter_order: i32,
    pub progress: i64,
    pub view_time: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
    if !index_exists(db.deref(), "novel_view_log", "novel_view_log_idx_view_time").await {
        create_index(
            db.deref(),
            "novel_view_log",
            vec!["view_time"],
            "novel_view_log_idx_view_time",
        )
        .await;
    }
}

pub(crate) async fn view_info(mut model: Model) -> anyhow::Result<()> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(model.novel_id.clone())
        .one(db.deref())
        .await?
    {
        let mut in_db = in_db.into_active_model();
        in_db.novel_id = Set(model.novel_id);
        in_db.novel_title = Set(model.novel_title);
        in_db.novel_authors = Set(model.novel_authors);
        in_db.novel_zone = Set(model.novel_zone);
        in_db.novel_status = Set(model.novel_status);
        in_db.novel_cover = Set(model.novel_cover);
        in_db.novel_last_update_volume_name = Set(model.novel_last_update_volume_name);
        in_db.novel_last_update_chapter_name = Set(model.novel_last_update_chapter_name);
        in_db.novel_last_update_volume_id = Set(model.novel_last_update_volume_id);
        in_db.novel_last_update_chapter_id = Set(model.novel_last_update_chapter_id);
        in_db.novel_last_update_time = Set(model.novel_last_update_time);
        in_db.novel_hot_hits = Set(model.novel_hot_hits);
        in_db.novel_introduction = Set(model.novel_introduction);
        in_db.novel_types = Set(model.novel_types);
        in_db.novel_first_letter = Set(model.novel_first_letter);
        in_db.novel_subscribe_num = Set(model.novel_subscribe_num);
        in_db.novel_redis_update_time = Set(model.novel_redis_update_time);
        in_db.view_time = Set(chrono::Local::now().timestamp_millis());
        in_db.update(db.deref()).await?;
    } else {
        model.view_time = chrono::Local::now().timestamp_millis();
        model.into_active_model().insert(db.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn view_process(model: Model) -> anyhow::Result<()> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(model.novel_id.clone())
        .one(db.deref())
        .await?
    {
        let mut in_db = in_db.into_active_model();
        in_db.volume_id = Set(model.volume_id);
        in_db.volume_title = Set(model.volume_title);
        in_db.volume_order = Set(model.volume_order);
        in_db.chapter_id = Set(model.chapter_id);
        in_db.chapter_title = Set(model.chapter_title);
        in_db.chapter_order = Set(model.chapter_order);
        in_db.progress = Set(model.progress);
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

pub(crate) async fn view_log_by_novel_id(novel_id: i32) -> anyhow::Result<Option<Model>> {
    let db = ACTIVE_DATABASE.get().unwrap().lock().await;
    Ok(Entity::find_by_id(novel_id).one(db.deref()).await?)
}
