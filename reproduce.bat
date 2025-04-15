@echo off
setlocal EnableDelayedExpansion
goto :main

:build_and_verify
set "target=%~1"
set "label=%~2"
set "binary_name=%~3"

echo.
echo === Testing %label% builds ===
echo.

:: Release builds
echo Building %label% release #1...
cmake --preset %target%-release || exit /b 1
cmake --build --preset %target%-release || exit /b 1

:: Store the first release build
copy /b "build\%target%-release\%binary_name%" "build\%target%-release\%binary_name%.1" >nul || exit /b 1

:: Clean while preserving the first build and rebuild for second build
echo Building %label% release #2...
copy /b "build\%target%-release\%binary_name%.1" "%binary_name%.1.tmp" >nul || exit /b 1
rmdir /s /q "build\%target%-release" || exit /b 1
mkdir "build\%target%-release" || exit /b 1
move "%binary_name%.1.tmp" "build\%target%-release\%binary_name%.1" >nul || exit /b 1
cmake --preset %target%-release || exit /b 1
cmake --build --preset %target%-release || exit /b 1
copy /b "build\%target%-release\%binary_name%" "build\%target%-release\%binary_name%.2" >nul || exit /b 1

:: Compare release builds
echo Comparing %label% release builds...
fc /b "build\%target%-release\%binary_name%.1" "build\%target%-release\%binary_name%.2" >nul
if errorlevel 1 (
    echo.
    echo ❌ %label% release builds differ!
    echo.
    powershell -ExecutionPolicy Bypass -File scripts/hexdiff.ps1 "build/%target%-release/%binary_name%.1" "build/%target%-release/%binary_name%.2"
    exit /b 1
)
echo ✅ %label% release builds match

:: Print build hashes
echo.
echo %label% release build hash:
certutil -hashfile "build\%target%-release\%binary_name%" SHA256 | findstr /v "CertUtil"

:: Clean up intermediate files
del "build\%target%-release\%binary_name%.1" >nul 2>nul
del "build\%target%-release\%binary_name%.2" >nul 2>nul

exit /b 0

:main
echo Checking for Zig installation...
if not exist sysroot\tools\zig\zig.exe (
    echo Error: Zig not found in sysroot\tools\zig
    echo Please run bootstrap.ps1 first to install Zig
    exit /b 1
)

:: Force deterministic environment
set TZ=UTC
set LC_ALL=C
set CMAKE_BUILD_PARALLEL_LEVEL=1

:: Find CMake
where cmake.exe >nul 2>nul
if errorlevel 1 (
    echo Error: cmake.exe not found in PATH
    exit /b 1
)

:: Add Zig and Ninja to PATH
set "PATH=%CD%\sysroot\tools\zig;%CD%\sysroot\tools\ninja;%PATH%"

:: Verify Zig works
"%CD%\sysroot\tools\zig\zig.exe" version >nul 2>nul
if errorlevel 1 (
    echo Error: Failed to execute zig version
    exit /b 1
)

:: Clean previous builds
echo Cleaning previous builds...
if exist build rmdir /s /q build
if exist binary_diff.txt del binary_diff.txt

:: Build and verify Windows native builds
call :build_and_verify windows-x86_64 "Windows native" myapp.exe || exit /b 1

:: Build and verify Linux cross-compilation builds
call :build_and_verify linux-x86_64 "Linux cross-compilation" myapp || exit /b 1

:: Build and verify macOS cross-compilation builds
call :build_and_verify macos-x86_64 "macOS x86_64 cross-compilation" myapp || exit /b 1

:: Build and verify macOS ARM64 cross-compilation builds
call :build_and_verify macos-arm64 "macOS ARM64 cross-compilation" myapp || exit /b 1

echo.
echo ✅ All builds completed successfully!
exit /b 0