use crate::anime_home::{
    ComicCategory, ComicChapter, ComicChapterDetail, ComicDetail, ComicFilter, ComicInFilter,
    ComicInSearch, ComicType, Comment, LoginData, NewsCategory, NewsListItem, NovelCategory,
    NovelDetail, NovelInFilter, NovelInSearch, NovelVolume, ObjType, Sort, Subscribed, TaskIndex,
};
use crate::anime_home::{ComicRankListItem, ComicUpdateListItem};
use crate::database::active::{comic_view_log, novel_view_log};
use crate::database::cache::{image_cache, web_cache};
use crate::database::download::download_comic;
use crate::database::properties::property;
use crate::utils::hash_lock;
use crate::{download_thread, get_image_cache_dir, join_paths, CLIENT};
use anyhow::Result;
use itertools::Itertools;
use lazy_static::lazy_static;
use serde_json::to_string;
use std::time::Duration;
use tokio::sync::Mutex;

pub async fn init(root: String) {
    crate::init_root(&root).await
}

pub fn desktop_root() -> Result<String> {
    #[cfg(target_os = "windows")]
    {
        use anyhow::Context;
        Ok(join_paths(vec![
            std::env::current_exe()?
                .parent()
                .with_context(|| "error")?
                .to_str()
                .with_context(|| "error")?,
            "data",
        ]))
    }
    #[cfg(target_os = "macos")]
    {
        use anyhow::Context;
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![
            home.as_str(),
            "Library",
            "Application Support",
            "niuhuan",
            "daisy",
        ]))
    }
    #[cfg(target_os = "linux")]
    {
        use anyhow::Context;
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![home.as_str(), ".niuhuan", "daisy"]))
    }
    #[cfg(not(any(target_os = "linux", target_os = "windows", target_os = "macos")))]
    panic!("未支持的平台")
}

pub async fn http_get(url: String) -> Result<String> {
    Ok(reqwest::ClientBuilder::new()
        .user_agent("daisy")
        .build()?
        .get(url)
        .send()
        .await?
        .error_for_status()?
        .text()
        .await?)
}

pub async fn save_property(k: String, v: String) -> Result<()> {
    property::save_property(k, v).await
}

pub async fn load_property(k: String) -> Result<String> {
    property::load_property(k).await
}

#[derive(Clone, Debug)]
pub struct LoginInfo {
    pub status: i32,
    pub message: String,
    pub data: Option<LoginData>,
}

lazy_static! {
    static ref PRELOGIN_ED: Mutex<bool> = Mutex::new(false);
    static ref LAST_LOGIN_INFO: Mutex<Option<LoginInfo>> = Mutex::new(None);
}

pub async fn pre_login(nickname: String, passwd: String) -> LoginInfo {
    let mut lock = PRELOGIN_ED.lock().await;
    if *lock {
        return LAST_LOGIN_INFO.lock().await.clone().unwrap();
    }
    *lock = true;
    let info = re_login(nickname, passwd);
    drop(lock);
    info.await
}

pub async fn re_login(nickname: String, passwd: String) -> LoginInfo {
    let client = CLIENT.read().await;
    let login_data = match client.login(nickname, passwd).await {
        Ok(value) => value,
        Err(e) => {
            let err_data = LoginInfo {
                status: 2,
                message: e.to_string(),
                data: None,
            };
            if let Ok(pre_data) = property::load_property("pre_data".to_owned()).await {
                if !pre_data.is_empty() {
                    if let Ok(login_data) = serde_json::from_str::<LoginData>(pre_data.as_str()) {
                        client
                            .set_user_ticket(login_data.uid.clone(), login_data.dmzj_token.clone())
                            .await;
                        // todo // 暂时不确定这个token能用多久 // 也无法验证
                        login_data
                    } else {
                        return err_data;
                    }
                } else {
                    return err_data;
                }
            } else {
                return err_data;
            }
        }
    };
    let _ = property::save_property(
        "pre_data".to_owned(),
        match to_string(&login_data) {
            Ok(value) => value,
            Err(e) => {
                return LoginInfo {
                    status: 2,
                    message: e.to_string(),
                    data: None,
                }
            }
        },
    )
    .await;
    let info = LoginInfo {
        status: 0,
        message: "".to_string(),
        data: Some(login_data),
    };
    let mut last = LAST_LOGIN_INFO.lock().await;
    *last = Some(info.clone());
    info
}

