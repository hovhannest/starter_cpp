# Setup paths
get_filename_component(SYSROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../../sysroot" ABSOLUTE)
get_filename_component(TOOLS_DIR "${SYSROOT_DIR}/tools" ABSOLUTE)

# Configure Zig environment
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

# Define system for cross-compilation
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(TARGET_TRIPLE "x86_64-windows-gnu")

# Disable resource compiler requirement
set(CMAKE_RC_COMPILER_WORKS 1)
set(CMAKE_RC_COMPILER ${CMAKE_C_COMPILER})

# Tell CMake not to add Unix-specific libraries
set(CMAKE_C_STANDARD_LIBRARIES "")
set(CMAKE_CXX_STANDARD_LIBRARIES "")
set(CMAKE_CROSSCOMPILING TRUE)

# Use Zig as both C and C++ compiler with proper Windows extension
if(WIN32)
    set(CMAKE_C_COMPILER "${ZIG_PATH}/zig.exe")
    set(CMAKE_CXX_COMPILER "${ZIG_PATH}/zig.exe")
else()
    set(CMAKE_C_COMPILER "${ZIG_PATH}/zig")
    set(CMAKE_CXX_COMPILER "${ZIG_PATH}/zig")
endif()

# Force compiler ID and skip detection
set(CMAKE_C_COMPILER_ID "Clang")
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

# Set basic compiler arguments with cross-platform path handling
file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}" CMAKE_SOURCE_DIR_NORMALIZED)
set(CMAKE_C_COMPILER_ARG1 "cc -target ${TARGET_TRIPLE}")
set(CMAKE_CXX_COMPILER_ARG1 "c++ -target ${TARGET_TRIPLE}")

# Common flags
set(COMMON_FLAGS
    "-target ${TARGET_TRIPLE} \
     -O3 \
     -fno-rtti \
     -ffunction-sections \
     -fdata-sections \
     -DWIN32 \
     -D__MINGW32__ \
     -D__MINGW64__")

# Set initial flags
set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS}")

# Force C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Link flags
# Configure linker flags for Windows executables
# Set PE timestamp to 0 for reproducible builds and avoid powershell dependency
set(CMAKE_EXE_LINKER_FLAGS_INIT "-target ${TARGET_TRIPLE} -static -s --no-dynamic-linker -Wl,/timestamp:0")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "")

# Ensure release flags are properly passed
set(CMAKE_C_FLAGS_RELEASE_INIT "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O3 -DNDEBUG")

# Set build flags for optimized release builds
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} -O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O3 -DNDEBUG")

# File path mapping and Windows settings
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
set(CMAKE_LINK_DEF_FILE_FLAG "")  # Disable .def file generation
set(CMAKE_EXECUTABLE_SUFFIX ".exe")