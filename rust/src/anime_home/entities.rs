use serde_derive::Deserialize;
use serde_derive::Serialize;
use std::fmt::{Display, Formatter};
use std::num::ParseIntError;

macro_rules! enum_i64 {
    ($name:ident { $($variant:ident($str:expr), )* }) => {
        #[derive(Clone, Copy, Debug, Eq, PartialEq)]
        pub enum $name {
            $($variant,)*
        }

        impl ::serde::Serialize for $name {
            fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
                where S: ::serde::Serializer,
            {
                // 将枚举序列化为字符串。
                serializer.serialize_i64(match *self {
                    $( $name::$variant => $str, )*
                })
            }
        }

        impl<'de> ::serde::Deserialize<'de> for $name {
            fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
                where D: ::serde::Deserializer<'de>,
            {
                struct Visitor;

                impl<'de> ::serde::de::Visitor<'de> for Visitor {
                    type Value = $name;

                    fn expecting(&self, formatter: &mut ::std::fmt::Formatter) -> ::std::fmt::Result {
                        write!(formatter, "a string for {}", stringify!($name))
                    }

                    fn visit_str<E>(self, value: &str) -> Result<$name, E>
                        where E: ::serde::de::Error,
                    {
                        let value = value.parse::<i64>().map_err(|e|serde::de::Error::custom(e))?;
                        match value {
                            $( $str => Ok($name::$variant), )*
                            _ => Err(E::invalid_value(::serde::de::Unexpected::Other(
                                &format!("unknown {} variant: {}", stringify!($name), value)
                            ), &self)),
                        }
                    }
                }

                // 从字符串反序列化枚举。
                deserializer.deserialize_str(Visitor)
            }
        }

        impl $name {
            #[allow(dead_code)]
            pub fn value(&self) -> i64 {
                match *self {
                    $( $name::$variant => $str, )*
                }
            }
            #[allow(dead_code)]
            pub fn from_value(value: i64) -> anyhow::Result<Self> {
                match value {
                    $( $str => Ok($name::$variant), )*
                    value => Err(anyhow::Error::msg(format!("unknown value : {}",value)))
                }
            }
        }

        impl Display for $name {

            fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
                write!(f, "{}", self.value())
            }

        }
    }
}

enum_i64!(ComicType {
    ALL(100),
    ORIGINAL(1),
    TRANSLATED(0),
});

enum_i64!(Sort {
    UPDATE(1),
    POPULARITY(0),
});

