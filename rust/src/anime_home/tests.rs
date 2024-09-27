use crate::anime_home::{ComicType, ObjType, Sort};
use crate::{Client, Result};

fn print<T>(result: Result<T>)
where
    T: serde::Serialize + Send + Sync,
{
    match result {
        Ok(t) => match serde_json::to_string(&t) {
            Ok(text) => println!("{}", text),
            Err(err) => panic!("{}", err),
        },
        Err(err) => panic!("{}", err),
    }
}

#[tokio::test]
async fn test_login() {
    print(
        Client::new()
            .login(
                env!("username").to_string(),
                hex::encode(md5::compute(env!("password").as_bytes()).0).to_uppercase(),
            )
            .await,
    )
}

#[tokio::test]
async fn test_update_list() {
    print(Client::new().comic_update_list(ComicType::ALL, 1).await)
}

#[tokio::test]
async fn test_rank_list() {
    print(Client::new().comic_rank_list().await)
}

#[tokio::test]
async fn test_detail() {
    print(Client::new().comic_detail(63825).await)
}

#[tokio::test]
async fn test_novel_detail() {
    print(Client::new().novel_detail(3581).await)
}

#[tokio::test]
async fn test_comic_chapter_detail() {
    print(Client::new().comic_chapter_detail(63825, 138099).await)
}

#[tokio::test]
async fn test_novel_chapters() {
    print(Client::new().novel_chapters(3581).await)
}

#[tokio::test]
async fn test_novel_content() {
    print(Client::new().novel_content(13197, 135945).await)
}

#[tokio::test]
async fn test_news_categories() {
    print(Client::new().news_categories().await)
}

#[tokio::test]
async fn test_news() {
    print(Client::new().news_list(0, 1).await)
}

#[tokio::test]
async fn test_comic_recommend() {
    print(Client::new().comic_recommend().await)
}

#[tokio::test]
async fn test_comic_classify_with_level() {
    print(
        Client::new()
            .comic_classify_with_level(None, Sort::UPDATE, 0)
            .await,
    )
}

#[tokio::test]
async fn test_comic_categories() {
    print(Client::new().comic_categories().await)
}

#[tokio::test]
async fn test_comic_search() {
    print(Client::new().comic_search("你好".to_owned(), 0).await)
}

#[tokio::test]
async fn test_novel_search() {
    print(Client::new().novel_search("你好".to_owned(), 0).await)
}

#[tokio::test]
async fn test_novel_categories() {
    print(Client::new().novel_categories().await)
}

#[tokio::test]
async fn test_chapter() {
    print(Client::new().comic_chapter_detail(10, 11).await)
}

#[tokio::test]
async fn test_comments() {
    print(Client::new().comment(ObjType::COMIC, 67216, true, 1).await)
}

#[tokio::test]
async fn test_task_index() {
    let client = Client::new();
    client
        .login(
            env!("username").to_string(),
            hex::encode(md5::compute(env!("password").as_bytes()).0).to_uppercase(),
        )
        .await
        .unwrap();
    print(client.task_index().await)
}

#[tokio::test]
async fn test_subscribed_list() {
    let client = Client::new();
    client
        .login(
            env!("username").to_string(),
            hex::encode(md5::compute(env!("password").as_bytes()).0).to_uppercase(),
        )
        .await
        .unwrap();
    print(client.subscribed_list(0, 0).await);
}
