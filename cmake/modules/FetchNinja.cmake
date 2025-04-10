# Configure Ninja version and downloads
set(NINJA_VERSION "1.12.1")
set(NINJA_DOWNLOAD_BASE "https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}")

# Platform-specific configuration
if(WIN32)
    set(NINJA_PLATFORM "win")
    set(NINJA_ARCHIVE_EXT "zip")
    set(NINJA_HASH "f550fec705b6d6ff58f2db3c374c2277a37691678d6aba463adcbb129108467a")
elseif(APPLE)
    set(NINJA_PLATFORM "mac")
    set(NINJA_ARCHIVE_EXT "zip")
    set(NINJA_HASH "482ecb23c59ae88e1a77d6e4d52e931c9a18ee0366c898969d01d6516c467335")
else()
    set(NINJA_PLATFORM "linux")
    set(NINJA_ARCHIVE_EXT "zip")
    set(NINJA_HASH "6f98805688d19672bd699fbbfa2c2cf0fc054ac3df1f0e6a47664d963d530255")
endif()

# Setup paths
set(NINJA_ARCHIVE "ninja-${NINJA_PLATFORM}.${NINJA_ARCHIVE_EXT}")
set(NINJA_URL "${NINJA_DOWNLOAD_BASE}/${NINJA_ARCHIVE}")
set(NINJA_DIR "${CMAKE_CURRENT_LIST_DIR}/../../sysroot/tools")
get_filename_component(NINJA_DIR ${NINJA_DIR} ABSOLUTE)
set(NINJA_PATH "${NINJA_DIR}/ninja")
set(NINJA_DOWNLOAD "${NINJA_DIR}/${NINJA_ARCHIVE}")

# Function to install Ninja
function(fetch_ninja)
    # Ensure directory exists
    file(MAKE_DIRECTORY "${NINJA_DIR}")

    # Check if Ninja is already installed
    if(WIN32)
        set(NINJA_EXE "${NINJA_PATH}/ninja.exe")
    else()
        set(NINJA_EXE "${NINJA_PATH}/ninja")
    endif()

    if(EXISTS "${NINJA_EXE}")
        execute_process(
            COMMAND "${NINJA_EXE}" --version
            RESULT_VARIABLE NINJA_CHECK
            OUTPUT_QUIET
            ERROR_QUIET
        )
        if(NINJA_CHECK EQUAL 0)
            message(STATUS "Ninja is already installed")
            # Set Ninja path in CMake cache even for existing installation
            set(CMAKE_MAKE_PROGRAM "${NINJA_EXE}" CACHE FILEPATH "Path to Ninja executable" FORCE)
            return()
        endif()
    endif()

    # Download Ninja
    message(STATUS "Downloading Ninja ${NINJA_VERSION} from ${NINJA_URL}")
    file(DOWNLOAD "${NINJA_URL}" "${NINJA_DOWNLOAD}"
        SHOW_PROGRESS
        EXPECTED_HASH SHA256=${NINJA_HASH}
        TLS_VERIFY ON
        STATUS DOWNLOAD_STATUS
    )

    list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)

    if(NOT STATUS_CODE EQUAL 0)
        message(FATAL_ERROR "Failed to download Ninja: ${ERROR_MSG}")
    endif()

    # Extract and install Ninja
    message(STATUS "Extracting Ninja...")
    
    # Remove existing installation if any
    if(EXISTS "${NINJA_PATH}")
        file(REMOVE_RECURSE "${NINJA_PATH}")
    endif()
    
    file(MAKE_DIRECTORY "${NINJA_PATH}")

    if(WIN32)
        # Extract using PowerShell
        execute_process(
            COMMAND powershell -Command "$ProgressPreference = 'Continue'; Expand-Archive -Path '${NINJA_DOWNLOAD}' -DestinationPath '${NINJA_PATH}' -Force"
            RESULT_VARIABLE EXTRACT_RESULT
            ERROR_VARIABLE EXTRACT_ERROR
        )
        
        if(NOT EXTRACT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to extract Ninja archive: ${EXTRACT_ERROR}")
        endif()
    else()
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf "${NINJA_DOWNLOAD}"
            WORKING_DIRECTORY "${NINJA_PATH}"
            RESULT_VARIABLE EXTRACT_RESULT
        )
        
        if(NOT EXTRACT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to extract Ninja archive")
        endif()

        # Make ninja executable
        execute_process(
            COMMAND chmod +x "${NINJA_EXE}"
            RESULT_VARIABLE CHMOD_RESULT
        )
        
        if(NOT CHMOD_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to make Ninja executable")
        endif()
    endif()

    # Clean up archive
    file(REMOVE "${NINJA_DOWNLOAD}")

    # Verify installation and set in CMake cache
    message(STATUS "Verifying Ninja installation...")
    if(NOT EXISTS "${NINJA_EXE}")
        message(FATAL_ERROR "Failed: Ninja executable not found at ${NINJA_EXE}")
    endif()
    
    execute_process(
        COMMAND "${NINJA_EXE}" --version
        RESULT_VARIABLE NINJA_VERSION_RESULT
        OUTPUT_VARIABLE NINJA_VERSION_OUTPUT
        ERROR_QUIET
    )
    
    if(NOT NINJA_VERSION_RESULT EQUAL 0)
        file(REMOVE_RECURSE "${NINJA_PATH}")
        message(FATAL_ERROR "Failed: Ninja executable verification failed")
    endif()
    
    string(STRIP "${NINJA_VERSION_OUTPUT}" NINJA_VERSION_OUTPUT)
    message(STATUS "Successfully installed Ninja ${NINJA_VERSION_OUTPUT} to ${NINJA_PATH}")

    # Make Ninja available to CMake by setting it in the cache
    set(CMAKE_MAKE_PROGRAM "${NINJA_EXE}" CACHE FILEPATH "Path to Ninja executable" FORCE)
endfunction()