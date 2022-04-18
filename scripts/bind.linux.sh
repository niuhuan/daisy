
cbindgen native/src/platforms/non_android.rs -l c > linux/native.h

# llvm (see https://pub.dev/packages/ffigen)
# sudo apt-get install libclang-dev

touch native/src/bridge_generated.rs
flutter_rust_bridge_codegen \
    --rust-input native/src/api.rs \
    --dart-output lib/bridge_generated.dart \
    --c-output linux/bridge_generated.h \
    --rust-crate-dir native \
    --class-name Native
