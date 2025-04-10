#!/bin/bash
# reproduce.sh

set -euo pipefail

# Force deterministic environment
export TZ=UTC
export LC_ALL=C
export CMAKE_BUILD_PARALLEL_LEVEL=1
export PATH="${PWD}/sysroot/tools/zig:${PWD}/sysroot/tools/ninja:${PWD}/sysroot/tools/cmake-3.27.0/bin:${PATH}"

# Clean any previous builds
rm -rf build-1 build-2

# First build
mkdir -p build-1
cd build-1
cmake -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/linux-x86_64.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_C_COMPILER_WORKS=ON \
    -DCMAKE_CXX_COMPILER_WORKS=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_COLOR_DIAGNOSTICS=OFF \
    .. || exit 1
cmake --build . || exit 1
cp myapp ../myapp-1
cd ..

# Second build
mkdir -p build-2
cd build-2
cmake -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/linux-x86_64.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_C_COMPILER_WORKS=ON \
    -DCMAKE_CXX_COMPILER_WORKS=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_COLOR_DIAGNOSTICS=OFF \
    .. || exit 1
cmake --build . || exit 1
cp myapp ../myapp-2
cd ..

# Compare the two builds
if cmp -s myapp-1 myapp-2; then
  echo "✅ Builds are identical"
  CHECKSUM=$(sha256sum myapp-1)
  echo "${CHECKSUM}"
  
  # Clean up artifacts since builds match
  rm -rf build-1 build-2 myapp-1 myapp-2
  echo "Cleaned up build artifacts"
else
  echo "❌ Builds differ"
  echo "First build:"
  sha256sum myapp-1
  echo "Second build:"
  sha256sum myapp-2
  exit 1
fi