pub struct LocalImage {
    pub abs_path: String,
    pub local_path: String,
    pub image_format: String,
    pub image_width: u32,
    pub image_height: u32,
}

pub(crate) async fn download_image_by_url(url: String) -> Result<(bytes::Bytes, String, u32, u32)> {
    let bytes = reqwest::ClientBuilder::new()
        .user_agent("Dalvik/2.1.0 (Linux; U; Android 12; SM-N9700 Build/SP1A.210812.016);")
        .build()?
        .get(url)
        .header("Referer", "http://images.muwai.com/;")
        .send()
        .await?
        .error_for_status()?
        .bytes()
        .await?;
    let format = image::guess_format(&bytes)?;
    let format = if let Some(format) = format.extensions_str().first() {
        format.to_string()
    } else {
        "".to_string()
    };
    let image = image::load_from_memory(&bytes)?;
    return Ok((bytes, format, image.width(), image.height()));
}

pub async fn load_cache_image(
    url: String,
    useful: String,
    extends_field_int_first: Option<i32>,
    extends_field_int_second: Option<i32>,
    extends_field_int_third: Option<i32>,
) -> Result<LocalImage> {
    let _ = hash_lock(&url).await;
    if let Some(model) = image_cache::load_image_by_url(url.clone()).await? {
        image_cache::update_cache_time(url).await?;
        Ok(LocalImage {
            abs_path: join_paths(vec![
                get_image_cache_dir().as_str(),
                model.local_path.as_str(),
            ]),
            local_path: model.local_path,
            image_format: model.image_format,
            image_width: model.image_width,
            image_height: model.image_height,
        })
    } else if let Some((model, path)) = download_thread::download_ok_pic(url.clone()).await {
        Ok(LocalImage {
            abs_path: path,
            local_path: hex::encode(md5::compute(&url).as_slice()),
            image_format: model.format,
            image_width: model.width as u32,
            image_height: model.height as u32,
        })
    } else {
        let local_path = hex::encode(md5::compute(&url).as_slice());
        let abs_path = join_paths(vec![get_image_cache_dir().as_str(), &local_path]);
        let bytes = reqwest::ClientBuilder::new()
            .user_agent("Dalvik/2.1.0 (Linux; U; Android 12; SM-N9700 Build/SP1A.210812.016);")
            .build()?
            .get(url.clone())
            .header("Referer", "http://images.muwai.com/;")
            .send()
            .await?
            .error_for_status()?
            .bytes()
            .await?;
        let format = image::guess_format(&bytes)?;
        let format = if let Some(format) = format.extensions_str().first() {
            format.to_string()
        } else {
            "".to_string()
        };
        let image = image::load_from_memory(&bytes)?;
        tokio::fs::write(&abs_path, &bytes).await?;
        let model = image_cache::Model {
            url,
            useful,
            extends_field_int_first,
            extends_field_int_second,
            extends_field_int_third,
            local_path,
            cache_time: chrono::Local::now().timestamp_millis(),
            image_format: format,
            image_width: image.width(),
            image_height: image.height(),
        };
        let model = image_cache::insert(model).await?;
        Ok(LocalImage {
            abs_path,
            local_path: model.local_path,
            image_format: model.image_format,
            image_width: model.image_width,
            image_height: model.image_height,
        })
    }
}

pub async fn comic_categories() -> Result<Vec<ComicCategory>> {
    web_cache::cache_first(
        "COMIC_CATEGORIES".to_owned(),
        Duration::from_secs(60 * 60 * 10),
        Box::pin(async { CLIENT.read().await.comic_categories().await }),
    )
    .await
}

pub async fn comic_recommend() -> Result<Vec<ComicInFilter>> {
    let key = "COMIC_RECOMMEND";
    web_cache::cache_first(
        key.to_owned(),
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async { CLIENT.read().await.comic_recommend().await }),
    )
    .await
}

