use std::path::{Path, PathBuf};

#[allow(dead_code)]
pub(crate) fn join_paths<P: AsRef<Path>>(paths: Vec<P>) -> String {
    match paths.len() {
        0 => String::default(),
        _ => {
            let mut path: PathBuf = PathBuf::new();
            for x in paths {
                path = path.join(x);
            }
            return path.to_str().unwrap().to_string();
        }
    }
}

pub(crate) fn create_dir_if_not_exists(path: &String) {
    if !Path::new(path).exists() {
        std::fs::create_dir_all(path).unwrap();
    }
}
