#!/bin/bash
# reproduce.sh

set -euo pipefail

# Check for Zig installation
if [ ! -f "sysroot/tools/zig/zig" ]; then
    echo "Error: Zig not found in sysroot/tools/zig"
    echo "Please ensure the environment is properly set up first"
    exit 1
fi

# Force deterministic environment
export TZ=UTC
export LC_ALL=C
export CMAKE_BUILD_PARALLEL_LEVEL=1
export PATH="${PWD}/sysroot/tools/zig:${PWD}/sysroot/tools/ninja:${PWD}/sysroot/tools/cmake-3.27.0/bin:${PATH}"

# Function to build and verify
build_and_verify() {
    local target="$1"
    local label="$2"
    local binary_name="$3"

    echo -e "\n=== Testing ${label} builds ===\n"

    # Debug builds
    echo "Building ${label} debug #1..."
    cmake --preset "${target}-debug"
    cmake --build --preset "${target}-debug"

    # Store the first debug build
    cp "build/${target}-debug/${binary_name}" "build/${target}-debug/${binary_name}.1"

    echo "Building ${label} debug #2..."
    cmake --build --preset "${target}-debug"

    # Compare debug builds
    echo "Comparing ${label} debug builds..."
    if ! cmp -s "build/${target}-debug/${binary_name}.1" "build/${target}-debug/${binary_name}"; then
        echo -e "\n❌ ${label} debug builds differ!\n"
        # Use hexdump to show differences (similar to hexdiff.ps1)
        hexdump -C "build/${target}-debug/${binary_name}.1" > "build/${target}-debug/hex1"
        hexdump -C "build/${target}-debug/${binary_name}" > "build/${target}-debug/hex2"
        diff "build/${target}-debug/hex1" "build/${target}-debug/hex2"
        rm -f "build/${target}-debug/hex1" "build/${target}-debug/hex2"
        exit 1
    fi
    echo "✅ ${label} debug builds match"

    # Release builds
    echo "Building ${label} release #1..."
    cmake --preset "${target}-release"
    cmake --build --preset "${target}-release"

    # Store the first release build
    cp "build/${target}-release/${binary_name}" "build/${target}-release/${binary_name}.1"

    echo "Building ${label} release #2..."
    cmake --build --preset "${target}-release"

    # Compare release builds
    echo "Comparing ${label} release builds..."
    if ! cmp -s "build/${target}-release/${binary_name}.1" "build/${target}-release/${binary_name}"; then
        echo -e "\n❌ ${label} release builds differ!\n"
        # Use hexdump to show differences
        hexdump -C "build/${target}-release/${binary_name}.1" > "build/${target}-release/hex1"
        hexdump -C "build/${target}-release/${binary_name}" > "build/${target}-release/hex2"
        diff "build/${target}-release/hex1" "build/${target}-release/hex2"
        rm -f "build/${target}-release/hex1" "build/${target}-release/hex2"
        exit 1
    fi
    echo "✅ ${label} release builds match"

    # Print build hashes
    echo -e "\n${label} debug build hash:"
    sha256sum "build/${target}-debug/${binary_name}"
    echo -e "\n${label} release build hash:"
    sha256sum "build/${target}-release/${binary_name}"

    # Clean up intermediate files
    rm -f "build/${target}-debug/${binary_name}.1"
    rm -f "build/${target}-release/${binary_name}.1"
}

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build

# Build for all platforms
build_and_verify "linux-x86_64" "Linux" "myapp"
build_and_verify "windows-x86_64" "Windows" "myapp.exe"
build_and_verify "macos-x86_64" "macOS" "myapp.out"

echo -e "\n✅ All builds completed successfully!"