from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps


class ProjectConan(ConanFile):
    name = "medit"
    version = "0.0.1"

    # Package metadata
    license = "MIT"
    author = "Tovhannes Tsakanyan hovhannes.ht@gmail.com"
    url = "https://github.com/hovhannest/medit"
    description = "A cross-platform C++ text editor"
    topics = ("cpp", "cross-platform", "editor")

    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "with_tests": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
        "with_tests": True,
    }

    # Sources are located in the same place as this recipe
    exports_sources = "CMakeLists.txt", "src/*", "include/*", "tests/*"

    def config_options(self):
        """Remove options that don't make sense for certain platforms"""
        if self.settings.os == "Windows":
            del self.options.fPIC

    def configure(self):
        """Fine-tune configuration based on settings"""
        if self.options.shared:
            # Shared libs don't need fPIC
            self.options.rm_safe("fPIC")

    def layout(self):
        """Define the project layout"""
        cmake_layout(self)

    def requirements(self):
        """Declare dependencies"""
        # Example dependencies - uncomment and modify as needed
        # self.requires("fmt/10.2.1")
        # self.requires("spdlog/1.13.0")
        # self.requires("nlohmann_json/3.11.3")
        # self.requires("cli11/2.4.1")
        pass

    def build_requirements(self):
        """Declare build-time dependencies"""
        if self.options.with_tests:
            self.test_requires("gtest/1.17.0")

    def generate(self):
        """Generate build system files"""
        # Generate CMake toolchain
        tc = CMakeToolchain(self)
        tc.variables["BUILD_TESTS"] = self.options.with_tests
        tc.generate()

        # Generate CMake dependency files
        deps = CMakeDeps(self)
        deps.generate()

    def build(self):
        """Build the project"""
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

        # Run tests if enabled
        if self.options.with_tests:
            cmake.test()

    def package(self):
        """Package the built artifacts"""
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        """Provide information about the package"""
        self.cpp_info.libs = ["medit"]

        # Add any compile definitions
        # self.cpp_info.defines = ["MY_DEFINE=1"]

        # Add include directories
        # self.cpp_info.includedirs = ["include"]
