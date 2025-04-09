# nimiCPP

A C++ project template demonstrating reproducible builds across different platforms.

## Overview

nimiCPP is designed to create consistently reproducible builds by:
- Using Zig as a hermetic C/C++ toolchain
- Ensuring deterministic compilation settings
- Removing timestamp and path information from binaries
- Supporting cross-platform builds via CMake presets

## Requirements

- CMake 3.23 or later
- [Ninja](https://ninja-build.org/) build system (required)

The project uses:
- Zig as its compiler toolchain (automatically downloaded)
- Ninja as the build system (must be installed)

## Quick Start

```bash
# Configure project (automatically downloads Zig)
cmake --preset windows-x86_64-release   # Windows
cmake --preset linux-x86_64-release     # Linux
cmake --preset macos-x86_64-release     # macOS

# Build project (using ninja)
cmake --build --preset windows-x86_64-release   # Windows
cmake --build --preset linux-x86_64-release     # Linux
cmake --build --preset macos-x86_64-release     # macOS
```

Or manually:
```bash
mkdir build
cd build
cmake ../ --preset windows-x86_64-release   # Configure
ninja                                       # Build
## Building

Build using CMake presets. The Zig compiler toolchain will be automatically installed if needed:

2. Build using CMake presets:
   ```bash
   # Windows
   cmake --preset windows-x86_64-release
   cmake --build --preset windows-x86_64-release

   # Linux
   cmake --preset linux-x86_64-release
   cmake --build --preset linux-x86_64-release

   # macOS
   cmake --preset macos-x86_64-release
   cmake --build --preset macos-x86_64-release
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
1. Perform two separate builds
2. Compare the resulting binaries
3. Show detailed differences if any are found

## Project Structure

- `/src` - Source code
- `/cmake`
  - `/modules` - CMake modules for build configuration
  - `/toolchains` - Platform-specific toolchain files
- `/scripts` - Build and utility scripts

## Adding Dependencies

The project includes a hermetic dependency system. Add new dependencies using the `add_hermetic_dependency` function in CMake:

```cmake
add_hermetic_dependency(
  NAME example_lib
  GIT_REPOSITORY https://github.com/example/lib.git
  GIT_TAG v1.0.0
  EXPECTED_HASH <sha256-hash>  # Hash of the source at the specified tag
)
```

This ensures dependencies are:
- Fetched using a hermetic Git installation
- Verified via hash checking
- Built consistently across platforms
- Isolated from system Git configuration

The system automatically manages its own Git installation in `sysroot/tools/git` to ensure:
- Consistent Git behavior across platforms
- Isolation from system Git settings
- Reproducible dependency fetching
- Security through verified downloads

## License

This project is licensed under terms to be determined.