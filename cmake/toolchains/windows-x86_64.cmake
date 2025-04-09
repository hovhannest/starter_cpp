# Load Zig fetcher
include(${CMAKE_CURRENT_LIST_DIR}/../modules/FetchZig.cmake)
fetch_zig()

# Load and setup Ninja if it's the chosen generator
if(CMAKE_GENERATOR STREQUAL "Ninja")
    include(${CMAKE_CURRENT_LIST_DIR}/../modules/FetchNinja.cmake)
    fetch_ninja()
endif()

# Define system
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(TARGET_TRIPLE "x86_64-windows")

# Use Zig as both C and C++ compiler
set(CMAKE_C_COMPILER "${ZIG_PATH}/zig.exe")
set(CMAKE_CXX_COMPILER "${ZIG_PATH}/zig.exe")

# Force compiler ID and skip detection
set(CMAKE_C_COMPILER_ID "Clang")
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

# Set basic compiler arguments
set(CMAKE_C_COMPILER_ARG1 "cc -fdebug-compilation-dir=.")
set(CMAKE_CXX_COMPILER_ARG1 "c++ -fdebug-compilation-dir=.")

# Common flags
set(COMMON_FLAGS
    "-target ${TARGET_TRIPLE} \
     -O3 \
     -fno-rtti \
     -ffunction-sections \
     -fdata-sections \
     -fno-unwind-tables \
     -fno-asynchronous-unwind-tables \
     -fmacro-prefix-map=${CMAKE_SOURCE_DIR}=. \
     -fno-pdb-source-path-map")

# Set initial flags
set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS}")

# Force C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Link flags
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static -s -Wl,--image-base=0x140000000")

# Ensure release flags are properly passed
set(CMAKE_C_FLAGS_RELEASE_INIT "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O3 -DNDEBUG")

# Set build flags for optimized release builds
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} -O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O3 -DNDEBUG")

# File path mapping for reproducible builds
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")

# Executables on Windows end in .exe
set(CMAKE_EXECUTABLE_SUFFIX ".exe")