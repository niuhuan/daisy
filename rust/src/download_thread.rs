use std::collections::VecDeque;
use std::fs::create_dir_all;
use std::ops::Deref;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;

use crate::Result;
use itertools::Itertools;
use lazy_static::lazy_static;
use sea_orm::ActiveModelTrait;
use sea_orm::ActiveValue::Set;
use sea_orm::DbErr;
use sea_orm::TransactionTrait;
use serde_json::to_string;
use tokio::sync::Mutex;
use tokio::time::sleep;

use crate::anime_home::{ComicChapter, ComicChapterInfo, ComicDetail};
use crate::api::bridge::download_image_by_url;
use crate::database::download::{
    download_comic, download_comic_chapter, download_comic_page, DOWNLOAD_DATABASE,
};
use crate::local::join_paths;
use crate::{CLIENT, DOWNLOAD_DIR};

lazy_static! {
    pub(crate) static ref RESTART_FLAG: Mutex<bool> = Mutex::new(false);
    pub(crate) static ref DOWNLOAD_AND_EXPORT_TO: Mutex<String> = Mutex::new("".to_owned());
    pub(crate) static ref DOWNLOAD_THREAD: Mutex<i32> = Mutex::new(3);
}

async fn need_restart() -> bool {
    *RESTART_FLAG.lock().await.deref()
}

//
pub(crate) async fn start_download() {
    loop {
        // 检测重启flag
        let mut restart_flag = RESTART_FLAG.lock().await;
        if *restart_flag.deref() {
            *restart_flag = false;
        }
        drop(restart_flag);
        // 删除
        let mut need_delete = load_first_need_delete_comic().await;
        while need_delete.is_some() {
            delete_file_and_database(need_delete.unwrap()).await;
            need_delete = load_first_need_delete_comic().await;
        }
        // 下载
        match load_first_need_download_comic().await {
            None => sleep(Duration::new(3, 0)).await,
            Some(album) => {
                println!("LOAD ALBUM : {}", album.id);
                let album_dir = join_paths(vec![
                    DOWNLOAD_DIR.get().unwrap().as_str(),
                    format!("{}", album.id).as_str(),
                ]);
                create_dir_if_not_exists(&album_dir);
                download_cover(&album_dir, &album).await;
                if need_restart().await {
                    continue;
                }
                let chapters = load_chapters(&album).await;
                for chapter in &chapters {
                    let chapter_dir =
                        join_paths(vec![&album_dir, &format!("{}", chapter.chapter_id)]);
                    create_dir_if_not_exists(&chapter_dir);

                    let images = Arc::new(Mutex::new(VecDeque::from(
                        load_all_need_download_image(&chapter).await,
                    )));

                    let dtl = DOWNLOAD_THREAD.lock().await;
                    let d = *dtl;
                    drop(dtl);
                    let _ = futures_util::future::join_all(
                        num_iter::range(0, d)
                            .map(|_| download_line(&chapter_dir, images.clone()))
                            .collect_vec(),
                    )
                    .await;

                    if need_restart().await {
                        break;
                    }

                    println!("PRE SUMMARY chapter : {}", chapter.chapter_id);
                    summary_chapter(chapter.chapter_id).await;
                }
                if need_restart().await {
                    continue;
                }
                println!("PRE SUMMARY album : {}", album.id);
                summary_album(album.id).await;
            }
        };
    }
}

pub(crate) async fn delete_file_and_database(album: download_comic::Model) {
    println!("DELETE ALBUM : {}", album.id);
    let album_dir = join_paths(vec![
        DOWNLOAD_DIR.get().unwrap().as_str(),
        format!("{}", album.id).as_str(),
    ]);
    if Path::new(&album_dir).exists() {
        let _ = tokio::fs::remove_dir_all(&album_dir).await;
    }
    crate::database::download::clear_download_comic(album.id).await;
}

