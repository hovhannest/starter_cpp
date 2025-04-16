# Include common settings
include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)

# Define the system for cross-compilation
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(ZIG_TARGET_TRIPLE "x86_64-windows-gnu")

# Setup cross compilation detection
setup_cross_compiling(${CMAKE_SYSTEM_NAME})

# Configure compiler settings based on compilation mode
if(CROSS_COMPILING)
    set(CMAKE_RC_COMPILER_WORKS 1)
    set(CMAKE_RC_COMPILER ${CMAKE_C_COMPILER})
    set(CMAKE_C_STANDARD_LIBRARIES "")
    set(CMAKE_CXX_STANDARD_LIBRARIES "")
endif()

# Configure Windows-specific settings
set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".lib")
set(CMAKE_LINK_LIBRARY_SUFFIX ".lib")
set(CMAKE_EXECUTABLE_SUFFIX ".exe")
set(CMAKE_LINK_DEF_FILE_FLAG "")  # Disable .def file generation

# Setup compiler paths and arguments
setup_compiler_paths()
setup_compiler_args()

# Configure Windows-specific flags
set(PLATFORM_SPECIFIC_FLAGS "-DWIN32 -D_WIN32")
if(CROSS_COMPILING)
    string(APPEND PLATFORM_SPECIFIC_FLAGS
        " -D__MINGW32__ \
         -D__MINGW64__")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    string(APPEND PLATFORM_SPECIFIC_FLAGS " -Wno-dll-attribute-on-redeclaration")
endif()

# Apply common compiler flags with Windows-specific additions
set_common_compiler_flags()

# Setup shared settings including linker flags
setup_shared_settings()

# Setup find root paths
setup_find_root_paths()

# Add PE timestamp setting as post-build step
function(set_pe_timestamp target)
  if(CMAKE_HOST_WIN32)
    set(TIMESTAMP_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/set_pe_timestamp.ps1")
    add_custom_command(TARGET ${target} POST_BUILD
      COMMAND PowerShell -ExecutionPolicy Bypass -File "${TIMESTAMP_SCRIPT}" "$<TARGET_FILE:${target}>" 0
      COMMENT "Setting PE timestamp for ${target}"
    )
  else()
    set(TIMESTAMP_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/set_pe_timestamp.sh")
    add_custom_command(TARGET ${target} POST_BUILD
      COMMAND ${TIMESTAMP_SCRIPT} "$<TARGET_FILE:${target}>" 0
      COMMENT "Setting PE timestamp for ${target}"
    )
  endif()
endfunction()
