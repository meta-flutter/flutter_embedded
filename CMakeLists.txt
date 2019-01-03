#
# MIT License
#
# Copyright (c) 2018 Joel Winarske
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

cmake_minimum_required(VERSION 3.11)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "MinSizeRel" CACHE STRING "Choose the type of build, options are: Debug, Release, or MinSizeRel." FORCE)
    message(STATUS "CMAKE_BUILD_TYPE not set, defaulting to MinSizeRel.")
endif()

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" "${CMAKE_SOURCE_DIR}/cmake")

if(NOT BUILD_NUMBER)
    set(BUILD_NUMBER 0)
endif()
set(FLUTTER_EMBEDDER_VERSION 1.0.${BUILD_NUMBER})

set(PACKAGE_NAME flutter-embedder)
project(${PACKAGE_NAME} VERSION "${FLUTTER_EMBEDDER_VERSION}" LANGUAGES CXX C)

message(STATUS "Generator .............. ${CMAKE_GENERATOR}")
message(STATUS "Build Type ............. ${CMAKE_BUILD_TYPE}")

option(BUILD_RPI_EMBEDDER "Build Raspberry Pi Embedder" ON)
option(BUILD_WAYLAND_EMBEDDER "Build Wayland Embedder" OFF)


include(build_dependencies)


# Toolchain file for building apps
configure_file(cmake/app.clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/app.toolchain.cmake @ONLY)


if(BUILD_RPI_EMBEDDER)

    #
    # build /opt/vc/src/hello_pi apps
    #

    configure_file(cmake/hello_pi.cmake ${TARGET_SYSROOT}/opt/vc/src/hello_pi/CMakeLists.txt COPYONLY)

    ExternalProject_Add(hello_pi
        PATCH_COMMAND ""
        SOURCE_DIR ${TARGET_SYSROOT}/opt/vc/src/hello_pi
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
            -DCMAKE_BUILD_TYPE=MinSizeRel
            -DCMAKE_VERBOSE_MAKEFILE=OFF
            -DSDKSTAGE=${TARGET_SYSROOT}
    )
    if(BUILD_LIBCXX)
        add_dependencies(hello_pi libcxx)
    endif()


    #TODO place holder

    set(FLUTTER_EMBEDDER_TARGET_NAME "Raspberry Pi")
    ExternalProject_Add(rpi_embedder
        GIT_REPOSITORY https://github.com/chinmaygarde/flutter_from_scratch.git
        GIT_TAG master
        BUILD_IN_SOURCE 1
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ""
        BUILD_COMMAND autoninja -C out
        INSTALL_COMMAND ""
    )
    add_dependencies(rpi_embedder engine)

elseif(BUILD_WAYLAND_EMBEDDER)

    #TODO place holder

    set(FLUTTER_EMBEDDER_TARGET_NAME "Wayland")
    ExternalProject_Add(wayland_embedder
        GIT_REPOSITORY https://github.com/chinmaygarde/flutter_wayland.git
        GIT_TAG master
        BUILD_IN_SOURCE 1
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ""
        BUILD_COMMAND autoninja -C out
        INSTALL_COMMAND ""
    )
    add_dependencies(wayland_embedder engine)
endif()

message(STATUS "Embedder ............... ${FLUTTER_EMBEDDER_TARGET_NAME}")
