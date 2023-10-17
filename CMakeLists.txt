cmake_minimum_required(VERSION 3.12)

project(HelloWorldApp)

# Set the C++ standard to C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Option to enable testing
option(ENABLE_TESTING "Enable testing" ON)

if (ENABLE_TESTING)
    # Include testing-related code
    include(CTest)
    enable_testing()

    # Set the installation path for Google Test relative to the root CMakeLists.txt
    set(GTEST_INSTALL_DIR ${CMAKE_BINARY_DIR}/gtest)
    
    # Download and build Google Test as an external project
    include(ExternalProject)
    ExternalProject_Add(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG release-1.12.1 # Updated to a newer version of Google Test
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${GTEST_INSTALL_DIR}
    )

    # Add the Google Test include and lib directories to your project
    ExternalProject_Get_Property(googletest source_dir binary_dir)
    include_directories(${GTEST_INSTALL_DIR}/include)
    link_directories(${GTEST_INSTALL_DIR}/lib)

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
