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

# Set MSVC runtime before any targets
if(MSVC)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

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
    "Z_FEATURE_PUBLICATION:BOOL=ON"
    "Z_FEATURE_SUBSCRIPTION:BOOL=ON"
    "Z_FEATURE_QUERYABLE:BOOL=OFF"
    "Z_FEATURE_QUERY:BOOL=OFF"
    "Z_FEATURE_MULTI_THREAD:BOOL=OFF"
    "Z_FEATURE_RAWETH_TRANSPORT:BOOL=OFF"
    "Z_FEATURE_UNIX_TRANSPORT:BOOL=OFF"
    "Z_FEATURE_UDP_MULTICAST:BOOL=ON"
    "Z_FEATURE_UDP_UNICAST:BOOL=ON"
    "Z_FEATURE_MATCHING:BOOL=OFF"
    "Z_FEATURE_BATCHING:BOOL=OFF"
    "Z_FEATURE_FRAGMENTATION:BOOL=OFF"
    "Z_FEATURE_ENCODING_VALUES:BOOL=OFF"
    "Z_FEATURE_INTEREST:BOOL=OFF"
    "Z_FEATURE_LIVELINESS:BOOL=OFF"
    "Z_FEATURE_AUTO_RECONNECT:BOOL=OFF"
    "Z_FEATURE_LINK_TCP:BOOL=OFF"
    "Z_FEATURE_SCOUTING_UDP:BOOL=OFF"
    "Z_FEATURE_SESSION_CHECK:BOOL=OFF"
    "Z_FEATURE_TCP_NODELAY:BOOL=OFF"
    "Z_FEATURE_UNICAST_PEER:BOOL=OFF"
    "Z_FEATURE_LOCAL_SUBSCRIBER:BOOL=OFF"
    "Z_FEATURE_MULTICAST_TRANSPORT:BOOL=OFF"
    "Z_FEATURE_UNICAST_TRANSPORT:BOOL=OFF"
)

if(TARGET zenohpico)
    configure_msvc_project(zenohpico)
endif()

# Global compiler settings
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Force MinSizeRel as the default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE MinSizeRel CACHE STRING "Build type" FORCE)
endif()

# Global optimization flags for size
if(MSVC)
    add_compile_options(
        $<$<CONFIG:Release,MinSizeRel>:/O1>
        $<$<CONFIG:Release,MinSizeRel>:/Os>
        $<$<CONFIG:Release,MinSizeRel>:/GL>
        $<$<CONFIG:Release,MinSizeRel>:/GS->
    )
    add_link_options(
        $<$<CONFIG:Release,MinSizeRel>:/LTCG>
        $<$<CONFIG:Release,MinSizeRel>:/OPT:REF>
        $<$<CONFIG:Release,MinSizeRel>:/OPT:ICF>
        $<$<CONFIG:Release,MinSizeRel>:/MANIFEST:NO>
        $<$<CONFIG:Release,MinSizeRel>:/LARGEADDRESSAWARE:NO>
    )

    # Force IPO for all targets in MinSizeRel
    if(LTO_SUPPORTED)
        set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            PROPERTY INTERPROCEDURAL_OPTIMIZATION_MINSIZE_REL TRUE)
    endif()
endif()

# Create runtime library
add_library(runtime STATIC src/runtime/printf.c)
configure_msvc_project(runtime)

# Create executable
add_executable(minimal_app src/main.c)
target_link_libraries(minimal_app PRIVATE runtime)

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