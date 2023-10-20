cmake_minimum_required(VERSION 3.12)

project(HelloWorldApp)

# Set the C++ standard to C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(cmake/cpm.cmake)

if (CMAKE_SYSTEM_NAME MATCHES "Windows")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd")
endif()

# treat all warnings as errors
if (MSVC)
    add_compile_options(/Wall /WX /wd4668 /wd4711 /wd4710)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# Option to enable testing
option(ENABLE_TESTING "Enable testing" ON)

# Option to specify the GTest installation directory
set(GTEST_INSTALL_DIR "" CACHE PATH "Path to Google Test installation directory")

if (ENABLE_TESTING)
    enable_testing()

    if (MSVC)
        target_compile_options(test_hello_world PRIVATE /wd5026 /wd5027 /wd5039 /wd4625 /wd4626 /wd4365 wd/4820 /wd4514)
    endif()
    CPMAddPackage(
        NAME googletest
        GITHUB_REPOSITORY google/googletest
        GIT_TAG release-1.12.1
        VERSION 1.12.1
        OPTIONS "INSTALL_GTEST OFF" "gtest_force_shared_crt"
    )

    add_subdirectory(test) # Include the test subdirectory
endif()

# Add an executable for the main application
add_executable(hello_world src/main.cpp)

# Add a function library
add_library(my_functions src/foo.cpp)

# Include directories for headers
target_include_directories(my_functions PUBLIC include)

# Link the executable with the function library
target_link_libraries(hello_world my_functions)