pub async fn comic_update_list(sort: i64, page: i64) -> Result<Vec<ComicUpdateListItem>> {
    let key = format!("COMIC_UPDATE_LIST${}${}", sort, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .comic_update_list(ComicType::from_value(sort)?, page)
                .await
        }),
    )
    .await
}

pub async fn comic_rank_list() -> Result<Vec<ComicRankListItem>> {
    let key = "COMIC_RANK_LIST";
    web_cache::cache_first(
        key.to_owned(),
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async { CLIENT.read().await.comic_rank_list().await }),
    )
    .await
}

pub async fn comic_search(content: String, page: i64) -> Result<Vec<ComicInSearch>> {
    let key = format!("COMIC_SEARCH${}${}", content, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.read().await.comic_search(content, page).await }),
    )
    .await
}

pub async fn comic_classify_filters() -> Result<Vec<ComicFilter>> {
    web_cache::cache_first(
        "COMIC_CLASSIFY_FILTERS".to_owned(),
        Duration::from_secs(60 * 60 * 24),
        Box::pin(async move { CLIENT.read().await.comic_classify_filters().await }),
    )
    .await
}

pub async fn comic_classify_filters_old() -> Result<Vec<ComicFilter>> {
    web_cache::cache_first(
        "COMIC_CLASSIFY_FILTERS".to_owned(),
        Duration::from_secs(60 * 60 * 99999),
        Box::pin(async move { CLIENT.read().await.comic_classify_filters().await }),
    )
    .await
}

pub async fn comic_classify_with_level(
    categories: Vec<i32>,
    sort: i64,
    page: i64,
) -> Result<Vec<ComicInFilter>> {
    let ck = categories.iter().map(|i| format!("{}", i)).join("_");
    let key = format!("COMIC_CLASSIFY_WITH_LEVEL${}${}${}", ck, sort, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .comic_classify_with_level(categories, Sort::from_value(sort)?, page)
                .await
        }),
    )
    .await
}

pub async fn comic_detail(id: i32) -> Result<ComicDetail> {
    let key = format!("COMIC_DETAIL${}", id);
    let comic_detail: ComicDetail = web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.read().await.comic_detail(id).await }),
    )
    .await?;
    comic_view_log::view_info(comic_view_log::Model {
        comic_id: comic_detail.id.clone(),
        comic_title: comic_detail.title.clone(),
        comic_authors: serde_json::to_string(&comic_detail.authors)?,
        comic_status: serde_json::to_string(&comic_detail.status)?,
        comic_cover: comic_detail.cover.clone(),
        comic_types: serde_json::to_string(&comic_detail.types)?,
        comic_last_update_time: comic_detail.last_update_time.clone(),
        comic_last_update_chapter_name: comic_detail.last_update_chapter_name.clone(),
        chapter_id: 0,
        chapter_title: "".to_string(),
        chapter_order: 0,
        page_rank: 0,
        view_time: 0,
    })
    .await?;
    Ok(comic_detail)
}

pub async fn comic_chapter_detail(comic_id: i32, chapter_id: i32) -> Result<ComicChapterDetail> {
    let key = format!("COMIC_CHAPTER_DETAIL_V4${}${}", comic_id, chapter_id);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 10),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .comic_chapter_detail(comic_id, chapter_id)
                .await
        }),
    )
    .await
}

pub async fn comment(obj_type: i64, obj_id: i32, hot: bool, page: i64) -> Result<Vec<Comment>> {
    let key = format!(
        "COMMENT${}${}${}${}",
        obj_type.clone(),
        obj_id.clone(),
        hot.clone(),
        page.clone()
    );
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 / 2),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .comment(ObjType::from_value(obj_type)?, obj_id, hot, page)
                .await
        }),
    )
    .await
}

