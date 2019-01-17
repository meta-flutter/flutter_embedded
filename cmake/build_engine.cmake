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

include (ExternalProject)

option(BUILD_FLUTTER_ENGINE "Build flutter engine" ON)

if(BUILD_FLUTTER_ENGINE)

    if(NOT ENGINE_REPO)
        set(ENGINE_REPO https://github.com/flutter/engine.git)
    endif()

    set(ENGINE_SRC_PATH ${CMAKE_BINARY_DIR}/engine-prefix/src/engine)
    configure_file(cmake/engine.gclient.in ${ENGINE_SRC_PATH}/.gclient @ONLY)
    include(engine_options)

    set(ENGINE_INCLUDE_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})
    set(ENGINE_LIBRARIES_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})

    # update patch file with toolchain dirs
    configure_file(cmake/patches/engine_compiler_build.patch.in ${CMAKE_BINARY_DIR}/engine_compiler_build.patch @ONLY)

    find_program(gclient REQUIRED)
    ExternalProject_Add(engine
        DOWNLOAD_COMMAND cd ${ENGINE_SRC_PATH} && gclient sync
        PATCH_COMMAND
            cd src && git checkout build/config/compiler/BUILD.gn && git apply ${CMAKE_BINARY_DIR}/engine_compiler_build.patch &&
            cd third_party/dart && git checkout runtime/BUILD.gn && git apply ${CMAKE_SOURCE_DIR}/cmake/patches/dart.patch &&
            cd ../../..
        UPDATE_COMMAND ""
        BUILD_IN_SOURCE 1
        CONFIGURE_COMMAND src/flutter/tools/gn ${ENGINE_FLAGS}
        BUILD_COMMAND autoninja -C src/${ENGINE_OUT_DIR}
        INSTALL_COMMAND
            ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/target/lib &&
            ${CMAKE_COMMAND} -E copy ${ENGINE_LIBRARIES_DIR}/icudtl.dat ${CMAKE_BINARY_DIR}/target/bin &&
            ${CMAKE_COMMAND} -E copy ${ENGINE_LIBRARIES_DIR}/libflutter_engine${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_BINARY_DIR}/target/lib &&
            ${CXX_LIB_COPY_CMD}
    )

    include_directories(${ENGINE_INCLUDE_DIR})
    link_directories(${ENGINE_LIBRARIES_DIR})
    
endif(BUILD_FLUTTER_ENGINE)