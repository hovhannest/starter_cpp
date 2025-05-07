#ifndef LOADER_H
#define LOADER_H

#include <Windows.h>
#include <stdint.h>

// Runtime function loading
typedef struct {
    uint32_t name_hash;
    FARPROC func_ptr;
} ExportEntry;

typedef struct {
    uint32_t dll_hash;
    HMODULE handle;
    ExportEntry* exports;
    size_t export_count;
} LoadedLibrary;

// FNV-1a hash function
static inline uint32_t hash_string_runtime(const char* str) {
    uint32_t hash = 2166136261u;
    while (*str) {
        hash ^= *str++;
        hash *= 16777619u;
    }
    return hash;
}

// Compile-time string hash using recursive macros
#define FNV_BASIS 2166136261u
#define FNV_PRIME 16777619u

#define HASH_1(x,c) ((uint32_t)((x^(unsigned char)(c))*FNV_PRIME))
#define HASH_2(x,c,d) HASH_1(HASH_1(x,c),d)
#define HASH_3(x,c,d,e) HASH_1(HASH_2(x,c,d),e)
#define HASH_4(x,c,d,e,f) HASH_1(HASH_3(x,c,d,e),f)
#define HASH_5(x,c,d,e,f,g) HASH_1(HASH_4(x,c,d,e,f),g)

// Max 5 characters for now, expand as needed
#define STRING_LITERAL_HASH_N(s,n) ((n)==1?HASH_1(FNV_BASIS,s[0]): \
                                   (n)==2?HASH_2(FNV_BASIS,s[0],s[1]): \
                                   (n)==3?HASH_3(FNV_BASIS,s[0],s[1],s[2]): \
                                   (n)==4?HASH_4(FNV_BASIS,s[0],s[1],s[2],s[3]): \
                                   (n)==5?HASH_5(FNV_BASIS,s[0],s[1],s[2],s[3],s[4]): \
                                   FNV_BASIS)

#define STRING_LITERAL_HASH(s) STRING_LITERAL_HASH_N(s,sizeof(s)-1)

// Load a DLL and cache its exports
BOOL loader_load_library(const char* dll_name);

// Get a function pointer by its hash
FARPROC loader_get_proc(uint32_t dll_hash, uint32_t func_hash);

// Helper macros for natural function loading syntax
#define LOAD_DLL(name) loader_load_library(name)
#define GET_FUNCTION(dll_name, func_name, type) \
    ((type)loader_get_proc(STRING_LITERAL_HASH(dll_name), STRING_LITERAL_HASH(#func_name)))

#endif // LOADER_H