async fn download_cover(album_dir: &str, album: &download_comic::Model) {
    if album.cover_download_status == 0 {
        match download_image_by_url(album.cover.clone()).await {
            Err(_) => {
                download_comic::set_cover_download_status(
                    DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
                    album.id,
                    2,
                    "".to_owned(),
                    0,
                    0,
                )
                .await;
            }
            Ok((data, format, width, height)) => {
                tokio::fs::write(&join_paths(vec![album_dir, "cover"]), data)
                    .await
                    .unwrap();
                download_comic::set_cover_download_status(
                    DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
                    album.id,
                    1,
                    format,
                    width,
                    height,
                )
                .await;
            }
        }
    }
}

async fn summary_chapter(chapter_id: i32) {
    let lock = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    match download_comic_page::has_not_success_images(lock.deref(), chapter_id).await {
        true => {
            println!("SUMMARY CHAPTER : {} : FAIL", chapter_id);
            download_comic_chapter::set_download_status(lock.deref(), chapter_id, 2).await
        }
        false => {
            println!("SUMMARY CHAPTER : {} : SUCCESS", chapter_id);
            download_comic_chapter::set_download_status(lock.deref(), chapter_id, 1).await
        }
    };
}

async fn summary_album(album_id: i32) {
    // todo check album cover
    let lock = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    match download_comic_chapter::has_not_success_chapter(lock.deref(), album_id).await {
        true => {
            println!("SUMMARY ALBUM : {} : FAIL", album_id);
            download_comic::set_download_status(lock.deref(), album_id, 2).await
        }
        false => {
            println!("SUMMARY ALBUM : {} : SUCCESS", album_id);
            download_comic::set_download_status(lock.deref(), album_id, 1).await
        }
    };
}

async fn download_line(
    chapter_dir: &str,
    deque: Arc<Mutex<VecDeque<download_comic_page::Model>>>,
) -> Result<()> {
    loop {
        if need_restart().await {
            break;
        }
        let mut model_stream = deque.lock().await;
        let model = model_stream.pop_back();
        drop(model_stream);
        if let Some(image) = model {
            let _ = download_image(chapter_dir.to_string(), image).await;
        } else {
            break;
        }
    }
    Ok(())
}

async fn download_image(chapter_dir: String, image: download_comic_page::Model) {
    match download_image_by_url(image.url.clone()).await {
        Err(err) => {
            println!("ERR : {}", err.to_string());
            download_comic_page::set_download_status(
                DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
                image.chapter_id,
                image.image_index,
                2,
                0,
                0,
                "".to_owned(),
            )
            .await
        }
        Ok((buff, format, width, height)) => {
            {
                let exp = DOWNLOAD_AND_EXPORT_TO.lock().await;
                if !exp.is_empty() {
                    let dir = join_paths(vec![
                        exp.as_str(),
                        image.comic_id.to_string().as_str(),
                        image.chapter_id.to_string().as_str(),
                    ]);
                    if !Path::new(&dir).exists() {
                        let _ = tokio::fs::create_dir_all(&dir).await;
                    }
                    drop(exp);
                    let path = join_paths(vec![&dir, &image.image_index.to_string()]);
                    let _ = tokio::fs::write(path, buff.clone()).await;
                }
            }
            std::fs::write(
                join_paths(vec![
                    chapter_dir.as_str(),
                    format!("{}", image.image_index).as_str(),
                ]),
                buff.clone(),
            )
            .unwrap();
            DOWNLOAD_DATABASE
                .get()
                .unwrap()
                .lock()
                .await
                .transaction::<_, (), DbErr>(|db| {
                    Box::pin(async move {
                        download_comic_page::set_download_status(
                            db,
                            image.chapter_id,
                            image.image_index,
                            1,
                            width,
                            height,
                            format,
                        )
                        .await;
                        download_comic_chapter::download_one_image(db, image.chapter_id).await;
                        download_comic::download_one_image(db, image.comic_id).await;
                        Ok(())
                    })
                })
                .await
                .unwrap();
        }
    }
}

fn create_dir_if_not_exists<P: AsRef<Path>>(path: P) {
    if !path.as_ref().exists() {
        create_dir_all(path).unwrap();
    }
}

