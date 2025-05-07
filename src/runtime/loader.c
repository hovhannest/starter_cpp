#include "loader.h"
#include <Windows.h>
#include <stdint.h>

#define MAX_LIBRARIES 16
#define MAX_EXPORTS_PER_LIB 1024*4

static LoadedLibrary libraries[MAX_LIBRARIES];
static size_t library_count = 0;

static LoadedLibrary* find_library_by_hash(uint32_t dll_hash) {
    for (size_t i = 0; i < library_count; i++) {
        if (libraries[i].dll_hash == dll_hash) {
            return &libraries[i];
        }
    }
    return NULL;
}

BOOL loader_load_library(const char* dll_name) {
    if (library_count >= MAX_LIBRARIES) {
        return FALSE;
    }

    uint32_t dll_hash = hash_string_runtime(dll_name);
    if (find_library_by_hash(dll_hash)) {
        return TRUE; // Already loaded
    }

    HMODULE handle = LoadLibraryA(dll_name);
    if (!handle) {
        return FALSE;
    }

    LoadedLibrary* lib = &libraries[library_count];
    lib->dll_hash = dll_hash;
    lib->handle = handle;
    lib->exports = (ExportEntry*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, 
                                         MAX_EXPORTS_PER_LIB * sizeof(ExportEntry));
    if (!lib->exports) {
        FreeLibrary(handle);
        return FALSE;
    }
    lib->export_count = 0;

    // Get export directory
    BYTE* base = (BYTE*)handle;
    IMAGE_DOS_HEADER* dos_header = (IMAGE_DOS_HEADER*)base;
    IMAGE_NT_HEADERS* nt_headers = (IMAGE_NT_HEADERS*)(base + dos_header->e_lfanew);
    IMAGE_EXPORT_DIRECTORY* export_dir = (IMAGE_EXPORT_DIRECTORY*)(base + 
        nt_headers->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);

    DWORD* names = (DWORD*)(base + export_dir->AddressOfNames);
    WORD* ordinals = (WORD*)(base + export_dir->AddressOfNameOrdinals);
    DWORD* functions = (DWORD*)(base + export_dir->AddressOfFunctions);

#ifdef LOG_EXPORTS
    // Cache all exported functions
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD written;
    WriteConsoleA(hConsole, "Exported functions:\n", 19, &written, NULL);
#endif // LOG_EXPORTS

    // Process each export
    for (DWORD i = 0; i < export_dir->NumberOfNames && lib->export_count < MAX_EXPORTS_PER_LIB; i++) {
        const char* name = (const char*)(base + names[i]);
        uint32_t name_hash = hash_string_runtime(name);
        FARPROC func_ptr = (FARPROC)(base + functions[ordinals[i]]);

        // Check for hash collisions by searching existing entries
        BOOL collision = FALSE;
        for (size_t j = 0; j < lib->export_count; j++) {
            if (lib->exports[j].name_hash == name_hash && lib->exports[j].func_ptr != 0) {
#ifdef LOG_EXPORT_COLLISIONS
                HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
                char msg[256];
                wsprintfA(msg, "WARNING: Hash collision detected for function '%s' (hash: 0x%08x)\n",
                         name, name_hash);
                DWORD written;
                WriteConsoleA(hConsole, msg, lstrlenA(msg), &written, NULL);
#endif // LOG_EXPORT_COLLISIONS
                collision = TRUE;
                break;
            }
        }

#ifdef LOG_EXPORTS
        // Print function name
        char msg[128];
        int len = wsprintfA(msg, "%d  ", (int)lib->export_count);
        WriteConsoleA(hConsole, msg, lstrlenA(msg), &written, NULL);
        WriteConsoleA(hConsole, name, lstrlenA(name), &written, NULL);
        WriteConsoleA(hConsole, "\n", 1, &written, NULL);
#endif // LOG_EXPORTS

        if (!collision) {
            lib->exports[lib->export_count].name_hash = name_hash;
            lib->exports[lib->export_count].func_ptr = func_ptr;
            lib->export_count++;
        }
    }

#ifdef LOG_EXPORTS
    // Print summary
    char msg[128];
    int len = wsprintfA(msg, "\nLoaded %d exports from library\n", (int)lib->export_count);
    WriteConsoleA(hConsole, msg, len, &written, NULL);
#endif // LOG_EXPORTS

    library_count++;
    return TRUE;
}

FARPROC loader_get_proc(uint32_t dll_hash, uint32_t func_hash) {
    LoadedLibrary* lib = find_library_by_hash(dll_hash);
    if (!lib) {
        return NULL;
    }

    // Search in cached exports
    for (size_t i = 0; i < lib->export_count; i++) {
        if (lib->exports[i].name_hash == func_hash) {
            return lib->exports[i].func_ptr;
        }
    }

    return NULL;
}