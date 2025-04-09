# Configure Zig version and downloads
set(ZIG_VERSION "0.14.0")
set(ZIG_DOWNLOAD_BASE "https://ziglang.org/download")

# Platform-specific configuration
if(WIN32)
    set(ZIG_PLATFORM "windows")
    set(ZIG_ARCHIVE_EXT "zip")
    set(ZIG_HASH "f53e5f9011ba20bbc3e0e6d0a9441b31eb227a97bac0e7d24172f1b8b27b4371")
elseif(APPLE)
    set(ZIG_PLATFORM "macos")
    set(ZIG_ARCHIVE_EXT "tar.xz")
    set(ZIG_HASH "5082f5bca449bb4f6c18776356da743166afd4488b0102d83a75e5cec8e5f265")
else()
    set(ZIG_PLATFORM "linux")
    set(ZIG_ARCHIVE_EXT "tar.xz")
    set(ZIG_HASH "c6052542376f606de613d63da465be731c2e8b437916ac71680062a407a41c2d")
endif()

# Setup paths
set(ZIG_ARCH "x86_64")
set(ZIG_ARCHIVE "zig-${ZIG_PLATFORM}-${ZIG_ARCH}-${ZIG_VERSION}.${ZIG_ARCHIVE_EXT}")
set(ZIG_URL "${ZIG_DOWNLOAD_BASE}/${ZIG_VERSION}/${ZIG_ARCHIVE}")
set(ZIG_DIR "${CMAKE_CURRENT_LIST_DIR}/../../sysroot/tools")
get_filename_component(ZIG_DIR ${ZIG_DIR} ABSOLUTE)
set(ZIG_PATH "${ZIG_DIR}/zig")
set(ZIG_DOWNLOAD "${ZIG_DIR}/${ZIG_ARCHIVE}")

# Function to install Zig
function(fetch_zig)
    # Ensure directory exists
    file(MAKE_DIRECTORY "${ZIG_DIR}")

    # Check if Zig is already installed
    if(WIN32)
        set(ZIG_EXE "${ZIG_PATH}/zig.exe")
    else()
        set(ZIG_EXE "${ZIG_PATH}/zig")
    endif()

    if(EXISTS "${ZIG_EXE}")
        execute_process(
            COMMAND "${ZIG_EXE}" version
            RESULT_VARIABLE ZIG_CHECK
            OUTPUT_QUIET
            ERROR_QUIET
        )
        if(ZIG_CHECK EQUAL 0)
            message(STATUS "Zig is already installed")
            return()
        endif()
    endif()

    # Download Zig
    message(STATUS "Downloading Zig ${ZIG_VERSION} from ${ZIG_URL}")
    file(DOWNLOAD "${ZIG_URL}" "${ZIG_DOWNLOAD}"
        SHOW_PROGRESS
        EXPECTED_HASH SHA256=${ZIG_HASH}
        TLS_VERIFY ON
        STATUS DOWNLOAD_STATUS
    )

    list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)

    if(NOT STATUS_CODE EQUAL 0)
        message(FATAL_ERROR "Failed to download Zig: ${ERROR_MSG}")
    endif()

    # Extract and install Zig
    message(STATUS "Extracting Zig...")
    if(WIN32)
        # Remove existing installation if any
        if(EXISTS "${ZIG_PATH}")
            file(REMOVE_RECURSE "${ZIG_PATH}")
        endif()

        # Extract directly to final location
        message(STATUS "Expanding archive with PowerShell...")
        execute_process(
            COMMAND powershell -Command "$ProgressPreference = 'Continue'; Write-Host 'PowerShell extraction starting...'; Expand-Archive -Path '${ZIG_DOWNLOAD}' -DestinationPath '${ZIG_DIR}' -Force; Write-Host 'PowerShell extraction complete'"
            RESULT_VARIABLE EXTRACT_RESULT
            OUTPUT_VARIABLE EXTRACT_OUTPUT
            ERROR_VARIABLE EXTRACT_ERROR
        )
        
        if(NOT EXTRACT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to extract Zig archive: ${EXTRACT_ERROR}")
        endif()
        
        message(STATUS "${EXTRACT_OUTPUT}")
        
        # Find extracted directory and rename it to 'zig'
        file(GLOB ZIG_EXTRACTED_LIST "${ZIG_DIR}/zig-windows-*")
        list(LENGTH ZIG_EXTRACTED_LIST ZIG_EXTRACTED_COUNT)
        if(ZIG_EXTRACTED_COUNT EQUAL 0)
            message(FATAL_ERROR "Could not find extracted Zig directory")
        endif()
        
        list(GET ZIG_EXTRACTED_LIST 0 ZIG_EXTRACTED)
        file(RENAME "${ZIG_EXTRACTED}" "${ZIG_PATH}")
    else()
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf "${ZIG_DOWNLOAD}"
            WORKING_DIRECTORY "${ZIG_DIR}"
            RESULT_VARIABLE EXTRACT_RESULT
        )
        
        if(NOT EXTRACT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to extract Zig archive")
        endif()
        
        # Find extracted directory and rename it to 'zig'
        file(GLOB ZIG_EXTRACTED_LIST "${ZIG_DIR}/zig-${ZIG_PLATFORM}-*")
        list(LENGTH ZIG_EXTRACTED_LIST ZIG_EXTRACTED_COUNT)
        if(ZIG_EXTRACTED_COUNT EQUAL 0)
            message(FATAL_ERROR "Could not find extracted Zig directory")
        endif()
        
        list(GET ZIG_EXTRACTED_LIST 0 ZIG_EXTRACTED)
        file(RENAME "${ZIG_EXTRACTED}" "${ZIG_PATH}")
    endif()

    # Clean up archive
    file(REMOVE "${ZIG_DOWNLOAD}")

    # Verify installation
    message(STATUS "Verifying Zig installation...")
    if(NOT EXISTS "${ZIG_EXE}")
        message(FATAL_ERROR "Failed: Zig executable not found at ${ZIG_EXE}")
    endif()
    
    execute_process(
        COMMAND "${ZIG_EXE}" version
        RESULT_VARIABLE ZIG_VERSION_RESULT
        OUTPUT_VARIABLE ZIG_VERSION_OUTPUT
        ERROR_QUIET
    )
    
    if(NOT ZIG_VERSION_RESULT EQUAL 0)
        file(REMOVE_RECURSE "${ZIG_PATH}")
        message(FATAL_ERROR "Failed: Zig executable verification failed")
    endif()
    
    string(STRIP "${ZIG_VERSION_OUTPUT}" ZIG_VERSION_OUTPUT)
    message(STATUS "Successfully installed Zig ${ZIG_VERSION_OUTPUT} to ${ZIG_PATH}")
endfunction()