
cmake_minimum_required(VERSION 3.17 FATAL_ERROR)
project(xeus-sml
    DESCRIPTION "SML bindings to Xeus"
    LANGUAGES CXX)

include(FetchContent)

# Dependencies
find_package(Threads REQUIRED)
find_program(MLTON_EXE mlton REQUIRED)

# nlohmann_json
find_package(nlohmann_json 3.8.0 QUIET)
if(NOT nlohmann_json_FOUND)
    message(WARNING "Could not find nlohmann_json installed - building locally")
    # nlohmann_json tests are enabled by default
    set(JSON_BuildTests OFF CACHE INTERNAL)
    set(JSON_Install OFF CACHE INTERNAL)
    # Fetch nlohmann_json
    FetchContent_Declare(
        nlohmann_json
        GIT_REPOSITORY "https://github.com/nlohmann/json.git"
        GIT_TAG        "v3.8.0")
    FetchContent_MakeAvailable(nlohmann_json)
endif()

# xtl (depends on nlohmann_json)
find_package(xtl 0.6.13)
if(NOT xtl_FOUND)
    message(WARNING "Could not find xtl installed - building locally")
    FetchContent_Declare(
        xtl
        GIT_REPOSITORY "https://github.com/xtensor-stack/xtl.git"
        GIT_TAG        "0.6.13")
    FetchContent_MakeAvailable(xtl)
endif()

# Xeus (depends on nlohmann_json and xtl)
find_package(xeus 0.24 QUIET)
if(xeus_FOUND)
    find_package(xeus 0.24) # Show CMake messages
else()
    message(WARNING "Could not find Xeus installed - building locally")
    FetchContent_Declare(
        xeus
        GIT_REPOSITORY "https://github.com/jupyter-xeus/xeus.git"
        GIT_TAG        "0.24.0")
    FetchContent_MakeAvailable(xeus)
endif()

# Create the MLton export header
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h
    COMMAND ${MLTON_EXE} -stop tc -export-header ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h ${CMAKE_CURRENT_LIST_DIR}/xeus-sml.mlb
    )

# The C++ library
add_library(xeus-sml STATIC
    cpp/xeus-sml.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h)
target_include_directories(xeus-sml
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/cpp>
    PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/include)
target_link_libraries(xeus-sml
    PUBLIC
    xeus-static
    nlohmann_json::nlohmann_json
    Threads::Threads)

# SML library constants - for use when compiling
# NOTE: make sure you use "VERBATIM" and "COMMAND_EXPAND_LISTS" when writing
# custom targets for compiling SML
set(XEUS_SML_MLB "${CMAKE_CURRENT_SOURCE_DIR}/xeus-sml.mlb")
set(XEUS_SML_OPTS -link-opt $<TARGET_FILE_NAME:xeus-sml>)


