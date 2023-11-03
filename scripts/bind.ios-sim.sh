
cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

echo > ios/Runner/bridge_generated.h
echo > native/src/bridge_generated.rs
flutter_rust_bridge_codegen \
    --rust-input native/src/api.rs \
    --dart-output lib/bridge_generated.dart \
    --c-output ios/Runner/bridge_generated.h \
    --rust-crate-dir native \
    --llvm-path $LLVM_HOME \
    --class-name Native


cargo build --manifest-path=native/Cargo.toml --features= --lib --release --target=aarch64-apple-ios-sim
cargo build --manifest-path=native/Cargo.toml --features= --lib --release --target=x86_64-apple-ios
lipo -create -output ios/Runner/libnative.a native/target/aarch64-apple-ios-sim/release/libnative.a native/target/x86_64-apple-ios/release/libnative.a

flutter build ios --release --no-codesign --no-simulator
cd build
rm -rf Payload
mkdir -p Payload
mv ios/iphoneos/Runner.app Payload
sh ../scripts/thin-payload.sh
zip -9 nosign.ipa -r Payload
