#include <Windows.h>
#include <stdarg.h>

// Basic printf implementation for Windows
int printf(const char* format, ...) {
    char buffer[1024];  // Static buffer for simplicity
    va_list args;
    int written = 0;
    HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD chars_written;

    va_start(args, format);
    
    // Simple implementation that only handles %s and %d for now
    while (*format) {
        if (*format == '%') {
            format++; // Skip '%'
            if (*format == '.') {
                format++; // Skip '.'
                if (*format == '*') {
                    format++; // Skip '*'
                    if (*format == 's') {
                        int precision = va_arg(args, int);
                        const char* str = va_arg(args, const char*);
                        size_t len_str = strlen(str);
                        size_t to_write = (precision < (int)len_str) ? precision : len_str;
                        WriteConsoleA(console, str, to_write, &chars_written, NULL);
                        written += chars_written;
                    } else {
                        WriteConsoleA(console, "%.*", 3, &chars_written, NULL);
                        written += chars_written;
                    }
                } else {
                    WriteConsoleA(console, "%.", 2, &chars_written, NULL);
                    written += chars_written;
                }
            } else {
                switch (*format) {
                    case 's': {
                        const char* str = va_arg(args, const char*);
                        WriteConsoleA(console, str, strlen(str), &chars_written, NULL);
                        written += chars_written;
                        break;
                    }
                    case 'd': {
                        int num = va_arg(args, int);
                        int len = sprintf_s(buffer, sizeof(buffer), "%d", num);
                        WriteConsoleA(console, buffer, len, &chars_written, NULL);
                        written += chars_written;
                        break;
                    }
                    default:
                        WriteConsoleA(console, format - 1, 1, &chars_written, NULL);
                        written += chars_written;
                        break;
                }
            }
        } else {
            WriteConsoleA(console, format, 1, &chars_written, NULL);
            written += chars_written;
        }
        format++;
    }

    va_end(args);
    return written;
}

// Custom strlen implementation since we're not using standard library
static size_t strlen(const char* str) {
    const char* s = str;
    while (*s) s++;
    return s - str;
}

// Simple sprintf_s implementation for numbers only
static int sprintf_s(char* buffer, size_t size, const char* format, int value) {
    if (value == 0) {
        if (size < 2) return 0;
        buffer[0] = '0';
        buffer[1] = '\0';
        return 1;
    }

    char temp[12];  // Enough for 32-bit integers
    int pos = 0;
    int negative = value < 0;
    
    if (negative) value = -value;
    
    while (value && pos < sizeof(temp) - 1) {
        temp[pos++] = '0' + (value % 10);
        value /= 10;
    }
    
    if (negative && pos < sizeof(temp) - 1) {
        temp[pos++] = '-';
    }
    
    int written = 0;
    for (int i = pos - 1; i >= 0 && written < size - 1; i--) {
        buffer[written++] = temp[i];
    }
    buffer[written] = '\0';
    
    return written;
}

// Custom snprintf implementation that only handles %s and %d
int snprintf(char* buffer, size_t size, const char* format, ...) {
    if (!buffer || size == 0) return 0;
    
    va_list args;
    va_start(args, format);
    int written = 0;
    
    while (*format && written < size - 1) {
        if (*format == '%') {
            format++;
            switch (*format) {
                case 's': {
                    const char* str = va_arg(args, const char*);
                    while (*str && written < size - 1) {
                        buffer[written++] = *str++;
                    }
                    break;
                }
                case 'd': {
                    int num = va_arg(args, int);
                    char temp[12];
                    int len = sprintf_s(temp, sizeof(temp), "%d", num);
                    for (int i = 0; i < len && written < size - 1; i++) {
                        buffer[written++] = temp[i];
                    }
                    break;
                }
                default:
                    if (written < size - 1) {
                        buffer[written++] = *(format - 1);
                        if (written < size - 1) {
                            buffer[written++] = *format;
                        }
                    }
                    break;
            }
        } else {
            buffer[written++] = *format;
        }
        format++;
    }
    
    buffer[written] = '\0';
    va_end(args);
    return written;
}