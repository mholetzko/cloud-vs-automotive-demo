cmake_minimum_required(VERSION 3.10)
project(LicenseClientCpp VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find dependencies
find_package(CURL REQUIRED)
find_package(jsoncpp REQUIRED)

# Library
add_library(license_client STATIC
    license_client.cpp
)

target_include_directories(license_client PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(license_client
    CURL::libcurl
    jsoncpp_lib
)

# Example executable
add_executable(license_client_example
    example.cpp
)

target_link_libraries(license_client_example
    license_client
)

# Install targets
install(TARGETS license_client license_client_example
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES license_client.hpp
    DESTINATION include
)

