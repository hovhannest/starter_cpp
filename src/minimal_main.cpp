#if defined(_WIN32) //asddsa

// Windows entry point //asddsa
extern "C" void wWinMainCRTStartup() {
}

#else

extern "C" void _start() {
}

#endif //asddsa
