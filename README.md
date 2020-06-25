
# Xeus-SML

Bindings for Xeus for Standard ML

# Installation

    $ mkdir _build
    $ cd _build
    $ cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
    $ cmake --build .
    $ cmake --build . --target install

# Usage

    find_package(xeus-sml 0.1.0 REQUIRED)

    set(KERNEL_DISPLAY_NAME "...")
    set(KERNEL_LANGUAGE "...")
    set(KERNEL_EXECUTABLE_PATH "...")
    xeus_sml_create_kernel(${CMAKE_CURRENT_BINARY_DIR}/kernel.json)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/kernel.json
        DESTINATION ${CMAKE_INSTALL_DATADIR}/jupyter/kernels/${KERNEL_LANGUAGE}/kernel.json)

    # Uses XEUS_SML_MLB
    configure_file(lang.mlb.in lang.mlb)

    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/lang.0.o
        COMMAND mlton -output lang lang.mlb
        DEPENDS ...)
    install(FILES lang DESTINATION ${CMAKE_INSTALL_BINDIR}/lang)



