use anyhow::Result;
use serde_derive::Deserialize;
use serde_derive::Serialize;
use serde_json::Value;

#[tokio::main]
async fn main() -> Result<()> {
    // get ghToken
    let gh_token = std::env::var("GITHUB_TOKEN")?;
    let target = std::env::var("TARGET")?;
    let repo = std::env::var("REPO")?;
    let flutter_version = std::env::var("FLUTTER_VERSION")?;
    let vs_code_txt = tokio::fs::read_to_string("version.code.txt").await?;
    let code = vs_code_txt.trim();
    let release_file_name = match target.as_str() {
        "macos" => format!("daisy-{}.dmg", code),
        "ios" => format!("daisy-{}-nosign.ipa", code),
        "windows" => format!("daisy-{}-windows-x86_64.zip", code),
        "linux" => format!("daisy-{}-linux-x86_64.AppImage", code),
        "android-arm32" => format!("daisy-{}-arm32.apk", code),
        "android-arm64" => format!("daisy-{}-arm64.apk", code),
        "android-x86_64" => format!("daisy-{}-x86_64.apk", code),
        un => panic!("unknown target : {}-flutter_{}", un, flutter_version),
    };
    let local_path = match target.as_str() {
        "macos" => "../build/macos.dmg",
        "ios" => "../build/nosign.ipa",
        "windows" => "../build/windows.zip",
        "linux" => "../build/linux.AppImage",
        "android-arm32" => "../build/app/outputs/flutter-apk/app-release.apk",
        "android-arm64" => "../build/app/outputs/flutter-apk/app-release.apk",
        "android-x86_64" => "../build/app/outputs/flutter-apk/app-release.apk",
        un => panic!("unknown target : {}", un),
    };

    let client = reqwest::ClientBuilder::new().user_agent(format!("{repo} CI")).build()?;

    let check_response = client
        .get(format!(
            "https://api.github.com/repos/{}/releases/tags/{}",
            repo, code
        ))
        .header("Authorization", format!("token {}", gh_token))
        .send()
        .await?;

    match check_response.status().as_u16() {
        200 => (),
        404 => println!("release not exists"),
        code => {
            let text = check_response.text().await?;
            panic!("error for check release : {} : {}", code, text);
        }
    }
    let release: Release = check_response.json().await?;

    let buff = tokio::fs::read(local_path).await?;

    let response = client
        .post(format!(
            "https://uploads.github.com/repos/{}/releases/{}/assets?name={}",
            repo, release.id, release_file_name
        ))
        .header("Authorization", format!("token {}", gh_token))
        .header("Content-Type", "application/octet-stream")
        .header("Content-Length", buff.len())
        .body(buff)
        .send()
        .await?;

    match response.status().as_u16() {
        201 => (),
        code => {
            let text = response.text().await?;
            panic!("error for check release : {} : {}", code, text);
        }
    }
    Ok(())
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Release {
    pub url: String,
    pub assets_url: String,
    pub upload_url: String,
    pub html_url: String,
    pub id: i64,
    pub author: Author,
    pub node_id: String,
    pub tag_name: String,
    pub target_commitish: String,
    pub name: String,
    pub draft: bool,
    pub prerelease: bool,
    pub created_at: String,
    pub published_at: String,
    pub assets: Vec<Asset>,
    pub tarball_url: String,
    pub zipball_url: String,
    pub body: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Author {
    pub login: String,
    pub id: i64,
    pub node_id: String,
    pub avatar_url: String,
    pub gravatar_id: String,
    pub url: String,
    pub html_url: String,
    pub followers_url: String,
    pub following_url: String,
    pub gists_url: String,
    pub starred_url: String,
    pub subscriptions_url: String,
    pub organizations_url: String,
    pub repos_url: String,
    pub events_url: String,
    pub received_events_url: String,
    #[serde(rename = "type")]
    pub type_field: String,
    pub site_admin: bool,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Asset {
    pub url: String,
    pub id: i64,
    pub node_id: String,
    pub name: String,
    pub label: Value,
    pub uploader: Uploader,
    pub content_type: String,
    pub state: String,
    pub size: i64,
    pub download_count: i64,
    pub created_at: String,
    pub updated_at: String,
    pub browser_download_url: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Uploader {
    pub login: String,
    pub id: i64,
    pub node_id: String,
    pub avatar_url: String,
    pub gravatar_id: String,
    pub url: String,
    pub html_url: String,
    pub followers_url: String,
    pub following_url: String,
    pub gists_url: String,
    pub starred_url: String,
    pub subscriptions_url: String,
    pub organizations_url: String,
    pub repos_url: String,
    pub events_url: String,
    pub received_events_url: String,
    #[serde(rename = "type")]
    pub type_field: String,
    pub site_admin: bool,
}
