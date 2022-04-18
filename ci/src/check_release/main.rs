use anyhow::Result;
use std::collections::HashMap;
use std::process::exit;

const OWNER: &str = "niuhuan";
const REPO: &str = "daisy";
const UA: &str = "niuhuan daisy ci";
const MAIN_BRANCH: &str = "master";

#[tokio::main]
async fn main() -> Result<()> {
    // get ghToken
    let gh_token = std::env::var("GH_TOKEN")?;
    if gh_token.is_empty() {
        panic!("Please set GH_TOKEN");
    }

    let vs_code_txt = tokio::fs::read_to_string("version.code.txt").await?;
    let vs_info_txt = tokio::fs::read_to_string("version.info.txt").await?;

    let code = vs_code_txt.trim();
    let info = vs_info_txt.trim();

    let client = reqwest::ClientBuilder::new().user_agent(UA).build()?;

    let check_response = client
        .get(format!(
            "https://api.github.com/repos/{}/{}/releases/tags/{}",
            OWNER, REPO, code
        ))
        .send()
        .await?;

    match check_response.status().as_u16() {
        200 => {
            println!("release exists");
            exit(0);
        }
        404 => (),
        code => {
            let text = check_response.text().await?;
            panic!("error for check release : {} : {}", code, text);
        }
    }
    drop(check_response);

    // 404

    let check_response = client
        .post(format!(
            "https://api.github.com/repos/{}/{}/releases",
            OWNER, REPO
        ))
        .header("Authorization", format!("token {}", gh_token))
        .json(&{
            let mut params = HashMap::<String, String>::new();
            params.insert("tag_name".to_string(), code.to_string());
            params.insert("target_commitish".to_string(), MAIN_BRANCH.to_string());
            params.insert("name".to_string(), code.to_string());
            params.insert("body".to_string(), info.to_string());
            params
        })
        .send()
        .await?;

    match check_response.status().as_u16() {
        201 => (),
        code => {
            let text = check_response.text().await?;
            panic!("error for create release : {} : {}", code, text);
        }
    }
    Ok(())
}
