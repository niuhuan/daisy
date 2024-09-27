use crate::database::cache::CACHE_DATABASE;
use crate::database::{create_index, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::sea_query::Expr;
use sea_orm::EntityTrait;
use sea_orm::IntoActiveModel;
use std::future::Future;
use std::ops::Deref;
use std::pin::Pin;
use std::time::Duration;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "web_cache")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub cache_key: String,
    pub cache_content: String,
    pub cache_time: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let gdb = CACHE_DATABASE.get().unwrap().lock().await;
    let db = gdb.deref();
    create_table_if_not_exists(db, Entity).await;
    if !index_exists(db, "web_cache", "web_cache_idx_cache_time").await {
        create_index(
            db,
            "web_cache",
            vec!["cache_time"],
            "web_cache_idx_cache_time",
        )
            .await;
    }
}

pub(crate) async fn cache_first<T: for<'de> serde::Deserialize<'de> + serde::Serialize>(
    key: String,
    expire: Duration,
    pin: Pin<Box<dyn Future<Output=anyhow::Result<T>> + Send>>,
) -> anyhow::Result<T> {
    let time = chrono::Local::now().timestamp_millis();
    let db = CACHE_DATABASE.get().unwrap().lock().await;
    let in_db = Entity::find_by_id(key.clone()).one(db.deref()).await?;
    if let Some(ref model) = in_db {
        if time < (model.cache_time + expire.as_millis() as i64) {
            return Ok(serde_json::from_str(&model.cache_content)?);
        }
    };
    let t = pin.await?;
    let content = serde_json::to_string(&t)?;
    if let Some(_) = in_db {
        Entity::update_many()
            .filter(Column::CacheKey.eq(key.clone()))
            .col_expr(Column::CacheTime, Expr::value(time.clone()))
            .col_expr(Column::CacheContent, Expr::value(content.clone()))
            .exec(db.deref())
            .await?;
    } else {
        Model {
            cache_key: key,
            cache_content: content,
            cache_time: time,
        }
            .into_active_model()
            .insert(db.deref())
            .await?;
    }
    Ok(t)
}

pub(crate) async fn clean_web_cache_by_time(time: i64) -> anyhow::Result<()> {
    Entity::delete_many()
        .filter(Column::CacheTime.lt(time))
        .exec(CACHE_DATABASE.get().unwrap().lock().await.deref())
        .await?;
    Ok(())
}