async fn load_chapters(album: &download_comic::Model) -> Vec<download_comic_chapter::Model> {
    let album = album.clone();
    let chapters = load_all_need_download_chapter(&album).await;
    for chapter in &chapters {
        if chapter.load_images == 0 {
            let chapter = chapter.clone();
            match CLIENT
                .read()
                .await
                .comic_chapter_detail(chapter.comic_id, chapter.chapter_id)
                .await
            {
                Err(_) => {
                    download_comic_chapter::set_download_status(
                        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
                        chapter.chapter_id,
                        1,
                    )
                    .await
                }
                Ok(load) => {
                    // 设置已经下载图片和图片个数
                    DOWNLOAD_DATABASE
                        .get()
                        .unwrap()
                        .lock()
                        .await
                        .transaction::<_, (), DbErr>(|db| {
                            Box::pin(async move {
                                let images = &load.page_url;
                                for idx in 0..images.len() {
                                    let image = &images[idx];
                                    download_comic_page::ActiveModel {
                                        comic_id: Set(chapter.comic_id),
                                        chapter_id: Set(chapter.chapter_id),
                                        image_index: Set(idx.try_into().unwrap()),
                                        url: Set(image.to_string()),
                                        download_status: Set(0),
                                        width: Set(0),
                                        height: Set(0),
                                        format: Set(String::default()),
                                    }
                                    .insert(db)
                                    .await
                                    .unwrap();
                                }
                                download_comic_chapter::save_image_count(
                                    db,
                                    chapter.chapter_id,
                                    images.len().try_into().unwrap(),
                                )
                                .await;
                                download_comic::inc_image_count(
                                    db,
                                    album.id,
                                    images.len().try_into().unwrap(),
                                )
                                .await;
                                Ok(())
                            })
                        })
                        .await
                        .unwrap();
                }
            };
        }
    }
    load_all_need_download_chapter(&album).await
}

async fn load_first_need_download_comic() -> Option<download_comic::Model> {
    return download_comic::load_first_need_download_comic(
        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
    )
    .await;
}

async fn load_first_need_delete_comic() -> Option<download_comic::Model> {
    return download_comic::load_first_need_delete_comic(
        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
    )
    .await;
}

async fn load_all_need_download_chapter(
    album: &download_comic::Model,
) -> Vec<download_comic_chapter::Model> {
    download_comic_chapter::load_all_need_download_chapter(
        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
        &album,
    )
    .await
}

async fn load_all_need_download_image(
    chapter: &download_comic_chapter::Model,
) -> Vec<download_comic_page::Model> {
    download_comic_page::load_all_need_download_image(
        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
        &chapter,
    )
    .await
}

pub(crate) async fn create_download(create: ComicDetail) -> Result<String> {
    DOWNLOAD_DATABASE
        .get()
        .unwrap()
        .lock()
        .await
        .transaction::<_, (), DbErr>(|db| {
            Box::pin(async move {
                let album = match download_comic::find_by_id(db, create.id).await {
                    None => {
                        download_comic::ActiveModel {
                            id: Set(create.id),
                            title: Set(create.title),
                            authors: Set(to_string(&create.authors).unwrap()),
                            types: Set(to_string(&create.types).unwrap()),
                            status: Set(to_string(&create.status).unwrap()),
                            direction: Set(create.direction),
                            is_long: Set(create.is_long),
                            is_anime_home: Set(create.is_anime_home),
                            cover: Set(create.cover),
                            description: Set(create.description),
                            copyright: Set(create.copyright),
                            first_letter: Set(create.first_letter),
                            comic_py: Set(create.comic_py),
                            cover_download_status: Set(0),
                            cover_format: Set(String::default()),
                            cover_width: Set(0),
                            cover_height: Set(0),
                            download_status: Set(0),
                            image_count: Set(0),
                            image_count_download: Set(0),
                        }
                        .insert(db)
                        .await?
                    }
                    Some(model) => {
                        download_comic::set_download_status(db, model.id, 0).await;
                        model
                    }
                };
                for chapter_coll in &create.chapters {
                    for chapter in &chapter_coll.data {
                        match download_comic_chapter::find_by_id(db, chapter.chapter_id).await {
                            None => {
                                download_comic_chapter::ActiveModel {
                                    comic_id: Set(album.id),
                                    chapter_coll: Set(chapter_coll.title.clone()),
                                    chapter_id: Set(chapter.chapter_id),
                                    chapter_title: Set(chapter.chapter_title.clone()),
                                    update_time: Set(chapter.update_time),
                                    file_size: Set(chapter.file_size),
                                    chapter_order: Set(chapter.chapter_order),
                                    load_images: Set(0),
                                    image_count: Set(0),
                                    image_count_download: Set(0),
                                    download_status: Set(0),
                                }
                                .insert(db)
                                .await?;
                                ()
                            }
                            Some(_) => (),
                        }
                    }
                }
                Ok(())
            })
        })
        .await
        .unwrap();
    Ok(String::new())
}

