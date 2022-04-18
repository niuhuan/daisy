
cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

echo > native/src/bridge_generated.rs
flutter_rust_bridge_codegen --llvm-path "$LLVM_HOME" --rust-input native/src/api.rs --dart-output lib/bridge_generated.dart

cd native
rm -rf ../android/app/src/main/jniLibs
cargo ndk -o ../android/app/src/main/jniLibs -t arm64-v8a build --release

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."
flutter build apk --target-platform android-arm64
