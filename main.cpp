#include <windows.h>

// Minimal entry point
extern "C" void __stdcall WinMainCRTStartup() {
    HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    const char msg[] = "Tiny MSVC executable\r\n";
    DWORD written;
    
    WriteFile(hStdOut, msg, sizeof(msg)-1, &written, NULL);
    
    // Test MSVC version
    #ifdef _MSC_VER
        char versionMsg[] = "MSVC v\r\n";
        versionMsg[5] = '0' + (_MSC_VER / 1000 % 10);
        WriteFile(hStdOut, versionMsg, sizeof(versionMsg)-1, &written, NULL);
    #endif
    
    ExitProcess(0);
}