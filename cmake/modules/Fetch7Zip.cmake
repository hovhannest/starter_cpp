# Configure 7-Zip version and downloads
set(SEVENZIP_VERSION "2409")

# Platform-specific configuration
if(WIN32)
    set(SEVENZIP_PLATFORM "win")
    set(SEVENZIP_URL "https://www.7-zip.org/a/7z${SEVENZIP_VERSION}-x64.exe")
    set(SEVENZIP_HASH "9477daac74e253f7cf6c6847b62aad2b42c690942c88d1f2060b1c1aa10e740c")
    set(SEVENZIP_ARCHIVE "7z-win64.exe")
    set(SEVENZIP_EXE "7z.exe")
elseif(APPLE)
    set(SEVENZIP_PLATFORM "mac")
    set(SEVENZIP_URL "https://www.7-zip.org/a/7z${SEVENZIP_VERSION}-mac.tar.xz")
    set(SEVENZIP_HASH "a9f8b60b2d56d52dab74cc4110dd094bfe92f172ee89c15dbd787d67fbcc173b")
    set(SEVENZIP_ARCHIVE "7z-mac.tar.xz")
    set(SEVENZIP_EXE "7zzs")
else()
    set(SEVENZIP_PLATFORM "linux")
    set(SEVENZIP_URL "https://www.7-zip.org/a/7z${SEVENZIP_VERSION}-linux-x64.tar.xz")
    set(SEVENZIP_HASH "914c7e20ad5ef8e4d3cf08620ff8894b28fe11b7eb99809d6930870fbe48a281")
    set(SEVENZIP_ARCHIVE "7z-linux.tar.xz")
    set(SEVENZIP_EXE "7zzs")
endif()

# Setup paths
set(SEVENZIP_DIR "${CMAKE_CURRENT_LIST_DIR}/../../sysroot/tools/7zip")
get_filename_component(SEVENZIP_DIR ${SEVENZIP_DIR} ABSOLUTE)
set(SEVENZIP_PATH "${SEVENZIP_DIR}")
set(SEVENZIP_DOWNLOAD "${SEVENZIP_DIR}/${SEVENZIP_ARCHIVE}")

# Function to install 7-Zip
function(fetch_7zip)
    # Check if 7-Zip is already installed
    if(EXISTS "${SEVENZIP_PATH}/${SEVENZIP_EXE}")
        message(STATUS "7-Zip is already installed")
        return()
    endif()

    # Create directory
    file(MAKE_DIRECTORY "${SEVENZIP_DIR}")

    # Download 7-Zip
    message(STATUS "Downloading 7-Zip for ${SEVENZIP_PLATFORM}")
    file(DOWNLOAD "${SEVENZIP_URL}" "${SEVENZIP_DOWNLOAD}"
        SHOW_PROGRESS
        EXPECTED_HASH SHA256=${SEVENZIP_HASH}
        TLS_VERIFY ON
        STATUS DOWNLOAD_STATUS
    )

    list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)

    if(NOT STATUS_CODE EQUAL 0)
        message(FATAL_ERROR "Failed to download 7-Zip: ${ERROR_MSG}")
    endif()

    # Extract and install 7-Zip
    message(STATUS "Extracting 7-Zip...")
    
    if(WIN32)
        # On Windows, use PowerShell to extract the self-extracting exe
        execute_process(
            COMMAND powershell -Command "Start-Process '${SEVENZIP_DOWNLOAD}' -ArgumentList '/S', '/D=${SEVENZIP_PATH}' -Wait"
            RESULT_VARIABLE EXTRACT_RESULT
            ERROR_VARIABLE EXTRACT_ERROR
        )
    else()
        # On Linux/macOS, use built-in tar command for .tar.xz files
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf "${SEVENZIP_DOWNLOAD}"
            WORKING_DIRECTORY "${SEVENZIP_PATH}"
            RESULT_VARIABLE EXTRACT_RESULT
            ERROR_VARIABLE EXTRACT_ERROR
        )
    endif()

    if(NOT EXTRACT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to extract 7-Zip: ${EXTRACT_ERROR}")
    endif()

    # Make executable on Unix-like systems
    if(UNIX)
        execute_process(
            COMMAND chmod +x "${SEVENZIP_PATH}/${SEVENZIP_EXE}"
            RESULT_VARIABLE CHMOD_RESULT
        )
        
        if(NOT CHMOD_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to make 7-Zip executable")
        endif()
    endif()

    # Clean up downloaded archive
    file(REMOVE "${SEVENZIP_DOWNLOAD}")

    # Verify installation
    if(NOT EXISTS "${SEVENZIP_PATH}/${SEVENZIP_EXE}")
        message(FATAL_ERROR "7-Zip installation failed: executable not found")
    endif()

    message(STATUS "Successfully installed 7-Zip to ${SEVENZIP_PATH}")
endfunction()

# Helper function to get 7-Zip executable path
function(get_7zip_exe OUTPUT_VAR)
    set(${OUTPUT_VAR} "${SEVENZIP_PATH}/${SEVENZIP_EXE}" PARENT_SCOPE)
endfunction()