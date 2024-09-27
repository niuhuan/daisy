use anyhow::Context;
use base64::engine::{GeneralPurpose, GeneralPurposeConfig};
use base64::{alphabet, Engine};
use lazy_static::lazy_static;
use prost::Message;
use reqwest::Method;
use rsa::pkcs8::DecodePrivateKey;
use rsa::RsaPrivateKey;
use std::collections::HashMap;
use std::ops::Deref;
use tokio::sync::RwLock;

use crate::Result;

use super::entities::*;
use super::proto::*;

const WEB_URL: &str = "https://m.idmzj.com";
const INTERFACE_URL: &str = "https://interface.muwai.com";
const BASE_URL_V3: &str = "https://nnv3api.idmzj.com";
const BASE_URL_V4: &str = "https://nnv4api.idmzj.com";
const LOGIN_URL_V2: &str = "https://nnuser.idmzj.com/loginV2/m_confirm";

const PAD: GeneralPurposeConfig = GeneralPurposeConfig::new();
const STANDARD: GeneralPurpose = GeneralPurpose::new(&alphabet::STANDARD, PAD);

lazy_static! {
    static ref CLIENT_PRIVATE_KEY: RsaPrivateKey = {
        let key_buff = STANDARD.decode("MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAK8nNR1lTnIfIes6oRWJNj3mB6OssDGx0uGMpgpbVCpf6+VwnuI2stmhZNoQcM417Iz7WqlPzbUmu9R4dEKmLGEEqOhOdVaeh9Xk2IPPjqIu5TbkLZRxkY3dJM1htbz57d/roesJLkZXqssfG5EJauNc+RcABTfLb4IiFjSMlTsnAgMBAAECgYEAiz/pi2hKOJKlvcTL4jpHJGjn8+lL3wZX+LeAHkXDoTjHa47g0knYYQteCbv+YwMeAGupBWiLy5RyyhXFoGNKbbnvftMYK56hH+iqxjtDLnjSDKWnhcB7089sNKaEM9Ilil6uxWMrMMBH9v2PLdYsqMBHqPutKu/SigeGPeiB7VECQQDizVlNv67go99QAIv2n/ga4e0wLizVuaNBXE88AdOnaZ0LOTeniVEqvPtgUk63zbjl0P/pzQzyjitwe6HoCAIpAkEAxbOtnCm1uKEp5HsNaXEJTwE7WQf7PrLD4+BpGtNKkgja6f6F4ld4QZ2TQ6qvsCizSGJrjOpNdjVGJ7bgYMcczwJBALvJWPLmDi7ToFfGTB0EsNHZVKE66kZ/8Stx+ezueke4S556XplqOflQBjbnj2PigwBN/0afT+QZUOBOjWzoDJkCQClzo+oDQMvGVs9GEajS/32mJ3hiWQZrWvEzgzYRqSf3XVcEe7PaXSd8z3y3lACeeACsShqQoc8wGlaHXIJOHTcCQQCZw5127ZGs8ZDTSrogrH73Kw/HvX55wGAeirKYcv28eauveCG7iyFR0PFB/P/EDZnyb+ifvyEFlucPUI0+Y87F").unwrap();
        RsaPrivateKey::from_pkcs8_der(&key_buff).unwrap()
    };
}

pub struct Client {
    agent: reqwest::Client,
    user_ticket: RwLock<(String, String)>,
}

macro_rules! ok_data {
    ($response:ident) => {
        if $response.err_number == 0 {
            Ok($response.data)
        } else {
            Err(anyhow::Error::msg($response.err_message))
        }
    };
}

macro_rules! ok_data_action {
    ($response:ident) => {
        if $response.code == 0 {
            Ok(())
        } else {
            Err(anyhow::Error::msg($response.msg))
        }
    };
}

macro_rules! ok_option_data {
    ($response:ident) => {
        if $response.err_number == 0 {
            if let Some(some) = $response.data {
                if some.id != 0 {
                    return Ok(some);
                }
            }
            Err(anyhow::Error::msg("not found"))
        } else {
            Err(anyhow::Error::msg($response.err_message))
        }
    };
}

impl Client {
    pub fn new() -> Self {
        Self {
            agent: reqwest::ClientBuilder::new()
                .user_agent("Android,DMZJ,10;")
                .build()
                .unwrap(),
            user_ticket: RwLock::new((String::default(), String::default())),
        }
    }

