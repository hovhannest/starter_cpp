# Makefile for building the main application

# Compiler and flags
CXX = g++
CXXFLAGS = -std=c++17 -Wall

# Directories
SRC_DIR = src
INCLUDE_DIR = include
BUILD_DIR = build
BIN_DIR = build/bin

# Source files
SRCS = $(wildcard $(SRC_DIR)/*.cpp)

# Object files
OBJS = $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SRCS))

# Target executable
TARGET = $(BIN_DIR)/hello_world

# Ensure that the build and bin directories exist
$(shell mkdir -p $(BUILD_DIR) $(BIN_DIR))

# Build the main application
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) $^ -o $@

# Compile source files into object files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) -c $< -o $@

.PHONY: clean

# Clean the build and bin directories
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

# Default target
all: $(TARGET)

# Ensure that 'all' is the default target when running 'make' without arguments
.DEFAULT_GOAL := all
