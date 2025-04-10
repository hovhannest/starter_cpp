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

# Create executable target
add_executable(myapp src/main.cpp)

# Apply hardening
force_source_file_ordering(myapp)

# Configure version info
target_compile_definitions(myapp PRIVATE
  PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
  PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
  PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
)