pub(crate) async fn all_downloads() -> Vec<download_comic::Model> {
    download_comic::all(DOWNLOAD_DATABASE.get().unwrap().lock().await.deref()).await
}

pub(crate) async fn download_comic_page_by_chapter_id(
    chapter_id: i32,
) -> Vec<download_comic_page::Model> {
    download_comic_page::find_by_chapter_id(
        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
        chapter_id,
    )
    .await
}

pub(crate) async fn download_comic_chapters_by_comic_id(
    comic_id: i32,
) -> Result<Vec<ComicChapter>> {
    let lock = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    let chapters = download_comic_chapter::list_by_comic_id(lock.deref(), comic_id).await;
    let mut result: Vec<ComicChapter> = vec![];
    for m in chapters {
        let mut point: Option<&mut ComicChapter> = None;
        for x in &mut result {
            if m.chapter_coll.eq(&x.title) {
                point = Some(x);
                break;
            }
        }
        match point {
            None => {
                let mut point = ComicChapter {
                    title: m.chapter_coll,
                    data: vec![],
                };
                point.data.push(ComicChapterInfo {
                    chapter_id: m.chapter_id,
                    chapter_title: m.chapter_title,
                    update_time: m.update_time,
                    file_size: m.file_size,
                    chapter_order: m.chapter_order,
                });
                result.push(point);
            }
            Some(point) => point.data.push(ComicChapterInfo {
                chapter_id: m.chapter_id,
                chapter_title: m.chapter_title,
                update_time: m.update_time,
                file_size: m.file_size,
                chapter_order: m.chapter_order,
            }),
        }
    }
    Ok(result)
}

pub(crate) async fn delete_download(id: i32) -> Result<String> {
    let lock = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    let mut restart_flag = RESTART_FLAG.lock().await;
    if *restart_flag.deref() {
        *restart_flag = true;
    }
    // delete_flag
    download_comic::set_download_status(lock.deref(), id, 3).await;
    drop(restart_flag);
    Ok(String::default())
}

pub(crate) async fn renew_all_downloads() -> Result<String> {
    let lock = DOWNLOAD_DATABASE.get().unwrap().lock().await;
    let mut restart_flag = RESTART_FLAG.lock().await;
    if *restart_flag.deref() {
        *restart_flag = true;
    }
    lock.transaction::<_, (), DbErr>(|db| {
        Box::pin(async move {
            download_comic::renew_failed(db).await;
            download_comic_chapter::renew_failed(db).await;
            download_comic_page::renew_failed(db).await;
            Ok(())
        })
    })
    .await?;
    Ok(String::default())
}

pub(crate) async fn download_ok_pic(url: String) -> Option<(download_comic_page::Model, String)> {
    if let Some(pic) = download_comic_page::find_by_url_ok(
        DOWNLOAD_DATABASE.get().unwrap().lock().await.deref(),
        url,
    )
    .await
    {
        Some((
            pic.clone(),
            join_paths(vec![
                DOWNLOAD_DIR.get().unwrap().as_str(),
                format!("{}", pic.comic_id).as_str(),
                format!("{}", pic.chapter_id).as_str(),
                format!("{}", pic.image_index).as_str(),
            ]),
        ))
    } else {
        None
    }
}
