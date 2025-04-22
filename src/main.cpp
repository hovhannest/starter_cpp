#include <windows.h>

int printf(const char* str) {
    HANDLE out = GetStdHandle(STD_OUTPUT_HANDLE);
    int len = 0;
    while(str[len]) len++;  // Calculate string length
    DWORD written;
    WriteConsoleA(out, str, len, &written, 0);
    return written;
}

int main(void) {
    printf("hello world\n");
    return 0;
}