    pub async fn set_user_ticket(&self, uid: String, token: String) {
        let mut tic = self.user_ticket.write().await;
        *tic = (uid, token);
    }

    pub async fn get_user_ticket(&self) -> (String, String) {
        self.user_ticket.read().await.deref().clone()
    }

    async fn query(
        &self,
        query: impl Into<Option<HashMap<String, String>>>,
        auth_level: AuthLevel,
    ) -> Result<HashMap<String, String>> {
        let mut map = HashMap::<String, String>::new();
        map.insert("channel".to_owned(), "android".to_owned());
        map.insert("version".to_owned(), "3.0.0".to_owned());
        map.insert(
            "timestamp".to_owned(),
            format!("{}", chrono::Local::now().timestamp()),
        );
        map.insert(
            "_m".to_owned(),
            "EAFAF04AE5D23760AB8D157C2FAB0452".to_owned(),
        );
        let ticket = self.user_ticket.read().await;
        if !ticket.0.is_empty() && !ticket.1.is_empty() {
            map.insert("uid".to_owned(), ticket.0.clone());
            map.insert("_token".to_owned(), ticket.1.clone());
        } else {
            if let AuthLevel::TOKEN = auth_level {
                return Err(anyhow::Error::msg("need login"));
            }
        }
        if let Some(queries) = query.into() {
            for (k, v) in queries.iter() {
                map.insert(k.clone(), v.clone());
            }
        }
        Ok(map)
    }

    pub async fn request_url<T: for<'de> serde::Deserialize<'de>>(
        &self,
        method: Method,
        url: &str,
        query: impl Into<Option<HashMap<String, String>>>,
        auth: AuthLevel,
    ) -> Result<T> {
        let query = self.query(query, auth).await?;
        let request = self.agent.request(method.clone(), url);
        let request = match method {
            Method::GET => request.query(&query),
            Method::POST => request.form(&query),
            _ => return Err(anyhow::Error::msg("not impl")),
        };
        let data = request.send().await?.text().await?;
        Ok(serde_json::from_str(data.as_str())?)
    }

    pub async fn request_interface<T: for<'de> serde::Deserialize<'de>>(
        &self,
        method: Method,
        path: &str,
        query: impl Into<Option<HashMap<String, String>>>,
        auth: AuthLevel,
    ) -> Result<T> {
        self.request_url(method, &format!("{}{}", INTERFACE_URL, path), query, auth)
            .await
    }

    pub async fn request_v3<T: for<'de> serde::Deserialize<'de>>(
        &self,
        method: Method,
        path: &str,
        query: impl Into<Option<HashMap<String, String>>>,
        auth: AuthLevel,
    ) -> Result<T> {
        self.request_url(method, &format!("{}{}", BASE_URL_V3, path), query, auth)
            .await
    }

    pub(crate) async fn request_v3_response<T: for<'de> serde::Deserialize<'de>>(
        &self,
        method: Method,
        path: &str,
        query: impl Into<Option<HashMap<String, String>>>,
        auth: AuthLevel,
    ) -> Result<T> {
        let query = self.query(query, auth).await?;
        let data = self
            .agent
            .request(method, &format!("{}{}", BASE_URL_V3, path))
            .query(&query)
            .send()
            .await?
            .text()
            .await?;
        let response = serde_json::from_str::<V3Response<T>>(data.as_str())?;
        match response.code {
            0 => Ok(response.data.with_context(|| "data not found")?),
            _ => Err(anyhow::Error::msg(response.msg)),
        }
    }

    pub(crate) async fn request_v3_no_response(
        &self,
        method: Method,
        path: &str,
        query: impl Into<Option<HashMap<String, String>>>,
        auth: AuthLevel,
    ) -> Result<()> {
        let query = self.query(query, auth).await?;
        let data = self
            .agent
            .request(method, &format!("{}{}", BASE_URL_V3, path))
            .query(&query)
            .send()
            .await?
            .text()
            .await?;
        let response = serde_json::from_str::<V3Response<()>>(data.as_str())?;
        match response.code {
            0 => Ok(()),
            _ => Err(anyhow::Error::msg(response.msg)),
        }
    }

