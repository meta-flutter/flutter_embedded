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

if(NOT ENGINE_REPO)
    set(ENGINE_REPO https://github.com/flutter/engine.git)
endif()
MESSAGE(STATUS "Engine Repo ............ ${ENGINE_REPO}")


set(ENGINE_SRC_PATH ${THIRD_PARTY_DIR}/engine)

include(engine_options)

ExternalProject_Add(engine
    DOWNLOAD_COMMAND
        export PATH=${THIRD_PARTY_DIR}/depot_tools:$ENV{PATH} &&
        virtualenv --python /usr/bin/python2.7 .env &&
        source .env/bin/activate &&
        ${CMAKE_COMMAND} -E make_directory ${ENGINE_SRC_PATH} &&
        cd ${ENGINE_SRC_PATH} &&
        echo ${GCLIENT_CONFIG} > .gclient &&
        gclient sync --no-history --revision ${FLUTTER_ENGINE_SHA} -R -D -j ${NUM_PROC}
    BUILD_IN_SOURCE 0
    CONFIGURE_COMMAND
        export PATH=${THIRD_PARTY_DIR}/depot_tools:$ENV{PATH} &&
        export PKG_CONFIG_PATH=${PKG_CONFIG_PATH} &&
        virtualenv --python /usr/bin/python2.7 .env &&
        source .env/bin/activate &&
        ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/toolchain.custom.BUILD.gn ${THIRD_PARTY_DIR}/engine/src/build/toolchain/custom/BUILD.gn &&
        cd ${ENGINE_SRC_PATH}/src &&
        ./flutter/tools/gn ${ENGINE_FLAGS} &&
        ${CMAKE_COMMAND} -E echo ${ARGS_GN_APPEND} >> ${ARGS_GN_FILE}
    BUILD_COMMAND
        export PATH=${THIRD_PARTY_DIR}/depot_tools:$ENV{PATH} &&
        export PKG_CONFIG_PATH=${PKG_CONFIG_PATH} &&
        virtualenv --python /usr/bin/python2.7 .env &&
        source .env/bin/activate &&
        cd ${ENGINE_SRC_PATH}/src &&
        autoninja -C ${ENGINE_OUT_DIR}
    INSTALL_COMMAND
        ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/${ENGINE_RUNTIME_MODE}/${CHANNEL} &&
        cd ${ENGINE_SRC_PATH}/src &&
        ${CMAKE_COMMAND} -E copy ${ENGINE_OUT_DIR}/icudtl.dat ${CMAKE_BINARY_DIR}/${ENGINE_RUNTIME_MODE}/${CHANNEL} &&
        ${CMAKE_COMMAND} -E copy ${ENGINE_OUT_DIR}/${ENGINE_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_BINARY_DIR}/${ENGINE_RUNTIME_MODE}/${CHANNEL} &&
        ${ENGINE_COPY_HEADER}
)

add_dependencies(engine depot_tools)
if(BUILD_PLATFORM_SYSROOT)
    add_dependencies(engine symlink_fixups)
endif()

set(ENGINE_INCLUDE_DIR ${CMAKE_BINARY_DIR}/${ENGINE_RUNTIME_MODE}/${CHANNEL})
set(ENGINE_LIBRARIES_DIR ${CMAKE_BINARY_DIR}/${ENGINE_RUNTIME_MODE}/${CHANNEL})
include_directories(${ENGINE_INCLUDE_DIR})
link_directories(${ENGINE_LIBRARIES_DIR})

#
# Install
#
set(BUILD_DIR ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR})

install(FILES ${CMAKE_BINARY_DIR}/engine.version DESTINATION share/flutter/sdk)
install(FILES ${BUILD_DIR}/${ENGINE_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX} DESTINATION lib)
install(FILES ${BUILD_DIR}/${ENGINE_HEADER} DESTINATION include)
install(FILES ${BUILD_DIR}/icudtl.dat DESTINATION share/flutter)

install(DIRECTORY ${BUILD_DIR}/flutter_patched_sdk DESTINATION share/flutter/sdk FILES_MATCHING PATTERN "*")

if(CMAKE_CROSSCOMPILING)
  install(FILES ${BUILD_DIR}/gen/frontend_server.dart.snapshot DESTINATION share/flutter/sdk)
  install(FILES ${BUILD_DIR}/clang_x64/dart DESTINATION share/flutter/sdk/clang_x64)
  install(FILES ${BUILD_DIR}/clang_x64/gen_snapshot DESTINATION share/flutter/sdk/clang_x64)
else()
  install(FILES ${BUILD_DIR}/frontend_server.dart.snapshot DESTINATION share/flutter/sdk)
  install(FILES ${BUILD_DIR}/dart DESTINATION share/flutter/sdk/clang_x64)
  install(FILES ${BUILD_DIR}/gen_snapshot DESTINATION share/flutter/sdk/clang_x64)
endif()
