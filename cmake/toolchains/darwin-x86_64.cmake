# Load Zig fetcher
include(${CMAKE_CURRENT_LIST_DIR}/../modules/FetchZig.cmake)
fetch_zig()

# Load and setup Ninja if it's the chosen generator
if(CMAKE_GENERATOR STREQUAL "Ninja")
    include(${CMAKE_CURRENT_LIST_DIR}/../modules/FetchNinja.cmake)
    fetch_ninja()
endif()

# Define the system name and processor for cross-compilation
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Set Zig as the compiler
set(CMAKE_C_COMPILER "${ZIG_PATH}/zig")
set(CMAKE_CXX_COMPILER "${ZIG_PATH}/zig")
set(CMAKE_C_COMPILER_ARG1 "cc")
set(CMAKE_CXX_COMPILER_ARG1 "c++")

# Set target triple for macOS x86_64
set(ZIG_TARGET_TRIPLE "x86_64-macos-gnu")
set(CMAKE_C_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})

# Configure compiler and linker flags for reproducible builds
set(COMMON_FLAGS "-target ${ZIG_TARGET_TRIPLE} \
    -fmacro-prefix-map=${CMAKE_SOURCE_DIR}=.")

set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS}")

# Force static linking and position independence
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -fPIC")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Disable rpath handling
set(CMAKE_SKIP_RPATH TRUE)

# macOS-specific flags for reproducible builds
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-dead_strip -Wl,-no_uuid")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")

# Set build flags for optimized release builds
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Configure the find root paths
set(CMAKE_FIND_ROOT_PATH ${ZIG_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)