    pub async fn request_v4<T>(
        &self,
        method: Method,
        path: &str,
        query: impl Into<Option<HashMap<String, String>>>,
        auth: AuthLevel,
    ) -> Result<T>
    where
        T: Message + std::default::Default,
    {
        let query = self.query(query, auth).await?;
        let data = self
            .agent
            .request(method, &format!("{}{}", BASE_URL_V4, path))
            .query(&query)
            .send()
            .await?
            .text()
            .await?;
        self.response_v4(data)
    }

    pub fn response_v4<T>(&self, data: String) -> Result<T>
    where
        T: Message + std::default::Default,
    {
        let mut decode = Vec::<u8>::new();
        let data = STANDARD.decode(data)?;
        for chunk in data.chunks(128) {
            decode.append(
                &mut CLIENT_PRIVATE_KEY.decrypt(rsa::PaddingScheme::PKCS1v15Encrypt, &chunk)?,
            );
        }
        Ok(T::decode(decode.as_slice())?)
    }

    pub async fn login(
        &self,
        username: String,
        password_md5_uppercase: String,
    ) -> Result<LoginData> {
        let query = self
            .query(
                {
                    let mut map = HashMap::<String, String>::new();
                    map.insert("nickname".to_string(), username);
                    map.insert("pwd".to_string(), password_md5_uppercase);
                    map
                },
                AuthLevel::NORMAL,
            )
            .await?;
        let data = self
            .agent
            .request(Method::POST, LOGIN_URL_V2)
            .form(&query)
            .send()
            .await?
            .text()
            .await?;
        let login_response: LoginResponse = serde_json::from_str(data.as_str())?;
        if login_response.result != 1 {
            return Err(anyhow::Error::msg(login_response.msg));
        }
        let data = login_response.data.with_context(|| "error body")?;
        let mut ticket = self.user_ticket.write().await;
        *ticket = (data.uid.clone(), data.dmzj_token.to_string());
        Ok(data)
    }

    pub async fn comic_categories(&self) -> Result<Vec<ComicCategory>> {
        return self
            .request_v3_response(Method::GET, "/0/category.json", None, AuthLevel::NORMAL)
            .await;
    }

    pub async fn comic_classify_filters(&self) -> Result<Vec<ComicFilter>> {
        self.request_v3(
            Method::GET,
            "/classify/filter.json",
            None,
            AuthLevel::NORMAL,
        )
        .await
    }

    /// 漫画列表
    /// page从0开始
    pub async fn comic_classify_with_level(
        &self,
        categories: impl Into<Option<Vec<i32>>>,
        sort: Sort,
        page: i64,
    ) -> Result<Vec<ComicInFilter>> {
        let categories: String = if let Some(categories) = categories.into() {
            if categories.len() > 0 {
                categories
                    .iter()
                    .map(|i| format!("{}", i))
                    .collect::<Vec<String>>()
                    .join("-")
            } else {
                "0".to_owned()
            }
        } else {
            "0".to_owned()
        };
        self.request_v3(
            Method::GET,
            &format!("/classifyWithLevel/{}/{}/{}.json", categories, sort, page),
            None,
            AuthLevel::NORMAL,
        )
        .await
    }

    /// 漫画推荐
    pub async fn comic_recommend(&self) -> Result<Vec<ComicInFilter>> {
        self.request_v3(Method::GET, "/recommend_new.json", None, AuthLevel::NORMAL)
            .await
    }

    /// 首页-更新
    // "全部漫画": "100",
    // "原创漫画": "1",
    // "译制漫画": "0",
    pub async fn comic_update_list(
        &self,
        comic_type: ComicType,
        page: i64,
    ) -> Result<Vec<ComicUpdateListItem>> {
        let response: ComicUpdateListResponse = self
            .request_v4(
                Method::GET,
                &format!("/comic/update/list/{}/{}", comic_type, page),
                None,
                AuthLevel::NORMAL,
            )
            .await?;
        ok_data!(response)
    }

    /// 漫画排行
    pub async fn comic_rank_list(&self) -> Result<Vec<ComicRankListItem>> {
        let response: ComicRankListResponse = self
            .request_v4(Method::GET, "/comic/rank/list", None, AuthLevel::NORMAL)
            .await?;
        ok_data!(response)
    }

