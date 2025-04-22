cmake_minimum_required(VERSION 3.15)
project(minimal_runtime LANGUAGES C)

# Option to control VC-LTL usage
option(USE_VC_LTL "Use VC-LTL to reduce binary size" ON)

# Include MSVC-specific configurations
include(cmake/msvc_config.cmake)

# Setup CPM
include(FetchContent)
set(CPM_DOWNLOAD_VERSION 0.40.8)
if(CPM_SOURCE_CACHE)
  set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
elseif(DEFINED ENV{HOME})
  set(CPM_DOWNLOAD_LOCATION "$ENV{HOME}/.cache/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
else()
  set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()

if(NOT (EXISTS ${CPM_DOWNLOAD_LOCATION}))
  message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
  file(DOWNLOAD
    https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
    ${CPM_DOWNLOAD_LOCATION}
  )
endif()
include(${CPM_DOWNLOAD_LOCATION})

# Add zenoh-pico 1.3.3
CPMAddPackage(
  NAME zenoh-pico
  GITHUB_REPOSITORY eclipse-zenoh/zenoh-pico
  VERSION 1.3.3
  GIT_TAG 1.3.3
  OPTIONS
    "BUILD_SHARED_LIBS OFF"
    "BUILD_TOOLS OFF"
    "BUILD_EXAMPLES OFF"
    "BUILD_TESTING OFF"
)

# Global compiler settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create executable
add_executable(minimal_app src/main.c)

# Link zenoh-pico library
if(TARGET zenohpico::lib)
  message(STATUS "Found zenoh-pico target")
  target_link_libraries(minimal_app PRIVATE zenohpico::lib)
else()
  # Diagnostic output
  get_property(targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
  message(STATUS "Available targets: ${targets}")
  message(FATAL_ERROR "zenoh-pico target not found - check build logs")
endif()

# Configure the project with optimization settings
configure_msvc_project(minimal_app)