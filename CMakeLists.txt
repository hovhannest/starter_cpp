cmake_minimum_required(VERSION 3.15)
project(medit VERSION 0.0.1 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for tooling
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Option to build tests
option(CMAKE_BUILD_TESTS "Build tests" ON)

# Sanitizer options
option(CMAKE_BUILD_ASAN "Build with AddressSanitizer" OFF)
option(CMAKE_BUILD_TSAN "Build with ThreadSanitizer" OFF)
option(CMAKE_BUILD_UBSAN "Build with UndefinedBehaviorSanitizer" OFF)
option(CMAKE_BUILD_TIDY "Run clang-tidy during build" OFF)

if(CMAKE_BUILD_ASAN AND CMAKE_BUILD_TSAN)
    message(FATAL_ERROR "CMAKE_BUILD_ASAN and CMAKE_BUILD_TSAN are mutually exclusive.")
endif()

if(CMAKE_BUILD_TIDY)
    find_program(CLANG_TIDY_EXE NAMES clang-tidy)
    if(CLANG_TIDY_EXE)
        set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY_EXE})
    else()
        message(WARNING "clang-tidy not found, CMAKE_BUILD_TIDY will be ignored.")
    endif()
endif()

# Find dependencies from Conan
# These are automatically available via CMakeDeps generator
# Example: uncomment when you add dependencies to conanfile.py
# find_package(fmt REQUIRED)
# find_package(spdlog REQUIRED)

# Main library/executable
add_executable(${PROJECT_NAME}
    src/main.cpp
)

# Link dependencies
# target_link_libraries(${PROJECT_NAME} PRIVATE
#     fmt::fmt
#     spdlog::spdlog
# )

# Include directories
target_include_directories(${PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Compiler warnings and sanitizers
if(MSVC)
    # Pure MSVC (not clang-cl)
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        target_compile_options(${PROJECT_NAME} PRIVATE /W4 /WX)
    else()
        # clang-cl: Clang with MSVC-compatible driver
        target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic -Werror)

        if(CMAKE_BUILD_ASAN)
            target_compile_options(${PROJECT_NAME} PRIVATE /fsanitize=address)
            # For clang-cl, we need to explicitly link the ASan runtime library
            # Get the Clang resource directory
            execute_process(
                COMMAND ${CMAKE_CXX_COMPILER} --print-resource-dir
                OUTPUT_VARIABLE CLANG_RESOURCE_DIR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            # Link the static ASan runtime library
            target_link_libraries(${PROJECT_NAME} PRIVATE
                "${CLANG_RESOURCE_DIR}/lib/windows/clang_rt.asan_dynamic-x86_64.lib"
                "${CLANG_RESOURCE_DIR}/lib/windows/clang_rt.asan_dynamic_runtime_thunk-x86_64.lib"
            )
        endif()

        if(CMAKE_BUILD_TSAN)
            target_compile_options(${PROJECT_NAME} PRIVATE /fsanitize=thread)
            target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=thread)
        endif()

        if(CMAKE_BUILD_UBSAN)
            target_compile_options(${PROJECT_NAME} PRIVATE /fsanitize=undefined)
            target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=undefined)
        endif()
    endif()
else()
    # Unix-style compilers (GCC, Clang)
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic -Werror)

    if(CMAKE_BUILD_ASAN)
        target_compile_options(${PROJECT_NAME} PRIVATE -fsanitize=address)
        target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=address)
    endif()

    if(CMAKE_BUILD_TSAN)
        target_compile_options(${PROJECT_NAME} PRIVATE -fsanitize=thread)
        target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=thread)
    endif()

    if(CMAKE_BUILD_UBSAN)
        target_compile_options(${PROJECT_NAME} PRIVATE -fsanitize=undefined)
        target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=undefined)
    endif()
endif()

# Tests
if(CMAKE_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(DIRECTORY include/
    DESTINATION include
)