    /// 搜索漫画
    pub async fn comic_search(&self, content: String, page: i64) -> Result<Vec<ComicInSearch>> {
        self.request_v3(
            Method::GET,
            &format!("/search/showWithLevel/0/{}/{}.json", content, page),
            None,
            AuthLevel::NORMAL,
        )
        .await
    }

    /// 漫画详情
    pub async fn comic_detail(&self, id: i32) -> Result<ComicDetail> {
        let core_token = self.core_token();
        let response: ComicDetailResponse = self
            .request_v4(
                Method::GET,
                &format!("/comic/detail/{}", id),
                {
                    let mut map = HashMap::<String, String>::new();
                    map.insert("timestamp".to_string(), core_token.0.to_string());
                    map.insert("coreToken".to_string(), core_token.1);
                    map
                },
                AuthLevel::TOKEN,
            )
            .await?;
        ok_option_data!(response)
    }

    fn core_token(&self) -> (i64, String) {
        let timestamp = chrono::Local::now().timestamp();
        let hash = md5::compute(
            format!(
                "com.dmzj.manhua63:60:C8:3B:75:31:3F:35:EC:41:1D:85:60:63:EB:25{}+bYV5TaOBivUHM",
                timestamp
            )
            .as_bytes(),
        )
        .to_vec()
        .iter()
        .map(|e| hex::encode(vec![e.clone()]).to_uppercase())
        .collect::<Vec<String>>()
        .join(":");
        (timestamp, format!("{}|{}", timestamp, hash))
    }

    pub async fn comic_chapter_detail(
        &self,
        comic_id: i32,
        chapter_id: i32,
    ) -> Result<ComicChapterDetail> {
        let core_token = self.core_token();
        let response: ComicChapterDetailResponse = self
            .request_v4(
                Method::GET,
                &format!("/comic/chapter/{}/{}", comic_id, chapter_id),
                {
                    let mut map = HashMap::<String, String>::new();
                    map.insert("timestamp".to_string(), core_token.0.to_string());
                    map.insert("coreToken".to_string(), core_token.1);
                    map
                },
                AuthLevel::TOKEN,
            )
            .await?;
        if response.err_number == 0 {
            if let Some(some) = response.data {
                if some.chapter_id != 0 {
                    return Ok(some);
                }
            }
        }
        Err(anyhow::Error::msg(response.err_message))
    }

    /// 新闻分类
    pub async fn news_categories(&self) -> Result<Vec<NewsCategory>> {
        Ok(self
            .request_v3(
                Method::GET,
                "/article/category.json",
                None,
                AuthLevel::NORMAL,
            )
            .await?)
    }

    pub async fn news_list(&self, id: i64, page: i64) -> Result<Vec<NewsListItem>> {
        let response: NewsListResponse = self
            .request_v4(
                Method::GET,
                &format!("/news/list/{}/{}/{}", id, if id == 0 { 2 } else { 3 }, page),
                None,
                AuthLevel::NORMAL,
            )
            .await?;
        ok_data!(response)
    }

    /// 小说分类
    pub async fn novel_categories(&self) -> Result<Vec<NovelCategory>> {
        Ok(self
            .request_v3(Method::GET, "/1/category.json", None, AuthLevel::NORMAL)
            .await?)
    }

    ///小说列表
    /// process 0,不限 1,连载中 2,已完结
    /// page从0开始
    pub async fn novel_list(
        &self,
        category: impl Into<Option<i32>>,
        process: i64,
        sort: Sort,
        page: i64,
    ) -> Result<Vec<NovelInFilter>> {
        let category = if let Some(category) = category.into() {
            category
        } else {
            0
        };
        self.request_v3(
            Method::GET,
            &format!("/novel/{}/{}/{}/{}.json", category, process, sort, page),
            None,
            AuthLevel::NORMAL,
        )
        .await
    }

    /// 搜索小说
    pub async fn novel_search(&self, content: String, page: i64) -> Result<Vec<NovelInSearch>> {
        self.request_v3(
            Method::GET,
            &format!("/search/show/1/{}/{}.json", content, page),
            None,
            AuthLevel::NORMAL,
        )
        .await
    }

    pub async fn novel_detail(&self, id: i32) -> Result<NovelDetail> {
        let response: NovelDetailResponse = self
            .request_v4(
                Method::GET,
                &format!("/novel/detail/{}", id),
                None,
                AuthLevel::NORMAL,
            )
            .await?;
        ok_option_data!(response)
    }

