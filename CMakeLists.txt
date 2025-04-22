cmake_minimum_required(VERSION 3.15)
project(minimal_runtime LANGUAGES CXX)

# Option to control VC-LTL usage
option(USE_VC_LTL "Use VC-LTL to reduce binary size" ON)

# Download and configure VC-LTL first
if(MSVC AND USE_VC_LTL)
    # Allow custom VC-LTL path
    set(VC_LTL_PATH "${CMAKE_CURRENT_BINARY_DIR}/_deps/VC-LTL" CACHE PATH "Path to VC-LTL")

    # Download VC-LTL if not found
    if(NOT EXISTS "${VC_LTL_PATH}")
        set(VC_LTL_VERSION "v5.2.1")
        set(VC_LTL_URL "https://github.com/Chuyu-Team/VC-LTL5/releases/download/${VC_LTL_VERSION}/VC-LTL-Binary.7z")
        
        message(STATUS "Downloading VC-LTL ${VC_LTL_VERSION}")
        
        # Create _deps directory
        file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/_deps")
        file(MAKE_DIRECTORY ${VC_LTL_PATH})
        
        # Download and extract
        file(DOWNLOAD "${VC_LTL_URL}" "${CMAKE_CURRENT_BINARY_DIR}/_deps/vc-ltl.7z" SHOW_PROGRESS)
        
        # Extract using cmake -E tar command
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf "${CMAKE_CURRENT_BINARY_DIR}/_deps/vc-ltl.7z"
            WORKING_DIRECTORY ${VC_LTL_PATH}
        )
        
        # Cleanup download
        file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/_deps/vc-ltl.7z")
    endif()

    # Set Windows 7 as minimum target
    set(WindowsTargetPlatformMinVersion "6.1.7601.0" CACHE STRING "Target Windows platform minimum version")
    
    # Force VC-LTL root path
    set(VC_LTL_Root ${VC_LTL_PATH})
    
    # Include VC-LTL cmake helper BEFORE any compiler settings
    include("${VC_LTL_PATH}/VC-LTL helper for cmake.cmake")
endif()

# Enable Link Time Optimization
include(CheckIPOSupported)
check_ipo_supported(RESULT LTO_SUPPORTED)

# Global compiler settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Function to configure MSVC project settings
function(configure_msvc_project TARGET_NAME)
    if(MSVC)
        # Set static runtime linking
        set_property(TARGET ${TARGET_NAME} PROPERTY
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        
        # Add MinSizeRel and RelWithDebInfo configurations
        set(CMAKE_CONFIGURATION_TYPES "Debug;Release;MinSizeRel;RelWithDebInfo"
            CACHE STRING "Available build configurations" FORCE)
        
        # MinSizeRel specific optimizations for MSVC
        target_compile_options(${TARGET_NAME} PRIVATE
            $<$<CONFIG:MinSizeRel>:/O1>     # Minimize size
            $<$<CONFIG:MinSizeRel>:/Os>     # Favor size over speed
            $<$<CONFIG:MinSizeRel>:/GF>     # String pooling
            $<$<CONFIG:MinSizeRel>:/Gy>     # Function-level linking
            $<$<CONFIG:MinSizeRel>:/Gw>     # Optimize global data
            $<$<CONFIG:MinSizeRel>:/GR->    # Disable RTTI
        )
            
        # MinSizeRel linker flags
        target_link_options(${TARGET_NAME} PRIVATE
            $<$<CONFIG:MinSizeRel>:/OPT:REF>    # Remove unused functions
            $<$<CONFIG:MinSizeRel>:/OPT:ICF>    # Fold identical functions
            $<$<CONFIG:MinSizeRel>:/INCREMENTAL:NO>)

        # Enable LTO for MinSizeRel if supported
        if(LTO_SUPPORTED)
            set_property(TARGET ${TARGET_NAME} PROPERTY
                INTERPROCEDURAL_OPTIMIZATION_MINSIZE_REL TRUE)
        endif()
    endif()
endfunction()

# Create executable
add_executable(minimal_app src/main.cpp)

# Configure the project with optimization settings
configure_msvc_project(minimal_app)