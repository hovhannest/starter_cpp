# Configure Git version and download URLs
set(GIT_VERSION "2.41.0")

if(WIN32)
    set(GIT_RELEASE "v${GIT_VERSION}.windows.3")
    set(GIT_FILE "PortableGit-${GIT_VERSION}.3-64-bit.7z.exe")
    set(GIT_URL "https://github.com/git-for-windows/git/releases/download/${GIT_RELEASE}/${GIT_FILE}")
    set(GIT_HASH "c2831df4c7fc61f0afe0231785119c3cf9b102c042fca6a36378b9999ffe1dfa")
elseif(APPLE)
    set(GIT_URL "https://github.com/git/git/releases/download/v${GIT_VERSION}/git-${GIT_VERSION}-darwin-x86_64.tar.gz")
    set(GIT_HASH "f0e3dd5c7fe09736d7fb7f76fc1843ebe93d1730ac1679f86d7714c01441cc9d")
else()
    set(GIT_URL "https://github.com/git/git/releases/download/v${GIT_VERSION}/git-${GIT_VERSION}-linux-x86_64.tar.gz")
    set(GIT_HASH "e2a4a486050db3dc01dea3d14933d781029ef125c1bce04b6e432f06f4195456")
endif()

# HermeticDependencies.cmake
#
# This module provides functionality for adding external dependencies in a hermetic way,
# ensuring reproducible builds by verifying content hashes and using a controlled Git environment.
#
# Usage:
# ```cmake
# add_hermetic_dependency(
#   NAME example_lib
#   GIT_REPOSITORY https://github.com/example/lib.git
#   GIT_TAG v1.0.0
#   EXPECTED_HASH 8d5f8d... # SHA256 hash of the source at the specified tag
# )
# ```

include(FetchContent)

# Ensure deterministic download behavior
set(FETCHCONTENT_QUIET OFF)
set(FETCHCONTENT_UPDATES_DISCONNECTED ON)