    pub async fn novel_chapters(&self, id: i32) -> Result<Vec<NovelVolume>> {
        let response: NovelChaptersResponse = self
            .request_v4(
                Method::GET,
                &format!("/novel/chapter/{}", id),
                None,
                AuthLevel::NORMAL,
            )
            .await?;
        ok_data!(response)
    }

    pub async fn novel_content(&self, volume_id: i32, chapter_id: i32) -> Result<String> {
        const NOVEL_CONTENT_HOST: &str = "http://jurisdiction.idmzj.com";
        const NOVEL_CONTENT_KEY: &str =
            "IBAAKCAQEAsUAdKtXNt8cdrcTXLsaFKj9bSK1nEOAROGn2KJXlEVekcPssKUxSN8dsfba51kmHM";
        let path = format!("/lnovel/{}_{}.txt", volume_id, chapter_id);
        let ts = chrono::Local::now().timestamp();
        let key =
            hex::encode(md5::compute(&format!("{}{}{}", NOVEL_CONTENT_KEY, path, ts)).as_slice());
        let url = format!("{}{}?t={}&k={}", NOVEL_CONTENT_HOST, path, ts, key);
        let text = self
            .agent
            .get(&url)
            .send()
            .await?
            .error_for_status()?
            .text()
            .await?;
        let reg = regex::Regex::new(r"<script type='text/javascript'>\S+</script>")?;
        Ok(reg.replace(&text, regex::NoExpand("")).to_string())
    }

    // page 从 1 开始
    pub async fn comment(
        &self,
        obj_type: ObjType,
        obj_id: i32,
        hot: bool,
        page: i64,
    ) -> Result<Vec<Comment>> {
        self.request_interface(
            Method::GET,
            "/api/NewComment2/list",
            {
                let mut params = HashMap::<String, String>::new();
                params.insert("type".to_owned(), obj_type.to_string());
                params.insert("obj_id".to_owned(), obj_id.to_string());
                params.insert("hot".to_owned(), if hot { "1" } else { "0" }.to_owned());
                params.insert("page_index".to_owned(), page.to_string());
                params.insert("_".to_owned(), chrono::Local::now().timestamp().to_string());
                params
            },
            AuthLevel::NORMAL,
        )
        .await
    }

    /// page 从0开始
    /// sub_type: 0 comic, 1 novel
    pub async fn subscribed_list(&self, sub_type: i64, page: i64) -> Result<Vec<Subscribed>> {
        self.request_v3(
            Method::GET,
            "/UCenter/subscribeWithLevel",
            {
                let mut params = HashMap::<String, String>::new();
                params.insert("type".to_owned(), sub_type.to_string());
                params.insert("page".to_owned(), page.to_string());
                params.insert("letter".to_owned(), "all".to_string());
                params
            },
            AuthLevel::TOKEN,
        )
        .await
    }

    /// obj_type 0 : 漫画 1 : 小说
    pub async fn subscribed_obj(&self, obj_type: i64, obj_id: i32) -> Result<bool> {
        let ticket = self.user_ticket.read().await;
        let uid = ticket.deref().0.clone();
        drop(ticket);
        let result: ActionResult = self
            .request_v3(
                Method::GET,
                &format!("/subscribe/{}/{}/{}", obj_type, uid, obj_id),
                None,
                AuthLevel::TOKEN,
            )
            .await?;
        if result.msg.len() > 0 {
            Err(anyhow::Error::msg(""))
        } else {
            Ok(result.code == 0)
        }
    }

    /// obj_type mh : 漫画 xs : 小说
    pub async fn subscribe_add(&self, obj_type: String, obj_id: i32) -> Result<()> {
        let result: ActionResult = self
            .request_v3(
                Method::POST,
                "/subscribe/add",
                {
                    let mut params = HashMap::<String, String>::new();
                    params.insert("obj_ids".to_owned(), obj_id.to_string());
                    params.insert("type".to_owned(), obj_type);
                    params
                },
                AuthLevel::TOKEN,
            )
            .await?;
        ok_data_action!(result)
    }

