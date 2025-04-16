# Include common settings
include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)

# Define the system for cross-compilation
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(ZIG_TARGET_TRIPLE "x86_64-macos-none")

# Setup cross compilation detection
setup_cross_compiling(${CMAKE_SYSTEM_NAME})

# Prevent using system SDK
set(CMAKE_OSX_SYSROOT "")
set(CMAKE_OSX_DEPLOYMENT_TARGET "")

# Darwin-specific compiler settings
set(CMAKE_C_COMPILER_FRONTEND_VARIANT "GNU")
set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "GNU")

# Setup compiler paths and arguments
setup_compiler_paths()
setup_compiler_args()

# Set platform specific flags and apply common compiler flags
set(PLATFORM_SPECIFIC_FLAGS "-D__APPLE__")
set_common_compiler_flags()

# Setup shared settings including linker flags
setup_shared_settings()

# Setup find root paths
setup_find_root_paths()