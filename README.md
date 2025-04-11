# Starter C++

A C++ project template demonstrating reproducible builds across different platforms.

## Overview

This project is designed to create consistently reproducible builds by:
- Using Zig as a hermetic C/C++ toolchain
- Ensuring deterministic compilation settings
- Removing timestamp and path information from binaries
- Supporting cross-platform builds via CMake presets

## Requirements

- CMake 3.23 or later

The project automatically manages:
- Zig compiler toolchain (automatically downloaded)
- Ninja build system (automatically downloaded)

## Quick Start

Configure and build the project using CMake presets:

```bash
# Configure project
cmake --preset <target-preset>

# Build project
cmake --build --preset <target-preset>
```

Available presets:
- Windows x64: `windows-x86_64-debug`, `windows-x86_64-release`
- Linux x64: `linux-x86_64-debug`, `linux-x86_64-release`
- macOS Intel: `macos-x86_64-debug`, `macos-x86_64-release`
- macOS Apple Silicon: `macos-arm64-debug`, `macos-arm64-release`

Example:
```bash
# Configure for Windows release build
cmake --preset windows-x86_64-release

# Build the project
cmake --build --preset windows-x86_64-release
```

## Verifying Reproducible Builds

Run the reproduce script to verify build reproducibility:

```powershell
# Windows
.\reproduce.bat
```
```bash
# Linux/macOS
./reproduce.sh
```

This will:
1. Clean previous builds
2. For each target platform (Windows, Linux, macOS Intel, macOS ARM):
   - Build debug and release variants twice
   - Compare the resulting binaries
   - Show detailed differences if any are found
   - Display SHA256 hashes of the builds
3. Report overall success/failure

## Project Structure

- `/src` - Source code
- `/cmake`
  - `/modules` - CMake modules
    - `BuildHardening.cmake` - Build hardening settings
    - `FetchNinja.cmake` - Ninja build system fetcher
    - `FetchZig.cmake` - Zig compiler toolchain fetcher
  - `/toolchains` - Platform-specific toolchain files
    - `windows-x86_64.cmake` - Windows x64 toolchain
    - `linux-x86_64.cmake` - Linux x64 toolchain
    - `darwin-x86_64.cmake` - macOS Intel toolchain
    - `darwin-arm64.cmake` - macOS ARM (Apple Silicon) toolchain
- `/scripts` - Build and utility scripts
- `/sysroot` - Downloaded tools and cache (automatically created)
  - `/tools` - Build tools (Zig, Ninja)
  - `/.zigcache` - Zig compiler cache

## Cross-Compilation

The project supports cross-compilation to any supported target from any host platform using Zig's cross-compilation capabilities. For example:
- Build Windows binaries from Linux
- Build Linux binaries from Windows
- Build macOS binaries from Windows/Linux

The toolchain files handle all necessary compiler and linker settings to ensure reproducible builds regardless of the host platform.

## License

This project is licensed under terms to be determined.