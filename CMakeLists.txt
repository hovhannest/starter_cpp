cmake_minimum_required(VERSION 3.23)

# Include modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
include(BuildHardening)
include(BinaryOptimizations)
include(FetchContent)

# Enable testing
enable_testing()

# Define the project
project(MyHermeticProject VERSION 1.0.0 LANGUAGES CXX C)

# Configure Windows-specific settings
if(WIN32)
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_SUFFIX ".lib")
endif()

# Add GTest
set(GTEST_CXX_STANDARD 17)
set(GTEST_CXX_STANDARD_REQUIRED ON)
set(BUILD_GMOCK ON)
set(BUILD_GTEST ON)
set(gtest_force_shared_crt ON)

FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG v1.16.0
)
FetchContent_MakeAvailable(googletest)

# Ensure proper library names on Windows
if(WIN32)
    set_target_properties(gtest PROPERTIES OUTPUT_NAME "gtest")
    set_target_properties(gtest_main PROPERTIES OUTPUT_NAME "gtest_main")
    if(TARGET gmock)
        set_target_properties(gmock PROPERTIES OUTPUT_NAME "gmock")
    endif()
    if(TARGET gmock_main)
        set_target_properties(gmock_main PROPERTIES OUTPUT_NAME "gmock_main")
    endif()
endif()

# Force C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Override CMake's default flags
set(CMAKE_CXX_FLAGS_INIT "")
set(CMAKE_CXX_FLAGS "")
set(CMAKE_CXX_FLAGS_RELEASE "")

# Create executable target
add_executable(myapp src/main.cpp)

# Ensure CMake doesn't add its default flags
set_target_properties(myapp PROPERTIES
  LINK_FLAGS ""
  LINK_FLAGS_RELEASE ""
)

# Apply hardening
force_source_file_ordering(myapp)

# Set PE timestamp for Windows builds
if(WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set_pe_timestamp(myapp)
endif()

# Configure version info
target_compile_definitions(myapp PRIVATE
  PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
  PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
  PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
)

# Example of a minimal target without CRT
add_executable(minimal_app src/minimal_main.cpp)
target_minimal_binary(minimal_app)
target_compile_definitions(minimal_app PRIVATE __linux__)

# Regular targets remain unchanged (using CRT)
add_executable(myapp_test tests/main_test.cpp)
target_link_libraries(myapp_test PRIVATE gtest_main)
add_test(NAME myapp_test COMMAND myapp_test)
