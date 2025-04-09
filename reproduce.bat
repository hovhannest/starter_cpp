@echo off
setlocal EnableDelayedExpansion

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
if exist build-1 rmdir /s /q build-1
if exist build-2 rmdir /s /q build-2
if exist binary_diff.txt del binary_diff.txt

:: First build
echo Building first copy...
mkdir build-1
pushd build-1
cmake.exe -G Ninja ^
    -DCMAKE_TOOLCHAIN_FILE=..\cmake\toolchains\windows-x86_64.cmake ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_VERBOSE_MAKEFILE=ON ^
    -DCMAKE_C_COMPILER_WORKS=ON ^
    -DCMAKE_CXX_COMPILER_WORKS=ON ^
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ^
    -DCMAKE_COLOR_DIAGNOSTICS=OFF ^
    .. || goto error
cmake.exe --build . || goto error
:: No longer copying to root folder
popd

:: Second build
echo Building second copy...
mkdir build-2
pushd build-2
cmake.exe -G Ninja ^
    -DCMAKE_TOOLCHAIN_FILE=..\cmake\toolchains\windows-x86_64.cmake ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_VERBOSE_MAKEFILE=ON ^
    -DCMAKE_C_COMPILER_WORKS=ON ^
    -DCMAKE_CXX_COMPILER_WORKS=ON ^
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ^
    -DCMAKE_COLOR_DIAGNOSTICS=OFF ^
    .. || goto error
cmake.exe --build . || goto error
:: No longer copying to root folder
popd

:: Compare builds
echo Comparing builds...
fc /b build-1\myapp.exe build-2\myapp.exe >nul
if errorlevel 1 (
    echo.
    echo ❌ Builds differ, generating detailed comparison...
    echo.
    
    :: Run PowerShell comparison script
    powershell -ExecutionPolicy Bypass -File scripts/hexdiff.ps1 build-1/myapp.exe build-2/myapp.exe
    
    echo.
    echo Build 1 hash:
    certutil -hashfile build-1\myapp.exe SHA256 | findstr /v "CertUtil"
    echo.
    echo Build 2 hash:
    certutil -hashfile build-2\myapp.exe SHA256 | findstr /v "CertUtil"
    exit /b 1
)

echo.
echo ✅ Success! Builds match
echo.
echo Build hash:
certutil -hashfile build-1\myapp.exe SHA256 | findstr /v "CertUtil"

:: Clean up build directories on success
if exist build-1 rmdir /s /q build-1
if exist build-2 rmdir /s /q build-2

exit /b 0

:error
echo.
echo ❌ Build failed with error #%errorlevel%
popd
exit /b %errorlevel%