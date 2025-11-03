# Simple Makefile for C++ License Client

CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
LDFLAGS = -lcurl -ljsoncpp

TARGET = license_client_example
SOURCES = license_client.cpp example.cpp
OBJECTS = $(SOURCES:.cpp=.o)

.PHONY: all clean test cmake-build

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)
	rm -rf build/

cmake-build:
	mkdir -p build
	cd build && cmake .. && make

test: $(TARGET)
	./$(TARGET)

test-remote: $(TARGET)
	./$(TARGET) https://license-server-demo.fly.dev

help:
	@echo "Available targets:"
	@echo "  all          - Build with make (default)"
	@echo "  cmake-build  - Build with CMake"
	@echo "  clean        - Remove build artifacts"
	@echo "  test         - Build and run against localhost"
	@echo "  test-remote  - Build and run against Fly.io"
	@echo ""
	@echo "Requirements:"
	@echo "  - libcurl-dev"
	@echo "  - libjsoncpp-dev"
	@echo ""
	@echo "Install on Ubuntu/Debian:"
	@echo "  sudo apt-get install libcurl4-openssl-dev libjsoncpp-dev"

