use build_target::Os;

fn main() {
    let os = build_target::target_os().unwrap();
    match os {
        Os::MacOs => {
            println!("cargo:rustc-link-lib=framework=SystemConfiguration");
        }
        _ => {}
    }
}