pub async fn comic_view_page(
    comic_id: i32,
    chapter_id: i32,
    chapter_title: String,
    chapter_order: i32,
    page_rank: i32,
) -> Result<()> {
    comic_view_log::view_page(comic_view_log::Model {
        comic_id,
        comic_title: "".to_string(),
        comic_authors: "".to_string(),
        comic_status: "".to_string(),
        comic_cover: "".to_string(),
        comic_types: "".to_string(),
        comic_last_update_time: 0,
        comic_last_update_chapter_name: "".to_string(),
        chapter_id,
        chapter_title,
        chapter_order,
        page_rank,
        view_time: 0,
    })
    .await
}

pub async fn load_comic_view_logs(page: i64) -> Result<Vec<ComicViewLog>> {
    let db_logs = comic_view_log::load_view_logs(page).await?;
    Ok(db_logs
        .iter()
        .map(|d| map_comic_view_log(d.clone()))
        .collect())
}

pub async fn view_log_by_comic_id(comic_id: i32) -> Result<Option<ComicViewLog>> {
    Ok(
        match comic_view_log::view_log_by_comic_id(comic_id).await? {
            None => None,
            Some(res) => Some(map_comic_view_log(res)),
        },
    )
}

pub async fn news_categories() -> Result<Vec<NewsCategory>> {
    web_cache::cache_first(
        "NEWS_CATEGORIES".to_owned(),
        Duration::from_secs(60 * 60 * 10),
        Box::pin(async { CLIENT.read().await.news_categories().await }),
    )
    .await
}

pub async fn news_list(id: i64, page: i64) -> Result<Vec<NewsListItem>> {
    let key = format!("NEWS_LIST${}${}", id, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.read().await.news_list(id, page).await }),
    )
    .await
}

pub async fn novel_categories() -> Result<Vec<NovelCategory>> {
    web_cache::cache_first(
        "NOVEL_CATEGORIES".to_owned(),
        Duration::from_secs(60 * 60 * 10),
        Box::pin(async { CLIENT.read().await.novel_categories().await }),
    )
    .await
}

pub async fn novel_list(
    category: i32,
    process: i64,
    sort: i64,
    page: i64,
) -> Result<Vec<NovelInFilter>> {
    let key = format!("NOVEL_LIST${}${}${}${}", category, process, sort, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 24),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .novel_list(category, process, Sort::from_value(sort)?, page)
                .await
        }),
    )
    .await
}

pub async fn novel_search(content: String, page: i64) -> Result<Vec<NovelInSearch>> {
    let key = format!("NOVEL_SEARCH${}${}", content, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.read().await.novel_search(content, page).await }),
    )
    .await
}

pub async fn novel_detail(id: i32) -> Result<NovelDetail> {
    let key = format!("NOVEL_DETAIL{}", id);

    let detail = web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.read().await.novel_detail(id).await }),
    )
    .await?;
    novel_view_log::view_info(novel_view_log::Model {
        novel_id: detail.id.clone(),
        novel_title: detail.name.clone(),
        novel_zone: detail.zone.clone(),
        novel_status: detail.status.clone(),
        novel_last_update_volume_name: detail.last_update_volume_name.clone(),
        novel_last_update_chapter_name: detail.last_update_chapter_name.clone(),
        novel_last_update_volume_id: detail.last_update_volume_id.clone(),
        novel_last_update_chapter_id: detail.last_update_chapter_id.clone(),
        novel_last_update_time: detail.last_update_time.clone(),
        novel_cover: detail.cover.clone(),
        novel_hot_hits: detail.hot_hits.clone(),
        novel_introduction: detail.introduction.clone(),
        novel_types: serde_json::to_string(&detail.types)?,
        novel_authors: detail.authors.clone(),
        novel_first_letter: detail.first_letter.clone(),
        novel_subscribe_num: detail.subscribe_num.clone(),
        novel_redis_update_time: detail.last_update_time.clone(),
        volume_id: 0,
        volume_title: "".to_string(),
        volume_order: 0,
        chapter_id: 0,
        chapter_title: "".to_string(),
        chapter_order: 0,
        progress: 0,
        view_time: 0,
    })
    .await?;
    Ok(detail)
}

pub async fn novel_chapters(id: i32) -> Result<Vec<NovelVolume>> {
    let key = format!("NOVEL_CHAPTERS${}", id);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 2),
        Box::pin(async move { CLIENT.read().await.novel_chapters(id).await }),
    )
    .await
}

