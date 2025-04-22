cmake_minimum_required(VERSION 3.15)
project(minimal_runtime LANGUAGES CXX)

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
            $<$<CONFIG:MinSizeRel>:/EHs-c->) # Disable exceptions
            
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