
cmake_minimum_required(VERSION 3.17 FATAL_ERROR)
project(xeus-sml
    VERSION 0.1.0
    DESCRIPTION "SML bindings to Xeus"
    LANGUAGES CXX)

include(FetchContent)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

#############################################################################
# 
# Options
# 
#############################################################################

#############################################################################
# 
# Dependencies
# 
#############################################################################

find_package(Threads REQUIRED)
find_program(MLTON_EXE mlton REQUIRED)

if(NOT TARGET nlohmann_json)
    find_package(nlohmann_json REQUIRED)
endif()

if(NOT TARGET xeus)
    find_package(xeus 0.24)
endif()
set_target_properties(xeus PROPERTIES INTERFACE_COMPILE_OPTIONS "")
set_target_properties(xeus-static PROPERTIES INTERFACE_COMPILE_OPTIONS "")

#############################################################################
# 
# Library
# 
#############################################################################

## RPATH handling

set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
list(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_LIBDIR}" install_is_sysdir)
if("${install_is_sysdir}" STREQUAL "-1")
    set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_LIBDIR}")
endif()

# Create the MLton export header
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/include"
    COMMAND ${MLTON_EXE} -stop tc -export-header ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h ${CMAKE_CURRENT_SOURCE_DIR}/sml/xeus-sml.mlb
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/sml/xeus.sml
    )

# The C++ shared library
add_library(xeus-sml SHARED
    cpp/xeus-sml.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h)
target_include_directories(xeus-sml
    PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/include)
target_link_libraries(xeus-sml
    PUBLIC
    xeus
    nlohmann_json::nlohmann_json
    Threads::Threads)
target_compile_options(xeus-sml
    PUBLIC
    -Wno-unused-parameter)
target_compile_features(xeus-sml
    PRIVATE
    cxx_std_17)

# The C++ static library
add_library(xeus-sml-static STATIC
    cpp/xeus-sml.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/include/xeus-sml-export.h)
target_include_directories(xeus-sml-static
    PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/include)
target_link_libraries(xeus-sml-static
    PUBLIC
    xeus-static
    nlohmann_json::nlohmann_json
    Threads::Threads)
target_compile_options(xeus-sml-static
    PUBLIC
    -Wno-unused-parameter)
target_compile_features(xeus-sml-static
    PRIVATE
    cxx_std_17)

#############################################################################
# 
# Installation
# 
#############################################################################

install(
    TARGETS xeus-sml xeus-sml-static
    EXPORT xeus-sml-targets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

configure_package_config_file(
    xeus-sml-config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/xeus-sml-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/xeus-sml"
    PATH_VARS CMAKE_INSTALL_LIBDIR)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/xeus-sml-config-version.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY ExactVersion)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/xeus-sml-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/xeus-sml-config-version.cmake"
        "${CMAKE_CURRENT_SOURCE_DIR}/kernel.json.in"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/xeus-sml")
install(
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/sml/xeus-impl.sml"
        "${CMAKE_CURRENT_SOURCE_DIR}/sml/xeus-kernel.fun"
        "${CMAKE_CURRENT_SOURCE_DIR}/sml/xeus-sml.mlb"
        "${CMAKE_CURRENT_SOURCE_DIR}/sml/xeus.sml"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/xeus-sml")
install(EXPORT xeus-sml-targets
    FILE xeus-sml-targets.cmake
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/xeus-sml")

