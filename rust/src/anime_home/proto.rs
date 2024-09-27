#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicChapterDetailResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, optional, tag="3")]
    pub data: ::core::option::Option<ComicChapterDetail>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicChapterDetail {
    #[prost(int64, tag="1")]
    pub chapter_id: i64,
    #[prost(int64, tag="2")]
    pub comic_id: i64,
    #[prost(string, tag="3")]
    pub title: ::prost::alloc::string::String,
    #[prost(int32, tag="4")]
    pub chapter_order: i32,
    #[prost(int32, tag="5")]
    pub direction: i32,
    #[prost(string, repeated, tag="6")]
    pub page_url: ::prost::alloc::vec::Vec<::prost::alloc::string::String>,
    #[prost(int32, tag="7")]
    pub picnum: i32,
    #[prost(string, repeated, tag="8")]
    pub page_url_hd: ::prost::alloc::vec::Vec<::prost::alloc::string::String>,
    #[prost(int32, tag="9")]
    pub comment_count: i32,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicDetailResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, optional, tag="3")]
    pub data: ::core::option::Option<ComicDetail>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicDetail {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub title: ::prost::alloc::string::String,
    #[prost(int32, tag="3")]
    pub direction: i32,
    #[prost(int32, tag="4")]
    pub is_long: i32,
    #[prost(int32, tag="5")]
    pub is_anime_home: i32,
    #[prost(string, tag="6")]
    pub cover: ::prost::alloc::string::String,
    #[prost(string, tag="7")]
    pub description: ::prost::alloc::string::String,
    #[prost(int64, tag="8")]
    pub last_update_time: i64,
    #[prost(string, tag="9")]
    pub last_update_chapter_name: ::prost::alloc::string::String,
    #[prost(int32, tag="10")]
    pub copyright: i32,
    #[prost(string, tag="11")]
    pub first_letter: ::prost::alloc::string::String,
    #[prost(string, tag="12")]
    pub comic_py: ::prost::alloc::string::String,
    #[prost(int32, tag="13")]
    pub hidden: i32,
    #[prost(int32, tag="14")]
    pub hot_num: i32,
    #[prost(int32, tag="15")]
    pub hit_num: i32,
    #[prost(int32, tag="16")]
    pub uid: i32,
    #[prost(int32, tag="17")]
    pub is_lock: i32,
    #[prost(int32, tag="18")]
    pub last_update_chapter_id: i32,
    #[prost(message, repeated, tag="19")]
    pub types: ::prost::alloc::vec::Vec<Item>,
    #[prost(message, repeated, tag="20")]
    pub status: ::prost::alloc::vec::Vec<Item>,
    #[prost(message, repeated, tag="21")]
    pub authors: ::prost::alloc::vec::Vec<Item>,
    #[prost(int32, tag="22")]
    pub subscribe_num: i32,
    #[prost(message, repeated, tag="23")]
    pub chapters: ::prost::alloc::vec::Vec<ComicChapter>,
    #[prost(int32, tag="24")]
    pub is_need_login: i32,
    ///object UrlLinks=25;
    ///
    ///object DhUrlLinks=27;
    #[prost(int32, tag="26")]
    pub is_hide_chapter: i32,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct Item {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub title: ::prost::alloc::string::String,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicChapter {
    #[prost(string, tag="1")]
    pub title: ::prost::alloc::string::String,
    #[prost(message, repeated, tag="2")]
    pub data: ::prost::alloc::vec::Vec<ComicChapterInfo>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicChapterInfo {
    #[prost(int32, tag="1")]
    pub chapter_id: i32,
    #[prost(string, tag="2")]
    pub chapter_title: ::prost::alloc::string::String,
    #[prost(int64, tag="3")]
    pub update_time: i64,
    #[prost(int32, tag="4")]
    pub file_size: i32,
    #[prost(int32, tag="5")]
    pub chapter_order: i32,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicRankListResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, repeated, tag="3")]
    pub data: ::prost::alloc::vec::Vec<ComicRankListItem>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicRankListItem {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub title: ::prost::alloc::string::String,
    #[prost(string, tag="3")]
    pub authors: ::prost::alloc::string::String,
    #[prost(string, tag="4")]
    pub status: ::prost::alloc::string::String,
    #[prost(string, tag="5")]
    pub cover: ::prost::alloc::string::String,
    #[prost(string, tag="6")]
    pub types: ::prost::alloc::string::String,
    #[prost(int64, tag="7")]
    pub last_update_time: i64,
    #[prost(string, tag="8")]
    pub last_update_chapter_name: ::prost::alloc::string::String,
    #[prost(string, tag="9")]
    pub comic_py: ::prost::alloc::string::String,
    #[prost(int32, tag="10")]
    pub num: i32,
    #[prost(int32, tag="11")]
    pub tag_id: i32,
    #[prost(string, tag="12")]
    pub chapter_name: ::prost::alloc::string::String,
    #[prost(int32, tag="13")]
    pub chapter_id: i32,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicUpdateListResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, repeated, tag="3")]
    pub data: ::prost::alloc::vec::Vec<ComicUpdateListItem>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct ComicUpdateListItem {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub title: ::prost::alloc::string::String,
    #[prost(bool, tag="3")]
    pub is_long: bool,
    #[prost(string, tag="4")]
    pub authors: ::prost::alloc::string::String,
    #[prost(string, tag="5")]
    pub types: ::prost::alloc::string::String,
    #[prost(string, tag="6")]
    pub cover: ::prost::alloc::string::String,
    #[prost(string, tag="7")]
    pub status: ::prost::alloc::string::String,
    #[prost(string, tag="8")]
    pub last_update_chapter_name: ::prost::alloc::string::String,
    #[prost(int32, tag="9")]
    pub last_update_chapter_id: i32,
    #[prost(int64, tag="10")]
    pub last_update_time: i64,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NewsListResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, repeated, tag="3")]
    pub data: ::prost::alloc::vec::Vec<NewsListItem>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NewsListItem {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub title: ::prost::alloc::string::String,
    #[prost(string, tag="3")]
    pub from_name: ::prost::alloc::string::String,
    #[prost(string, tag="4")]
    pub from_url: ::prost::alloc::string::String,
    #[prost(int64, tag="5")]
    pub create_time: i64,
    #[prost(int32, tag="6")]
    pub is_foreign: i32,
    #[prost(string, tag="7")]
    pub foreign_url: ::prost::alloc::string::String,
    #[prost(string, tag="8")]
    pub intro: ::prost::alloc::string::String,
    #[prost(int32, tag="9")]
    pub author_id: i32,
    #[prost(int32, tag="10")]
    pub status: i32,
    #[prost(string, tag="11")]
    pub row_pic_url: ::prost::alloc::string::String,
    #[prost(string, tag="12")]
    pub col_pic_url: ::prost::alloc::string::String,
    #[prost(int32, tag="13")]
    pub q_chat_show: i32,
    #[prost(string, tag="14")]
    pub page_url: ::prost::alloc::string::String,
    #[prost(int32, tag="15")]
    pub comment_amount: i32,
    #[prost(int32, tag="16")]
    pub author_uid: i32,
    #[prost(string, tag="17")]
    pub cover: ::prost::alloc::string::String,
    #[prost(string, tag="18")]
    pub nickname: ::prost::alloc::string::String,
    #[prost(int32, tag="19")]
    pub mood_amount: i32,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NovelChaptersResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, repeated, tag="3")]
    pub data: ::prost::alloc::vec::Vec<NovelVolume>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NovelVolume {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub title: ::prost::alloc::string::String,
    #[prost(int32, tag="3")]
    pub rank: i32,
    #[prost(message, repeated, tag="4")]
    pub chapters: ::prost::alloc::vec::Vec<NovelChapter>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NovelChapter {
    #[prost(int32, tag="1")]
    pub chapter_id: i32,
    #[prost(string, tag="2")]
    pub chapter_name: ::prost::alloc::string::String,
    #[prost(int32, tag="3")]
    pub chapter_order: i32,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NovelDetailResponse {
    #[prost(int32, tag="1")]
    pub err_number: i32,
    #[prost(string, tag="2")]
    pub err_message: ::prost::alloc::string::String,
    #[prost(message, optional, tag="3")]
    pub data: ::core::option::Option<NovelDetail>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NovelDetail {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(string, tag="2")]
    pub name: ::prost::alloc::string::String,
    #[prost(string, tag="3")]
    pub zone: ::prost::alloc::string::String,
    #[prost(string, tag="4")]
    pub status: ::prost::alloc::string::String,
    #[prost(string, tag="5")]
    pub last_update_volume_name: ::prost::alloc::string::String,
    #[prost(string, tag="6")]
    pub last_update_chapter_name: ::prost::alloc::string::String,
    #[prost(int32, tag="7")]
    pub last_update_volume_id: i32,
    #[prost(int32, tag="8")]
    pub last_update_chapter_id: i32,
    #[prost(int64, tag="9")]
    pub last_update_time: i64,
    #[prost(string, tag="10")]
    pub cover: ::prost::alloc::string::String,
    #[prost(int32, tag="11")]
    pub hot_hits: i32,
    #[prost(string, tag="12")]
    pub introduction: ::prost::alloc::string::String,
    #[prost(string, repeated, tag="13")]
    pub types: ::prost::alloc::vec::Vec<::prost::alloc::string::String>,
    #[prost(string, tag="14")]
    pub authors: ::prost::alloc::string::String,
    #[prost(string, tag="15")]
    pub first_letter: ::prost::alloc::string::String,
    #[prost(int32, tag="16")]
    pub subscribe_num: i32,
    #[prost(int64, tag="17")]
    pub redis_update_time: i64,
    #[prost(message, repeated, tag="18")]
    pub volumes: ::prost::alloc::vec::Vec<NovelVolumeInfo>,
}
#[derive(::serde_derive::Serialize, ::serde_derive::Deserialize)]
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct NovelVolumeInfo {
    #[prost(int32, tag="1")]
    pub id: i32,
    #[prost(int32, tag="2")]
    pub novel_id: i32,
    #[prost(string, tag="3")]
    pub title: ::prost::alloc::string::String,
    #[prost(int32, tag="4")]
    pub rank: i32,
    #[prost(int64, tag="5")]
    pub add_time: i64,
    #[prost(int32, tag="6")]
    pub chapters_count: i32,
}