    pub async fn subscribe_cancel(&self, obj_type: String, obj_id: i32) -> Result<()> {
        let result: ActionResult = self
            .request_v3(
                Method::GET,
                "/subscribe/cancel",
                {
                    let mut params = HashMap::<String, String>::new();
                    params.insert("obj_ids".to_owned(), obj_id.to_string());
                    params.insert("type".to_owned(), obj_type);
                    params
                },
                AuthLevel::TOKEN,
            )
            .await?;
        ok_data_action!(result)
    }

    /// page从1开始
    pub async fn get_re_info_with_level_comic(&self, page: i64) -> Result<Vec<ComicReDown>> {
        if page < 0 {
            return Err(anyhow::Error::msg("error page number"));
        }
        let token = self.user_ticket.read().await;
        let uid = token.0.clone();
        drop(token);
        if uid.is_empty() {
            return Err(anyhow::Error::msg("need login"));
        }
        self.request_interface(
            Method::GET,
            format!("/api/getReInfoWithLevel/comic/{}/{}", uid, 0).as_str(),
            {
                let mut params = HashMap::<String, String>::new();
                if page > 1 {
                    params.insert("page".to_owned(), page.to_string());
                }
                params
            },
            AuthLevel::TOKEN,
        )
        .await
    }

    /// 从网页获取comic_id
    pub async fn load_comic_id(&self, comic_id_string: String) -> Result<i32> {
        let url = format!("{}/info/{}.html", WEB_URL, comic_id_string);
        let body = self.agent.get(url).send().await?.text().await?;
        let regex = regex::Regex::new("onclick=\"addSubscribe\\((\\d+)\\)\"")?;
        if let Some(find) = regex.captures_iter(&body).next() {
            if let Some(find) = find.get(1) {
                return Ok(find.as_str().parse()?);
            }
        }
        Err(anyhow::Error::msg("not found"))
    }

    pub async fn task_index(&self) -> Result<TaskIndex> {
        self.request_v3_response(Method::GET, "/task/index", None, AuthLevel::TOKEN)
            .await
    }

    pub async fn task_sign(&self) -> Result<()> {
        self.request_v3_no_response(Method::GET, "/task/sign", None, AuthLevel::TOKEN)
            .await
    }

    pub async fn get_re_comic(&self, re_list: Vec<ComicReSet>) -> Result<Vec<()>> {
        let mut maps = Vec::<HashMap<String, String>>::new();
        for x in re_list {
            maps.push({
                let mut map = HashMap::new();
                map.insert(x.comic_id.to_string(), x.chapter_id.to_string());
                map.insert("comicId".to_owned(), x.comic_id.to_string());
                map.insert("chapterId".to_owned(), x.chapter_id.to_string());
                map.insert("page".to_owned(), x.page.to_string());
                map.insert("time".to_owned(), x.time.to_string());
                map
            });
        }
        let st = "comic".to_string();
        let json = serde_json::to_string(&maps)?;
        self.request_interface(
            Method::GET,
            "/api/record/getRe",
            {
                let mut params = HashMap::<String, String>::new();
                params.insert("st".to_owned(), st);
                params.insert("json".to_owned(), json);
                params
            },
            AuthLevel::TOKEN,
        )
        .await
    }

    pub async fn get_re_novel(&self, re_list: Vec<NovelReSet>) -> Result<Vec<()>> {
        let mut maps = Vec::<HashMap<String, String>>::new();
        for x in re_list {
            maps.push({
                let mut map = HashMap::new();
                map.insert(x.lnovel_id.to_string(), x.chapter_id.to_string());
                map.insert("lnovel_id".to_owned(), x.lnovel_id.to_string());
                map.insert("volume_id".to_owned(), x.volume_id.to_string());
                map.insert("chapter_id".to_owned(), x.chapter_id.to_string());
                map.insert("page".to_owned(), 0.to_string());
                map.insert("total_num".to_owned(), x.total_num.to_string());
                map.insert("time".to_owned(), x.time.to_string());
                map
            });
        }
        let st = "novel".to_string();
        let json = serde_json::to_string(&maps)?;
        self.request_interface(
            Method::GET,
            "/api/record/getRe",
            {
                let mut params = HashMap::<String, String>::new();
                params.insert("st".to_owned(), st);
                params.insert("json".to_owned(), json);
                params
            },
            AuthLevel::TOKEN,
        )
        .await
    }
}

pub enum AuthLevel {
    NORMAL,
    TOKEN,
}
