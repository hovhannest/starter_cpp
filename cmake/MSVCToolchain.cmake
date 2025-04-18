# Minimum required MSVC version (19.0 = MSVC 2019)
set(MSVC_MIN_VERSION 19.0 CACHE STRING "Minimum required MSVC version")

# Common MSVC compiler flags
function(configure_msvc_common target)
    # Modern MSVC features
    target_compile_options(${target} PRIVATE /permissive- /Zc:preprocessor /Zc:__cplusplus)
    target_compile_definitions(${target} PRIVATE _HAS_CXX23=1)

    # Common compiler flags
    target_compile_options(${target} PRIVATE /W4 /WX /EHsc /MP)

    # Common definitions
    target_compile_definitions(${target} PRIVATE
        _CRT_SECURE_NO_WARNINGS
        _SCL_SECURE_NO_WARNINGS)
endfunction()

# MSVC-specific configurations
function(configure_msvc_target target)
    if(NOT MSVC)
        message(WARNING "MSVC compiler not available - target ${target} will not be configured for MSVC")
        return()
    endif()

    # Verify compiler meets version requirements
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS MSVC_MIN_VERSION)
        message(FATAL_ERROR
            "MSVC compiler version ${CMAKE_CXX_COMPILER_VERSION} is too old\n"
            "Required version: ${MSVC_MIN_VERSION} or later")
    endif()

    message(STATUS "Configuring target ${target} for MSVC toolchain (version ${CMAKE_CXX_COMPILER_VERSION})")

    # Apply common configurations
    configure_msvc_common(${target})

    # MSVC-specific compiler flags (static runtime)
    target_compile_options(${target} PRIVATE $<$<CONFIG:Debug>:/Od /Zi /MTd>)
    target_compile_options(${target} PRIVATE $<$<CONFIG:Release>:/O2 /Oi /GL /MT>)

    # MSVC-specific linker flags
    target_link_options(${target} PRIVATE $<$<CONFIG:Release>:/LTCG>)
endfunction()

# Minimal size MSVC configuration (no CRT linking)
function(configure_msvc_minimal target)
    # Optional minimum Windows version (default: 7 = windows 7)
    if(NOT DEFINED WIN_MIN_VERSION)
        set(WIN_MIN_VERSION 7)
    elseif(WIN_MIN_VERSION LESS 7)
        message(FATAL_ERROR "WIN_MIN_VERSION must be at least 7 (Windows 7)")
    endif()
    set(WIN_MIN_VERSION ${WIN_MIN_VERSION} PARENT_SCOPE)
    if(NOT MSVC)
        message(WARNING "MSVC compiler not available - target ${target} will not be configured for MSVC")
        return()
    endif()

    # Verify compiler meets version requirements
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS MSVC_MIN_VERSION)
        message(FATAL_ERROR
            "MSVC compiler version ${CMAKE_CXX_COMPILER_VERSION} is too old\n"
            "Required version: ${MSVC_MIN_VERSION} or later")
    endif()

    message(STATUS "Configuring target ${target} for minimal MSVC executable (version ${CMAKE_CXX_COMPILER_VERSION})")

    # Apply common configurations
    configure_msvc_common(${target})

    # Minimal size compiler flags (different for Debug vs Release)
    target_compile_options(${target} PRIVATE
        $<$<CONFIG:Debug>:/Od /Zi /MTd /GS- /GR- /fp:precise>
        $<$<CONFIG:Release>:/O1 /Os  /GS- /GR- /fp:precise>)

    # Linker flags - different for Debug vs Release
    target_link_options(${target} PRIVATE
        $<$<CONFIG:Debug>:
            /DEBUG
            /INCREMENTAL
            /ENTRY:WinMainCRTStartup
            /NODEFAULTLIB:msvcrt.lib
            /NODEFAULTLIB:libcmt.lib
            /NODEFAULTLIB:libcmtd.lib
            /SUBSYSTEM:WINDOWS,6.00
            /DYNAMICBASE:NO
            /NXCOMPAT:NO
        >
        $<$<CONFIG:Release>:
            /NODEFAULTLIB:msvcrt.lib
            /ENTRY:WinMainCRTStartup
            /MERGE:.rdata=.text
            /OPT:REF
            /OPT:ICF
            /SAFESEH:NO
            /FILEALIGN:16
            /SUBSYSTEM:CONSOLE,6.00
            /DYNAMICBASE:NO
            /NXCOMPAT:NO
            /DEBUG:NONE
        >)
        
    # Link against required Windows DLLs
    target_link_libraries(${target} PRIVATE
        kernel32.lib
        ntdll.lib
        user32.lib
        advapi32.lib
        msvcrt.lib
        $<$<CONFIG:Debug>:libucrt.lib libvcruntime.lib>)
        
    # Additional libraries for Windows 8+ targets
    if(WIN_MIN_VERSION GREATER_EQUAL 8)
        target_link_libraries(${target} PRIVATE
            gdi32.lib
            shell32.lib
            comctl32.lib
            comdlg32.lib
            wininet.lib)
            
        # Windows 8.1+ specific libraries
        if(WIN_MIN_VERSION GREATER_EQUAL 8.1)
            target_link_libraries(${target} PRIVATE
                SpeechUX/speechuxcpl.lib
                SpaceControl.lib
                SyncCenter.lib
                systemcpl.lib)
            
            # Windows 10+ specific libraries
            if(WIN_MIN_VERSION GREATER_EQUAL 10)
                target_link_libraries(${target} PRIVATE
                    windows.ui.lib
                    Microsoft.Windows.Shell.lib
                    wincorlib.lib
                    WindowsCodecs.lib)
            endif()
        endif()
    endif()
endfunction()
