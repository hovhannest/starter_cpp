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
            
            // Handle width specification
            int width = 0;
            while (*format >= '0' && *format <= '9') {
                width = width * 10 + (*format - '0');
                format++;
            }
            
            switch (*format) {
                case 's': {
                    const char* str = va_arg(args, const char*);
                    size_t len = strlen(str);
                    
                    // Add padding if width specified
                    while (width > len && written < size - 1) {
                        buffer[written++] = ' ';
                        width--;
                    }
                    
                    while (*str && written < size - 1) {
                        buffer[written++] = *str++;
                    }
                    break;
                }
                case 'd': {
                    int num = va_arg(args, int);
                    char temp[12];
                    int len = sprintf_s(temp, sizeof(temp), "%d", num);
                    
                    // Add padding if width specified
                    while (width > len && written < size - 1) {
                        buffer[written++] = ' ';
                        width--;
                    }
                    
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

// Helper function to skip whitespace
static const char* skip_whitespace(const char* str) {
    while (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r') {
        str++;
    }
    return str;
}

// Helper function to parse integer
static int parse_int(const char** str, int* value) {
    *value = 0;
    int sign = 1;
    const char* s = *str;

    // Handle sign
    if (*s == '-') {
        sign = -1;
        s++;
    } else if (*s == '+') {
        s++;
    }

    // Parse digits
    if (!(*s >= '0' && *s <= '9')) {
        return 0;  // No valid number found
    }

    while (*s >= '0' && *s <= '9') {
        *value = (*value * 10) + (*s - '0');
        s++;
    }

    *value *= sign;
    *str = s;
    return 1;  // Successfully parsed
}

// Basic sscanf implementation
int sscanf(const char* str, const char* format, ...) {
    va_list args;
    va_start(args, format);
    int matched = 0;

    while (*format && *str) {
        if (*format == '%') {
            format++;  // Skip '%'
            
            // Handle assignment suppression with *
            int suppress = 0;
            if (*format == '*') {
                suppress = 1;
                format++;
            }

            // Skip any width specification
            while (*format >= '0' && *format <= '9') {
                format++;
            }

            switch (*format) {
                case 'd': {
                    int value;
                    str = skip_whitespace(str);
                    if (parse_int(&str, &value)) {
                        if (!suppress) {
                            int* value_ptr = va_arg(args, int*);
                            *value_ptr = value;
                            matched++;
                        }
                    } else {
                        va_end(args);
                        return matched;
                    }
                    break;
                }
                case 's': {
                    str = skip_whitespace(str);
                    if (!suppress) {
                        char* buffer = va_arg(args, char*);
                        // Copy until whitespace or end
                        while (*str && *str != ' ' && *str != '\t' && *str != '\n' && *str != '\r') {
                            *buffer++ = *str++;
                        }
                        *buffer = '\0';
                        matched++;
                    } else {
                        // Skip the string without storing
                        while (*str && *str != ' ' && *str != '\t' && *str != '\n' && *str != '\r') {
                            str++;
                        }
                    }
                    break;
                }
                default:
                    // Unsupported format specifier
                    va_end(args);
                    return matched;
            }
        } else if (*format == ' ' || *format == '\t' || *format == '\n' || *format == '\r') {
            // Skip whitespace in both format and input
            format = skip_whitespace(format);
            str = skip_whitespace(str);
        } else {
            // Match literal character
            if (*format != *str) {
                va_end(args);
                return matched;
            }
            str++;
        }
        format++;
    }

    va_end(args);
    return matched;
}