// Type 4=漫画，6=新闻，2=专题，1=轻小说
enum_i64!(ObjType {
    COMIC(4),
    NEWS(6),
    SPECIAL(2),
    NOVEL(1),
});

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NewsCategory {
    pub tag_id: i64,
    pub tag_name: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RecommendComicCategory {
    pub category_id: i64,
    pub title: String,
    pub sort: i64,
    pub data: Vec<RecommendComic>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RecommendComic {
    pub cover: String,
    pub title: String,
    pub sub_title: Option<String>,
    #[serde(rename = "type")]
    pub comic_type: Option<i64>,
    pub url: Option<String>,
    pub obj_id: Option<i64>,
    pub status: Option<String>,
    pub id: Option<i64>,
    pub authors: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicInFilter {
    pub id: i64,
    pub title: String,
    #[serde(deserialize_with = "null_string")]
    pub authors: String,
    pub status: String,
    pub cover: String,
    pub types: String,
    #[serde(rename = "last_updatetime")]
    pub last_update_time: i64,
    pub num: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicInSearch {
    #[serde(rename = "_biz")]
    pub biz: String,
    pub addtime: i64,
    #[serde(deserialize_with = "null_string")]
    pub authors: String,
    pub copyright: i64,
    pub cover: String,
    pub hidden: i64,
    pub hot_hits: i64,
    pub last_name: String,
    pub status: i64,
    pub title: String,
    pub types: String,
    pub id: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct V3Response<T> {
    pub code: i32,
    pub msg: String,
    #[serde(default = "default_option")]
    pub data: Option<T>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicCategory {
    pub tag_id: i32,
    pub title: String,
    pub cover: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Comment {
    pub id: i64,
    pub is_passed: i64,
    pub top_status: i64,
    pub is_goods: i64,
    pub upload_images: String,
    pub obj_id: i64,
    pub content: String,
    pub sender_uid: i64,
    pub like_amount: i64,
    pub create_time: i64,
    pub to_uid: i64,
    pub to_comment_id: i64,
    pub origin_comment_id: i64,
    pub reply_amount: i64,
    pub hot_comment_amount: i64,
    pub cover: String,
    pub nickname: String,
    pub avatar_url: String,
    pub sex: i64,
    #[serde(rename = "masterCommentNum")]
    pub master_comment_num: i64,
    #[serde(rename = "masterComment")]
    #[serde(default)]
    pub master_comment: Vec<MasterComment>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MasterComment {
    pub id: i64,
    pub is_passed: i64,
    pub top_status: i64,
    pub is_goods: i64,
    pub upload_images: String,
    pub obj_id: i64,
    pub content: String,
    pub sender_uid: i64,
    pub like_amount: i64,
    pub create_time: i64,
    pub to_uid: i64,
    pub to_comment_id: i64,
    pub origin_comment_id: i64,
    pub reply_amount: i64,
    pub cover: String,
    pub nickname: String,
    pub hot_comment_amount: i64,
    pub sex: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NovelCategory {
    pub tag_id: i64,
    pub title: String,
    pub cover: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NovelInFilter {
    pub cover: String,
    pub name: String,
    #[serde(deserialize_with = "null_string")]
    pub authors: String,
    pub id: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NovelInSearch {
    #[serde(rename = "_biz")]
    pub biz: String,
    pub addtime: i64,
    #[serde(deserialize_with = "null_string")]
    pub authors: String,
    pub copyright: i64,
    pub cover: String,
    pub hidden: i64,
    pub hot_hits: i64,
    pub last_name: String,
    pub status: i64,
    pub title: String,
    pub types: String,
    pub id: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LoginResponse {
    pub result: i64,
    pub msg: String,
    pub data: Option<LoginData>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LoginData {
    pub uid: String,
    pub nickname: String,
    pub dmzj_token: String,
    pub photo: String,
    pub bind_phone: String,
    pub email: String,
    pub passwd: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Subscribed {
    pub name: String,
    pub sub_update: String,
    pub sub_img: String,
    pub sub_uptime: i64,
    pub sub_first_letter: String,
    pub sub_readed: i64, // 0 应该标记"新"字样
    pub id: i64,
    pub status: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ActionResult {
    pub code: i64,
    pub msg: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicFilter {
    pub title: String,
    pub items: Vec<ComicFilterItem>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicFilterItem {
    pub tag_id: i64,
    pub tag_name: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TaskIndex {
    #[serde(default = "default_vec")]
    pub new_person_task: Vec<Task>,
    #[serde(default = "default_vec")]
    pub day_task: Vec<Task>,
    #[serde(default = "default_vec")]
    pub week_task: Vec<Task>,
    pub summations_task: SummationsTask,
    pub day_sign_task: DaySignTask,
    #[serde(deserialize_with = "fuzzy_i64")]
    pub credits_nums: i64,
    #[serde(deserialize_with = "fuzzy_i64")]
    pub silver_nums: i64,
    #[serde(deserialize_with = "fuzzy_i64")]
    pub stars_nums: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Task {
    pub id: i64,
    pub title: String,
    pub con: String,
    pub icon: String,
    pub times: i64,
    pub nums: i64,
    pub source: i64,
    pub type_id: i64,
    pub url: String,
    pub btn: String,
    pub status: i64,
    pub progress: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SummationsTask {
    pub sign_count: i64,
    pub max_sign_count: i64,
    pub task_list: Vec<TaskList>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TaskList {
    pub id: i64,
    pub title: String,
    pub con: String,
    pub icon: String,
    pub times: i64,
    pub nums: i64,
    pub source: i64,
    pub type_id: i64,
    pub url: String,
    pub btn: String,
    pub status: i64,
    pub progress: i64,
    pub icon_checked: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DaySignTask {
    pub current_day: i64,
    pub status: i64,
    pub double_status: i64,
    pub day_list: Vec<DayList>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DayList {
    pub id: i64,
    pub title: String,
    pub icon: String,
    pub icon_checked: String,
    pub type_id: i64,
    pub times: i64,
    pub nums: i64,
    #[serde(deserialize_with = "fuzzy_i64")]
    pub credits_nums: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicReSet {
    #[serde(rename = "comicId")]
    pub comic_id: i64,
    #[serde(rename = "chapterId")]
    pub chapter_id: i64,
    pub page: i64,
    pub time: u64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NovelReSet {
    pub lnovel_id: i64,
    pub volume_id: i64,
    pub chapter_id: i64,
    pub total_num: i64,
    pub time: u64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComicReDown {
    pub uid: i64,
    #[serde(rename = "type")]
    pub type_field: i64,
    pub comic_id: i64,
    pub chapter_id: i64,
    pub record: i64,
    pub viewing_time: i64,
    pub comic_name: String,
    pub cover: String,
    pub chapter_name: String,
}

fn default_option<T>() -> Option<T> {
    None
}

fn null_string<'de, D>(d: D) -> std::result::Result<String, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let value: serde_json::Value = serde::Deserialize::deserialize(d)?;
    if value.is_null() {
        Ok(String::default())
    } else if value.is_string() {
        Ok(value.as_str().unwrap().to_string())
    } else {
        Err(serde::de::Error::custom("type error"))
    }
}

fn fuzzy_i64<'de, D>(d: D) -> std::result::Result<i64, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let value: serde_json::Value = serde::Deserialize::deserialize(d)?;
    if value.is_i64() {
        Ok(value.as_i64().unwrap())
    } else if value.is_string() {
        let str = value.as_str().unwrap();
        let from: std::result::Result<i64, ParseIntError> = std::str::FromStr::from_str(str);
        match from {
            Ok(from) => Ok(from),
            Err(_) => Err(serde::de::Error::custom("parse error")),
        }
    } else {
        Err(serde::de::Error::custom("type error"))
    }
}

fn default_vec<T>() -> Vec<T> {
    vec![]
}
