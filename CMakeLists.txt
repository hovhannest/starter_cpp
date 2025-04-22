cmake_minimum_required(VERSION 3.15)
project(minimal_runtime LANGUAGES CXX)

# Option to control VC-LTL usage
option(USE_VC_LTL "Use VC-LTL to reduce binary size" ON)

# Include MSVC-specific configurations
include(cmake/msvc_config.cmake)

# Global compiler settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create executable
add_executable(minimal_app src/main.cpp)

# Configure the project with optimization settings
configure_msvc_project(minimal_app)