use std::env;

fn main() {
    // Only run on Windows MSVC
    if env::var("CARGO_CFG_TARGET_ENV").unwrap() == "msvc" {
        thunk::thunk();
    }
}