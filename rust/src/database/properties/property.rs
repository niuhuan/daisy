use crate::database::properties::PROPERTIES_DATABASE;
use crate::database::{create_index, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::IntoActiveModel;
use sea_orm::{EntityTrait, Set};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "property")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub k: String,
    pub v: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init() {
    let db = PROPERTIES_DATABASE.get().unwrap().lock().await;
    create_table_if_not_exists(db.deref(), Entity).await;
    if !index_exists(db.deref(), "property", "property_idx_k").await {
        create_index(db.deref(), "property", vec!["k"], "property_idx_k").await;
    }
}

pub async fn save_property(k: String, v: String) -> anyhow::Result<()> {
    let db = PROPERTIES_DATABASE.get().unwrap().lock().await;
    if let Some(in_db) = Entity::find_by_id(k.clone()).one(db.deref()).await? {
        let mut in_db = in_db.into_active_model();
        in_db.v = Set(v);
        in_db.update(db.deref()).await?;
    } else {
        Model { k, v }
            .into_active_model()
            .insert(db.deref())
            .await?;
    }
    Ok(())
}

pub async fn load_property(k: String) -> anyhow::Result<String> {
    let in_db = Entity::find_by_id(k)
        .one(PROPERTIES_DATABASE.get().unwrap().lock().await.deref())
        .await?;
    Ok(if let Some(in_db) = in_db {
        in_db.v
    } else {
        "".to_owned()
    })
}
