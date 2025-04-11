cmake_minimum_required(VERSION 3.23)

# Set SOURCE_DATE_EPOCH for reproducible builds
if(NOT DEFINED ENV{SOURCE_DATE_EPOCH})
    set(ENV{SOURCE_DATE_EPOCH} "0")
endif()

# Include hardening module before defining project
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
include(BuildHardening)

# Define the project
project(MyHermeticProject VERSION 1.0.0 LANGUAGES CXX C)

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

# Configure version info
target_compile_definitions(myapp PRIVATE
  PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
  PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
  PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
)
