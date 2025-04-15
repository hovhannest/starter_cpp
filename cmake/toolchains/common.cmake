# Setup paths
get_filename_component(SYSROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../../sysroot" ABSOLUTE)
get_filename_component(TOOLS_DIR "${SYSROOT_DIR}/tools" ABSOLUTE)

# Configure environment variables for reproducible builds
set(ENV{SOURCE_DATE_EPOCH} "0")
set(ENV{TZ} "UTC")
set(ENV{LC_ALL} "C")
set(ENV{ZIG_LIB_DIR} "${TOOLS_DIR}/zig/lib")

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

# Set paths based on host system
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(ZIG_EXE "zig.exe")
else()
    set(ZIG_EXE "zig")
endif()

# Set cache directories for Zig
set(ENV{ZIG_LOCAL_CACHE_DIR} "${SYSROOT_DIR}/.zigcache")
set(ENV{ZIG_GLOBAL_CACHE_DIR} "${SYSROOT_DIR}/.zigcache")

# Force compiler ID and skip detection
set(CMAKE_C_COMPILER_ID "Clang")
set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

# Detect if we're cross-compiling (to be set after CMAKE_SYSTEM_NAME is defined by platform)
macro(setup_cross_compiling TARGET_SYSTEM)
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL ${TARGET_SYSTEM})
        set(CROSS_COMPILING FALSE)
    else()
        set(CROSS_COMPILING TRUE)
        set(CMAKE_CROSSCOMPILING TRUE)
    endif()
endmacro()

# Set compiler paths
macro(setup_compiler_paths)
    if(NOT CROSS_COMPILING)
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
            set(COMPILER_PATH "${ZIG_PATH}/zig.exe")
        else()
            set(COMPILER_PATH "${ZIG_PATH}/zig")
        endif()
    else()
        set(COMPILER_PATH "${TOOLS_DIR}/zig/${ZIG_EXE}")
    endif()

    set(CMAKE_C_COMPILER "${COMPILER_PATH}")
    set(CMAKE_CXX_COMPILER "${COMPILER_PATH}")

    # Configure archiver settings
    set(CMAKE_AR "${COMPILER_PATH}" CACHE FILEPATH "Archiver")
    set(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> ar crs <TARGET> <OBJECTS>")
    set(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> ar crs <TARGET> <OBJECTS>")
endmacro()

# Setup compiler arguments
macro(setup_compiler_args)
    # Set target triple for both compilers
    set(CMAKE_C_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})
    set(CMAKE_CXX_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})
    
    # Base compiler arguments
    set(COMPILER_ARGS "cc --target=${ZIG_TARGET_TRIPLE}")
    set(CXX_COMPILER_ARGS "c++ --target=${ZIG_TARGET_TRIPLE}")
    
    # Handle cross-compilation sysroot settings
    if(CROSS_COMPILING)
        if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
            set(COMPILER_ARGS "${COMPILER_ARGS} --sysroot=none")
            set(CXX_COMPILER_ARGS "${CXX_COMPILER_ARGS} --sysroot=none")
        endif()
    endif()
    
    # Set final compiler arguments
    set(CMAKE_C_COMPILER_ARG1 "${COMPILER_ARGS}")
    set(CMAKE_CXX_COMPILER_ARG1 "${CXX_COMPILER_ARGS}")
endmacro()

# Configure common flags for reproducible builds
set(COMMON_FLAGS_BASE
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
   string(APPEND COMMON_FLAGS_BASE " -ffile-prefix-map=//${CMAKE_SOURCE_DIR_NORMALIZED}=.")
else()
   file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}" CMAKE_SOURCE_DIR_NORMALIZED)
   string(APPEND COMMON_FLAGS_BASE " -ffile-prefix-map=${CMAKE_SOURCE_DIR_NORMALIZED}=.")
endif()

# Add build type specific flags
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    string(APPEND COMMON_FLAGS_BASE " -g")
else()
    string(APPEND COMMON_FLAGS_BASE " -O3")
endif()

# Set build flags for debug and release builds
set(CMAKE_C_FLAGS_DEBUG_INIT "-g")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g")
set(CMAKE_C_FLAGS_RELEASE_INIT "-O3 -DNDEBUG -fmerge-all-constants -fvisibility=hidden")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O3 -DNDEBUG -fmerge-all-constants -fvisibility=hidden")

# Common function to set compiler flags
function(set_common_compiler_flags)
    set(COMMON_FLAGS "${COMMON_FLAGS_BASE} ${PLATFORM_SPECIFIC_FLAGS}" PARENT_SCOPE)
    set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS}" PARENT_SCOPE)
endfunction()

# Configure linker flags for Zig compiler (works across all platforms)
macro(setup_linker_flags)
    set(LINKER_FLAGS_BASE "-target ${ZIG_TARGET_TRIPLE} -static \
        -Wl,--gc-sections \
        -Wl,--icf=all")

    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        string(APPEND LINKER_FLAGS_BASE " -s")
    endif()
    
    set(CMAKE_EXE_LINKER_FLAGS_INIT "${LINKER_FLAGS_BASE}")
    set(CMAKE_SHARED_LINKER_FLAGS_INIT "")
endmacro()

# Configure shared settings including linker flags
macro(setup_shared_settings)
    setup_linker_flags()
    set(CMAKE_SKIP_RPATH TRUE)
    set(CMAKE_C_COMPILER_FORCED TRUE)
    set(CMAKE_CXX_COMPILER_FORCED TRUE)
    set(CMAKE_CXX_COMPILE_FEATURES "cxx_std_14")
endmacro()

# Configure the find root paths
macro(setup_find_root_paths)
    set(CMAKE_FIND_ROOT_PATH ${ZIG_ROOT})
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
endmacro()