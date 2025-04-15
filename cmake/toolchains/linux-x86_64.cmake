# Include common settings
include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)

# Define the system for cross-compilation
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(ZIG_TARGET_TRIPLE "x86_64-linux-musl")

# Setup cross compilation detection
setup_cross_compiling(${CMAKE_SYSTEM_NAME})

# Setup compiler paths and arguments
setup_compiler_paths()
setup_compiler_args()

# Set platform specific flags and apply common compiler flags
set(PLATFORM_SPECIFIC_FLAGS "")
set_common_compiler_flags()

# Setup shared settings including linker flags
setup_shared_settings()

# Setup find root paths
setup_find_root_paths()