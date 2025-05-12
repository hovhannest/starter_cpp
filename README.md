# Rust Project Setup and Build Instructions

## Prerequisites

1. Install Rust toolchain for nightly builds:
```bash
rustup toolchain install nightly
```

2. Add the `rust-src` component for nightly toolchain:
```bash
rustup component add rust-src --toolchain nightly
```

## Building the Project

To build the project with optimized size and custom panic handling, use:
```bash
cargo +nightly build -Z build-std=std,panic_abort -Z build-std-features=optimize_for_size,panic_immediate_abort --profile minsizerel
```

This command:
- Uses nightly toolchain (`+nightly`)
- Rebuilds standard library with size optimizations (`-Z build-std`)
- Configures panic handling for minimal size (`panic_abort`)
- Enables additional size optimizations for std library (`optimize_for_size`)
- Uses immediate abort on panic for smaller binary size (`panic_immediate_abort`)
- Uses minimal size release profile (`--profile minsizerel`)