pub async fn novel_content(volume_id: i32, chapter_id: i32) -> Result<String> {
    let key = format!("NOVEL_CONTENT${}${}", volume_id, chapter_id);
    web_cache::cache_first(
        key,
        Duration::from_secs(60 * 60 * 1000),
        Box::pin(async move {
            CLIENT
                .read()
                .await
                .novel_content(volume_id, chapter_id)
                .await
        }),
    )
    .await
}

pub async fn load_novel_view_logs(page: i64) -> Result<Vec<NovelViewLog>> {
    let db_logs = novel_view_log::load_view_logs(page).await?;
    Ok(db_logs
        .iter()
        .map(|d| map_novel_view_log(d.clone()))
        .collect())
}

pub async fn view_log_by_novel_id(novel_id: i32) -> Result<Option<NovelViewLog>> {
    Ok(
        match novel_view_log::view_log_by_novel_id(novel_id).await? {
            None => None,
            Some(res) => Some(map_novel_view_log(res)),
        },
    )
}

pub async fn novel_view_page(
    novel_id: i32,
    volume_id: i32,
    volume_title: String,
    volume_order: i32,
    chapter_id: i32,
    chapter_title: String,
    chapter_order: i32,
    progress: i64,
) -> Result<()> {
    novel_view_log::view_process(novel_view_log::Model {
        novel_id,
        novel_title: "".to_string(),
        novel_zone: "".to_string(),
        novel_status: "".to_string(),
        novel_last_update_volume_name: "".to_string(),
        novel_last_update_chapter_name: "".to_string(),
        novel_last_update_volume_id: 0,
        novel_last_update_chapter_id: 0,
        novel_last_update_time: 0,
        novel_cover: "".to_string(),
        novel_hot_hits: 0,
        novel_introduction: "".to_string(),
        novel_types: "".to_string(),
        novel_authors: "".to_string(),
        novel_first_letter: "".to_string(),
        novel_subscribe_num: 0,
        novel_redis_update_time: 0,
        volume_id,
        volume_title,
        volume_order,
        chapter_id,
        chapter_title,
        chapter_order,
        progress,
        view_time: 0,
    })
    .await
}

pub async fn auto_clean(time: i64) -> Result<()> {
    let time = chrono::Local::now().timestamp_millis() - time;
    let dir = get_image_cache_dir();
    loop {
        let caches: Vec<image_cache::Model> = image_cache::take_100_cache(time.clone()).await?;
        if caches.is_empty() {
            break;
        }
        for cache in caches {
            let local = join_paths(vec![dir.as_str(), cache.local_path.as_str()]);
            image_cache::delete_by_url(cache.url).await?; // 不管有几条被作用
            let _ = std::fs::remove_file(local); // 不管成功与否
        }
    }
    web_cache::clean_web_cache_by_time(time).await?;
    crate::database::cache::vacuum().await?;
    Ok(())
}

