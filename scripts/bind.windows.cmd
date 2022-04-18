
@echo. > native/src/bridge_generated.rs

flutter_rust_bridge_codegen --rust-crate-dir native --rust-input native/src/api.rs --dart-output lib/bridge_generated.dart
