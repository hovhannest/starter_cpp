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

# Detect if we're cross-compiling
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(CROSS_COMPILING FALSE)
else()
    set(CROSS_COMPILING TRUE)
    set(CMAKE_CROSSCOMPILING TRUE)
endif()

# Define system
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(TARGET_TRIPLE "x86_64-windows-gnu")

# Configure compiler settings based on compilation mode
if(CROSS_COMPILING)
    # Cross-compilation specific settings
    set(CMAKE_RC_COMPILER_WORKS 1)
    set(CMAKE_RC_COMPILER ${CMAKE_C_COMPILER})
    set(CMAKE_C_STANDARD_LIBRARIES "")
    set(CMAKE_CXX_STANDARD_LIBRARIES "")
endif()

# Configure Windows-specific settings
set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".lib")
set(CMAKE_LINK_LIBRARY_SUFFIX ".lib")
set(CMAKE_EXECUTABLE_SUFFIX ".exe")
set(CMAKE_LINK_DEF_FILE_FLAG "")  # Disable .def file generation

# Set up Zig executable path
if(CROSS_COMPILING)
    set(ZIG_EXE "${ZIG_PATH}/zig")
    set(CMAKE_C_COMPILER "${ZIG_PATH}/zig")
    set(CMAKE_CXX_COMPILER "${ZIG_PATH}/zig")
else()
    set(ZIG_EXE "${TOOLS_DIR}/zig/zig.exe")
    set(CMAKE_C_COMPILER "${TOOLS_DIR}/zig/zig.exe")
    set(CMAKE_CXX_COMPILER "${TOOLS_DIR}/zig/zig.exe")
endif()

# Configure archiver settings
set(CMAKE_AR "${ZIG_EXE}" CACHE FILEPATH "Archiver")
set(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> ar crs <TARGET> <OBJECTS>")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> ar crs <TARGET> <OBJECTS>")

# Force compiler ID and skip detection
set(CMAKE_C_COMPILER_ID "Clang")
set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

# Set basic compiler arguments with cross-platform path handling
file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}" CMAKE_SOURCE_DIR_NORMALIZED)
set(CMAKE_C_COMPILER_ARG1 "cc -target ${TARGET_TRIPLE}")
set(CMAKE_CXX_COMPILER_ARG1 "c++ -target ${TARGET_TRIPLE}")

# Common flags
set(BASE_FLAGS
    "-target ${TARGET_TRIPLE} \
     -fno-rtti \
     -ffunction-sections \
     -fdata-sections \
     -DWIN32")

# Add cross-compilation specific defines
if(CROSS_COMPILING)
    string(APPEND BASE_FLAGS
        " -D__MINGW32__ \
         -D__MINGW64__")
endif()

# Add optimization and debug-specific flags
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    string(APPEND BASE_FLAGS " -Wno-dll-attribute-on-redeclaration")
else()
    string(APPEND BASE_FLAGS " -O3")
endif()

# Set common flags
set(COMMON_FLAGS "${BASE_FLAGS}")

# Set initial flags
set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS}")

# Configure linker flags based on compilation mode
if(CROSS_COMPILING)
    set(CMAKE_EXE_LINKER_FLAGS_INIT "-target ${TARGET_TRIPLE} -static -s --no-dynamic-linker -Wl,/timestamp:0")
else()
    set(CMAKE_EXE_LINKER_FLAGS_INIT "-target ${TARGET_TRIPLE} -static -s -Wl,--gc-sections -Wl,--icf=all")
endif()
set(CMAKE_SHARED_LINKER_FLAGS_INIT "")

# Configure debug and release flags
set(CMAKE_C_FLAGS_DEBUG_INIT "-g -Wno-dll-attribute-on-redeclaration")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g -Wno-dll-attribute-on-redeclaration")
set(CMAKE_C_FLAGS_RELEASE_INIT "-O3 -DNDEBUG -fmerge-all-constants -fvisibility=hidden")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O3 -DNDEBUG -fmerge-all-constants -fvisibility=hidden")

# Set build flags for debug and release builds
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS} -g -Wno-dll-attribute-on-redeclaration")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS} -g -Wno-dll-attribute-on-redeclaration")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} -O3 -DNDEBUG -fmerge-all-constants -fvisibility=hidden")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O3 -DNDEBUG -fmerge-all-constants -fvisibility=hidden")

# Configure file path mapping
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")