use anyhow::Result;
use std::collections::HashMap;
use std::process::exit;

#[tokio::main]
async fn main() -> Result<()> {
    // get ghToken
    let gh_token = std::env::var("GITHUB_TOKEN")?;
    let repo = std::env::var("REPO")?;
    let flutter_version = std::env::var("FLUTTER_VERSION")?;

    let vs_code_txt = tokio::fs::read_to_string("version.code.txt").await?;
    let vs_info_txt = tokio::fs::read_to_string("version.info.txt").await?;

    let code = vs_code_txt.trim();
    let info = vs_info_txt.trim();

    let client = reqwest::ClientBuilder::new().user_agent(format!("{repo} CI")).build()?;

    let check_response = client
        .get(format!(
            "https://api.github.com/repos/{}/releases/tags/{}",
            repo, code
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
            "https://api.github.com/repos/{}/releases",
            repo
        ))
        .header("Authorization", format!("token {}", gh_token))
        .json(&{
            let mut params = HashMap::<String, String>::new();
            params.insert("tag_name".to_string(), code.to_string());
            params.insert("target_commitish".to_string(), "master".to_string());
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