pub struct ComicViewLog {
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

fn map_comic_view_log(res: comic_view_log::Model) -> ComicViewLog {
    ComicViewLog {
        comic_id: res.comic_id,
        comic_title: res.comic_title,
        comic_authors: res.comic_authors,
        comic_status: res.comic_status,
        comic_cover: res.comic_cover,
        comic_types: res.comic_types,
        comic_last_update_time: res.comic_last_update_time,
        comic_last_update_chapter_name: res.comic_last_update_chapter_name,
        chapter_id: res.chapter_id,
        chapter_title: res.chapter_title,
        chapter_order: res.chapter_order,
        page_rank: res.page_rank,
        view_time: res.view_time,
    }
}

pub struct NovelViewLog {
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

fn map_novel_view_log(res: novel_view_log::Model) -> NovelViewLog {
    NovelViewLog {
        novel_id: res.novel_id,
        novel_title: res.novel_title,
        novel_zone: res.novel_zone,
        novel_status: res.novel_status,
        novel_last_update_volume_name: res.novel_last_update_volume_name,
        novel_last_update_chapter_name: res.novel_last_update_chapter_name,
        novel_last_update_volume_id: res.novel_last_update_volume_id,
        novel_last_update_chapter_id: res.novel_last_update_chapter_id,
        novel_last_update_time: res.novel_last_update_time,
        novel_cover: res.novel_cover,
        novel_hot_hits: res.novel_hot_hits,
        novel_introduction: res.novel_introduction,
        novel_types: res.novel_types,
        novel_authors: res.novel_authors,
        novel_first_letter: res.novel_first_letter,
        novel_subscribe_num: res.novel_subscribe_num,
        novel_redis_update_time: res.novel_redis_update_time,
        volume_id: res.volume_id,
        volume_title: res.volume_title,
        volume_order: res.volume_order,
        chapter_id: res.chapter_id,
        chapter_title: res.chapter_title,
        chapter_order: res.chapter_order,
        progress: res.progress,
        view_time: res.view_time,
    }
}

pub async fn subscribe_add(obj_type: String, obj_id: i32) -> Result<()> {
    CLIENT.read().await.subscribe_add(obj_type, obj_id).await
}

pub async fn subscribe_cancel(obj_type: String, obj_id: i32) -> Result<()> {
    CLIENT.read().await.subscribe_cancel(obj_type, obj_id).await
}

pub async fn subscribed_list(sub_type: i64, page: i64) -> Result<Vec<Subscribed>> {
    let key = format!("SUBSCRIBED_LIST${}${}", sub_type, page);
    web_cache::cache_first(
        key,
        Duration::from_secs(15),
        Box::pin(async move { CLIENT.read().await.subscribed_list(sub_type, page).await }),
    )
    .await
}

pub async fn subscribed_obj(sub_type: i64, obj_id: i32) -> Result<bool> {
    let key = format!("SUBSCRIBED_OBJ${}${}", sub_type, obj_id);
    web_cache::cache_first(
        key,
        Duration::from_secs(15),
        Box::pin(async move { CLIENT.read().await.subscribed_obj(sub_type, obj_id).await }),
    )
    .await
}

pub async fn create_download(buff: ComicDetail) -> Result<String> {
    download_thread::create_download(buff).await
}

pub struct DownloadComic {
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

pub async fn all_downloads() -> Result<Vec<DownloadComic>> {
    Ok({
        let model: Vec<download_comic::Model> = download_thread::all_downloads().await;
        model
            .iter()
            .map(|m| m.clone())
            .map(|m| DownloadComic {
                id: m.id,
                title: m.title,
                authors: m.authors,
                types: m.types,
                status: m.status,
                direction: m.direction,
                is_long: m.is_long,
                is_anime_home: m.is_anime_home,
                cover: m.cover,
                description: m.description,
                copyright: m.copyright,
                first_letter: m.first_letter,
                comic_py: m.comic_py,
                cover_download_status: m.cover_download_status,
                cover_format: m.cover_format,
                cover_width: m.cover_width,
                cover_height: m.cover_height,
                download_status: m.download_status,
                image_count: m.image_count,
                image_count_download: m.image_count_download,
            })
            .collect()
    })
}

pub async fn download_comic_chapters_by_comic_id(id: i32) -> Result<Vec<ComicChapter>> {
    download_thread::download_comic_chapters_by_comic_id(id).await
}

pub async fn download_comic_page_by_chapter_id(chapter_id: i32) -> Result<Vec<String>> {
    let mos = download_thread::download_comic_page_by_chapter_id(chapter_id).await;
    Ok(mos.iter().map(|x| x.url.clone()).collect())
}

pub async fn delete_download(id: i32) -> Result<String> {
    download_thread::delete_download(id).await
}

pub async fn renew_all_downloads() -> Result<String> {
    download_thread::renew_all_downloads().await
}

pub async fn load_comic_id(comic_id_string: String) -> Result<i32> {
    CLIENT.read().await.load_comic_id(comic_id_string).await
}

pub async fn task_index() -> Result<TaskIndex> {
    CLIENT.read().await.task_index().await
}

pub async fn task_sign() -> Result<()> {
    CLIENT.read().await.task_sign().await
}
