#include <iostream>

int main() {
    std::cout << "Hello from hermetic build!\n";
    std::cout << "Project version: "
              << PROJECT_VERSION_MAJOR << "."
              << PROJECT_VERSION_MINOR << "."
              << PROJECT_VERSION_PATCH << "\n";
    return 0;
}