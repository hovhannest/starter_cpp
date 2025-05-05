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

# Global compiler settings
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create runtime library
add_library(runtime STATIC src/runtime/printf.c)
configure_msvc_project(runtime)

# Create executable
add_executable(minimal_app src/main.c)
target_link_libraries(minimal_app PRIVATE runtime)

# Configure the project with optimization settings
configure_msvc_project(minimal_app)