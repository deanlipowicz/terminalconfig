# Rust Development Policy

Always follow these rules when working on Rust projects:

1. Run `cargo check` before `cargo build` — it provides faster compilation feedback
2. Run `cargo clippy` before any commit and fix all warnings
3. Run `cargo fmt` before any commit
4. On compile errors, inspect the **first error** — later errors are usually cascading
5. Use `anyhow::Result` in application binaries, `thiserror` for library error types
6. Never add `unwrap()` or `expect()` in production code without a comment explaining why the None/Err case is unreachable
7. Prefer `cargo test` with a filter argument over running the full suite during development
