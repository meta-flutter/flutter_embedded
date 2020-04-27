#
# MIT License
#
# Copyright (c) 2018-2020 Joel Winarske
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

if(NOT ENGINE_COMMIT)
    set(ENGINE_COMMIT 9e5072f0ce81206b99db3598da687a19ce57a863)
endif()
MESSAGE(STATUS "Engine Commit .......... ${ENGINE_COMMIT}")

set(ENGINE_SRC_PATH ${THIRD_PARTY_DIR}/engine)

include(engine_options)

ExternalProject_Add(engine
    DOWNLOAD_COMMAND
        ${CMAKE_COMMAND} -E make_directory ${ENGINE_SRC_PATH} &&
        cd ${ENGINE_SRC_PATH} &&
        gclient config --spec ${GCLIENT_CONFIG} &&
        gclient sync --nohooks --no-history --revision ${ENGINE_COMMIT} -j ${NUM_PROC} -v
    PATCH_COMMAND
        cd ${ENGINE_SRC_PATH}/src &&
        git apply ${CMAKE_SOURCE_DIR}/cmake/patches/custom_BUILD_gn.patch &&
        cd third_party/icu &&
        git apply ${CMAKE_SOURCE_DIR}/cmake/patches/icu.patch
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE 0
    CONFIGURE_COMMAND
        cd ${ENGINE_SRC_PATH}/src && 
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH} ./flutter/tools/gn ${ENGINE_FLAGS} &&
        echo "custom_lib_flags = \"${ENGINE_CUSTOM_LIB_FLAGS}\"" >> ${ENGINE_OUT_DIR}/args.gn
    BUILD_COMMAND ""
        cd ${ENGINE_SRC_PATH}/src && 
        ninja -j ${NUM_PROC} -C ${ENGINE_OUT_DIR}
    INSTALL_COMMAND
        cd ${ENGINE_SRC_PATH}/src && 
        ${CMAKE_COMMAND} -E copy ${ENGINE_OUT_DIR}/icudtl.dat ${CMAKE_BINARY_DIR} &&
        ${CMAKE_COMMAND} -E copy ${ENGINE_OUT_DIR}/libflutter_engine${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_BINARY_DIR} &&
        ${CMAKE_COMMAND} -E copy ${ENGINE_OUT_DIR}/flutter_embedder.h ${CMAKE_BINARY_DIR}
)
add_dependencies(engine sysroot depot_tools)

set(ENGINE_INCLUDE_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})
set(ENGINE_LIBRARIES_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})

include_directories(${ENGINE_INCLUDE_DIR})
link_directories(${ENGINE_LIBRARIES_DIR})
