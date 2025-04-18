cmake_minimum_required(VERSION 3.15)

project(MSVCDemoProject LANGUAGES CXX)

# Common target configurations
function(configure_common_target target)
    # Set C++ standard (can be overridden by calling code)
    set_target_properties(${target} PROPERTIES
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED ON
        LINK_SEARCH_START_STATIC ON
        LINK_SEARCH_END_STATIC ON)
endfunction()

# Include MSVC toolchain configuration
include(cmake/MSVCToolchain.cmake)

# Only add MSVC target if MSVC is available
if(MSVC)
    # Add executable target
    add_executable(demo main.cpp)

    # Apply common configurations
    configure_common_target(demo)

    # Apply MSVC-specific configurations
    configure_msvc_minimal(demo)
else()
    message(WARNING "MSVC compiler not found - skipping MSVC-specific targets")
endif()