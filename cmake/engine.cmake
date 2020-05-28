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

find_program(gclient REQUIRED)


if(NOT ENGINE_REPO)
    set(ENGINE_REPO git@github.com:flutter/engine.git)
endif()
MESSAGE(STATUS "Engine Repo ............ ${ENGINE_REPO}")


set(ENGINE_SRC_PATH ${THIRD_PARTY_DIR}/engine)

include(engine_options)

ExternalProject_Add(engine
    DOWNLOAD_COMMAND
        ${CMAKE_COMMAND} -E make_directory ${ENGINE_SRC_PATH} && cd ${ENGINE_SRC_PATH} &&
        gclient config --spec ${GCLIENT_CONFIG} &&
        gclient sync --no-history --revision ${FLUTTER_ENGINE_SHA} -R -D -j ${NUM_PROC} -v && sync
    PATCH_COMMAND 
        ${ENGINE_PATCH_CLR} && ${ENGINE_PATCH_SET} && sync
    BUILD_IN_SOURCE 0
    CONFIGURE_COMMAND
        cd ${ENGINE_SRC_PATH}/src &&
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH} ./flutter/tools/gn ${ENGINE_FLAGS} &&
        ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/BUILD.gn ${THIRD_PARTY_DIR}/engine/src/build/toolchain/custom/BUILD.gn &&
        ${CMAKE_COMMAND} -E echo ${ARGS_GN_APPEND} >> ${ARGS_GN_FILE} && sync
    BUILD_COMMAND
        ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/BUILD.gn ${THIRD_PARTY_DIR}/engine/src/build/toolchain/custom/BUILD.gn &&
        cd ${ENGINE_SRC_PATH}/src &&
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH} ninja -j ${NUM_PROC} -C ${ENGINE_OUT_DIR}
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
if(NOT ENGINE_DISABLE_DESKTOP AND NOT ENGINE_EMBEDDER_FOR_TARGET)
    install(DIRECTORY ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/flutter_linux DESTINATION share/flutter/engine)
else()
    install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/${ENGINE_HEADER} DESTINATION  share/flutter/engine)
endif()

install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/icudtl.dat DESTINATION bin)
install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/${ENGINE_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX} DESTINATION lib${PACKAGE_LIB_PATH_SUFFIX})
install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/flutter_patched_sdk/platform_strong.dill DESTINATION share/flutter/engine/flutter_patched_sdk)
install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/flutter_patched_sdk/platform_strong.dill.d DESTINATION share/flutter/engine/flutter_patched_sdk)
if(${ENGINE_RUNTIME_MODE} STREQUAL "debug")
    install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/flutter_patched_sdk/platform_strong.dill.S DESTINATION share/flutter/engine/flutter_patched_sdk)
endif()
install(FILES ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/flutter_patched_sdk/vm_outline_strong.dill DESTINATION share/flutter/engine/flutter_patched_sdk)

#
# Package - TODO platforms other than Linux
#
if(UNIX)
    set(CPACK_GENERATOR "DEB")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Joel Winarske")
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${PACKAGE_ARCH})
    set(CPACK_DEBIAN_PACKAGE_DEPENDS)
endif()

set(CPACK_PACKAGE_NAME ${ENGINE_NAME})
set(CPACK_PACKAGE_VENDOR "JoWi Electronics")
set(CPACK_DEFAULT_PACKAGE_DESCRIPTION_SUMMARY "Flutter Embedder Engine - ${ENGINE_RUNTIME_MODE} ${CHANNEL}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/cmake/files/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
set(CPACK_PACKAGE_FILE_NAME ${ENGINE_NAME}-${ENGINE_RUNTIME_MODE}-${CHANNEL}-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${PACKAGE_ARCH})

include(CPack)
