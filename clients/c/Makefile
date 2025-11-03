# Makefile for C License Client

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS = -lcurl

TARGET = license_client_example
SOURCES = license_client.c example.c
OBJECTS = $(SOURCES:.c=.o)

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(TARGET) $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

test: $(TARGET)
	./$(TARGET)

# Example usage with Fly.io
test-remote: $(TARGET)
	./$(TARGET) https://license-server-demo.fly.dev

help:
	@echo "Available targets:"
	@echo "  all          - Build the example (default)"
	@echo "  clean        - Remove build artifacts"
	@echo "  test         - Build and run against localhost"
	@echo "  test-remote  - Build and run against Fly.io"
	@echo ""
	@echo "Requirements:"
	@echo "  - libcurl-dev (sudo apt-get install libcurl4-openssl-dev)"
	@echo ""
	@echo "Usage:"
	@echo "  make"
	@echo "  ./license_client_example [server_url]"