# Set up hermetic Git environment
function(setup_hermetic_git)
  set(GIT_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../sysroot/tools/git")
  set(GIT_EXE "${GIT_ROOT}/bin/git${CMAKE_EXECUTABLE_SUFFIX}")
  
  if(NOT EXISTS "${GIT_EXE}")
    message(STATUS "Downloading hermetic Git...")
    
    if(WIN32)
      set(GIT_ARCHIVE "${CMAKE_CURRENT_BINARY_DIR}/portable-git.exe")
      
      # Download portable Git using version-specific URL and hash
      file(DOWNLOAD "${GIT_URL}" "${GIT_ARCHIVE}"
           EXPECTED_HASH SHA256=${GIT_HASH}
           SHOW_PROGRESS
           STATUS DOWNLOAD_STATUS)
      
      list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
      if(NOT STATUS_CODE EQUAL 0)
        message(FATAL_ERROR "Failed to download Git")
      endif()
      
      # Extract portable Git (self-extracting 7z archive)
      file(MAKE_DIRECTORY "${GIT_ROOT}")
      execute_process(
        COMMAND "${GIT_ARCHIVE}" -y -o"${GIT_ROOT}"
        RESULT_VARIABLE EXTRACT_RESULT
      )
      if(NOT EXTRACT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to extract Git")
      endif()
      
      file(REMOVE "${GIT_ARCHIVE}")
      
    else()
      # For Unix systems, use already configured URL and hash
      set(GIT_ARCHIVE "${CMAKE_CURRENT_BINARY_DIR}/git.tar.gz")
      
      # Download minimal Git bundle
      file(DOWNLOAD "${GIT_URL}" "${GIT_ARCHIVE}"
           EXPECTED_HASH SHA256=${GIT_HASH}
           SHOW_PROGRESS
           STATUS DOWNLOAD_STATUS)
           
      list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
      if(NOT STATUS_CODE EQUAL 0)
        message(FATAL_ERROR "Failed to download Git")
      endif()
      
      # Extract Git
      file(MAKE_DIRECTORY "${GIT_ROOT}")
      execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "${GIT_ARCHIVE}"
        WORKING_DIRECTORY "${GIT_ROOT}"
        RESULT_VARIABLE EXTRACT_RESULT
      )
      if(NOT EXTRACT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to extract Git")
      endif()
      
      file(REMOVE "${GIT_ARCHIVE}")
    endif()
    
    # Verify Git works
    execute_process(
      COMMAND "${GIT_EXE}" --version
      RESULT_VARIABLE GIT_VERSION_RESULT
      OUTPUT_QUIET
      ERROR_QUIET
    )
    if(NOT GIT_VERSION_RESULT EQUAL 0)
      message(FATAL_ERROR "Hermetic Git installation failed")
    endif()
  endif()
  
  set(HERMETIC_GIT_EXE "${GIT_EXE}" PARENT_SCOPE)
endfunction()

# Set up hermetic Git before we use it
setup_hermetic_git()

# Create a hermetic way to include dependencies
function(add_hermetic_dependency)
  # Parse arguments
  set(options "")
  set(oneValueArgs NAME GIT_REPOSITORY GIT_TAG EXPECTED_HASH)
  set(multiValueArgs "")
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # Validate required arguments
  if(NOT ARG_NAME OR NOT ARG_GIT_REPOSITORY OR NOT ARG_GIT_TAG OR NOT ARG_EXPECTED_HASH)
    message(FATAL_ERROR "Required arguments missing in add_hermetic_dependency. Required: NAME GIT_REPOSITORY GIT_TAG EXPECTED_HASH")
  endif()

  set(DEPS_DIR "${CMAKE_BINARY_DIR}/deps")
  set(SOURCE_DIR "${DEPS_DIR}/src/${ARG_NAME}")
  set(HASH_FILE "${DEPS_DIR}/${ARG_NAME}.hash")

  # Configure fetch options using hermetic Git
  set(FETCH_OPTIONS
    GIT_REPOSITORY ${ARG_GIT_REPOSITORY}
    GIT_TAG ${ARG_GIT_TAG}
    GIT_SHALLOW ON
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR "${DEPS_DIR}/build/${ARG_NAME}"
    DOWNLOAD_NO_EXTRACT ON
    GIT_COMMAND "${HERMETIC_GIT_EXE}"
  )

  # Ensure consistent line endings
  if(WIN32)
    list(APPEND FETCH_OPTIONS GIT_CONFIG core.autocrlf=false)
  endif()

  # Declare the content that needs to be fetched
  FetchContent_Declare(${ARG_NAME} ${FETCH_OPTIONS})

  # Download the content but don't populate yet
  FetchContent_GetProperties(${ARG_NAME})
  if(NOT ${ARG_NAME}_POPULATED)
    message(STATUS "Downloading ${ARG_NAME}...")
    FetchContent_Populate(${ARG_NAME})

    # Calculate hash of downloaded content
    file(SHA256 "${SOURCE_DIR}" ACTUAL_HASH)
    
    # Verify hash before proceeding
    if(NOT "${ACTUAL_HASH}" STREQUAL "${ARG_EXPECTED_HASH}")
      message(FATAL_ERROR
        "Hash mismatch for ${ARG_NAME}:\n"
        "  Expected: ${ARG_EXPECTED_HASH}\n"
        "  Actual:   ${ACTUAL_HASH}\n"
        "This could indicate the source has been tampered with."
      )
      # Clean up failed download
      file(REMOVE_RECURSE "${SOURCE_DIR}")
      return()
    endif()

    # Save verified hash
    file(WRITE "${HASH_FILE}" "${ACTUAL_HASH}")
    
    message(STATUS "Hash verified for ${ARG_NAME}")
  endif()

  # Add the dependency to the project
  add_subdirectory("${SOURCE_DIR}" "${DEPS_DIR}/build/${ARG_NAME}")
endfunction()