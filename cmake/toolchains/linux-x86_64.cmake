# Setup paths
get_filename_component(SYSROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../../sysroot" ABSOLUTE)
get_filename_component(TOOLS_DIR "${SYSROOT_DIR}/tools" ABSOLUTE)

# Configure Zig environment with reproducible build settings
set(ENV{SOURCE_DATE_EPOCH} "0")
set(ENV{TZ} "UTC")
set(ENV{LC_ALL} "C")
set(ENV{ZIG_LIB_DIR} "${TOOLS_DIR}/zig/lib")
set(ENV{ZIG_GLOBAL_CACHE_DIR} "${SYSROOT_DIR}/.zigcache")
set(ENV{ZIG_LOCAL_CACHE_DIR} "${SYSROOT_DIR}/.zigcache")

# Ensure cache directory exists
file(MAKE_DIRECTORY "${SYSROOT_DIR}/.zigcache")

# Load Zig fetcher
include(${CMAKE_CURRENT_LIST_DIR}/../modules/FetchZig.cmake)
fetch_zig()

# Load and setup Ninja if it's the chosen generator
if(CMAKE_GENERATOR STREQUAL "Ninja")
    include(${CMAKE_CURRENT_LIST_DIR}/../modules/FetchNinja.cmake)
    fetch_ninja()
endif()

# Detect if we're cross-compiling
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(CROSS_COMPILING FALSE)
else()
    set(CROSS_COMPILING TRUE)
    set(CMAKE_CROSSCOMPILING TRUE)
endif()

# Define the system for cross-compilation
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(ZIG_TARGET_TRIPLE "x86_64-linux-musl")

# Set paths based on host system
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(ZIG_EXE "zig.exe")
else()
    set(ZIG_EXE "zig")
endif()

# Configure build environment
if(CROSS_COMPILING)
    set(CMAKE_C_COMPILER "${TOOLS_DIR}/zig/${ZIG_EXE}")
    set(CMAKE_CXX_COMPILER "${TOOLS_DIR}/zig/${ZIG_EXE}")
    set(ENV{ZIG_LOCAL_CACHE_DIR} "${SYSROOT_DIR}/.zigcache")
    set(ENV{ZIG_GLOBAL_CACHE_DIR} "${SYSROOT_DIR}/.zigcache")
endif()

# Force compiler ID and skip detection
set(CMAKE_C_COMPILER_ID "Clang")
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

# Set compiler
if(NOT CROSS_COMPILING)
    set(CMAKE_C_COMPILER "${ZIG_PATH}/zig")
    set(CMAKE_CXX_COMPILER "${ZIG_PATH}/zig")
else()
    set(CMAKE_C_COMPILER "${TOOLS_DIR}/zig/${ZIG_EXE}")
    set(CMAKE_CXX_COMPILER "${TOOLS_DIR}/zig/${ZIG_EXE}")
endif()

# Configure archiver settings
if(NOT CROSS_COMPILING)
    set(CMAKE_AR "${ZIG_PATH}/zig" CACHE FILEPATH "Archiver")
else()
    set(CMAKE_AR "${TOOLS_DIR}/zig/${ZIG_EXE}" CACHE FILEPATH "Archiver")
endif()
set(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> ar crs <TARGET> <OBJECTS>")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> ar crs <TARGET> <OBJECTS>")

# Set compiler arguments
set(CMAKE_C_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})
set(CMAKE_C_COMPILER_ARG1 "cc --target=${ZIG_TARGET_TRIPLE}")
set(CMAKE_CXX_COMPILER_ARG1 "c++ --target=${ZIG_TARGET_TRIPLE}")

# Configure flags for reproducible builds
set(COMMON_FLAGS
    "-target ${ZIG_TARGET_TRIPLE} \
     -fno-PIC \
     -fno-rtti \
     -fno-common \
     -ffunction-sections \
     -fdata-sections \
     -fno-plt \
     -fsanitize=cfi \
     -fstack-protector-strong \
     -fcf-protection=full \
     -no-canonical-prefixes \
     -fno-use-cxa-atexit \
     -fno-addrsig \
     -Wno-builtin-macro-redefined \
     -D__DATE__=\"redacted\" \
     -D__TIME__=\"redacted\" \
     -D__TIMESTAMP__=\"redacted\" \
     -D__FILE__=redacted")

# Configure path mapping for reproducible builds
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
   # Convert Windows paths to Unix style for cross-compilation
   file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}" CMAKE_SOURCE_DIR_NORMALIZED)
   string(REPLACE ":" "" CMAKE_SOURCE_DIR_NORMALIZED "${CMAKE_SOURCE_DIR_NORMALIZED}")
   string(APPEND COMMON_FLAGS " -ffile-prefix-map=//${CMAKE_SOURCE_DIR_NORMALIZED}=.")
else()
   file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}" CMAKE_SOURCE_DIR_NORMALIZED)
   string(APPEND COMMON_FLAGS " -ffile-prefix-map=${CMAKE_SOURCE_DIR_NORMALIZED}=.")
endif()

# Add build type specific flags
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    string(APPEND COMMON_FLAGS " -g")
else()
    string(APPEND COMMON_FLAGS " -O3")
endif()

set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS}")

# Configure linker flags for reproducible builds
set(CMAKE_EXE_LINKER_FLAGS_INIT "-target ${ZIG_TARGET_TRIPLE} \
    -static -s -fPIC \
    -Wl,--build-id=none \
    -Wl,-z,relro,-z,now")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "")

# Disable rpath handling
set(CMAKE_SKIP_RPATH TRUE)

# Configure path mapping for reproducible builds
file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}" CMAKE_SOURCE_DIR_NORMALIZED)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR_NORMALIZED}=.")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR_NORMALIZED}=.")

# Set build flags for debug and release builds
set(CMAKE_C_FLAGS_DEBUG_INIT "-g")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g")
set(CMAKE_C_FLAGS_RELEASE_INIT "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O3 -DNDEBUG")


# Configure the find root paths
set(CMAKE_FIND_ROOT_PATH ${ZIG_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)