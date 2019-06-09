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

if(NOT ANDROID)

    if(NOT TARGET_ARCH)
        set(TARGET_ARCH arm)
    endif()

    if(NOT TOOLCHAIN_DIR)
        set(BUILD_TOOLCHAIN true)
        set(TOOLCHAIN_DIR ${CMAKE_SOURCE_DIR}/sdk/toolchain)

        if(NOT LLVM_TARGETS_TO_BUILD)
            set(LLVM_TARGETS_TO_BUILD ARM) #ARM|AArch64|X86
        endif()
    endif()

    if(NOT TARGET_SYSROOT)
        set(TARGET_SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)
    endif()

    if(NOT TARGET_TRIPLE)
        set(TARGET_TRIPLE ${TARGET_ARCH}-linux-gnueabihf)
    endif()

    set(BUILD_RPI_SYSROOT OFF)
    if(BUILD_SYSROOT AND BUILD_RPI_FLUTTER)
        set(BUILD_RPI_SYSROOT ON)
    endif()
    
    if(NOT LLVM_VERSION)
        set(LLVM_VERSION tags/RELEASE_800/final/)
    endif()

    if(NOT LLVM_VER_DIR)
        set(LLVM_VER_DIR 8.0.0)
    endif()

    if(BUILD_TOOLCHAIN)
        ExternalProject_Add(toolchain
            GIT_REPOSITORY https://github.com/jwinarske/clang_toolchain.git
            GIT_TAG master
            UPDATE_COMMAND ""
            BUILD_IN_SOURCE 0
            LIST_SEPARATOR |
            CMAKE_ARGS
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DBUILD_PLATFORM_SYSROOT=${BUILD_SYSROOT}
                -DBUILD_PLATFORM_RPI=${BUILD_RPI_FLUTTER}
                -DTHIRD_PARTY_DIR=${CMAKE_SOURCE_DIR}/third_party
                -DTOOLCHAIN_DIR=${TOOLCHAIN_DIR}
                -DTOOLCHAIN_FILE_DIR=${CMAKE_BINARY_DIR}
                -DTARGET_SYSROOT=${TARGET_SYSROOT}
                -DTARGET_TRIPLE=${TARGET_TRIPLE}
                -DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}
                -DLLVM_VERSION=${LLVM_VERSION}
                -DLLVM_VER_DIR=${LLVM_VER_DIR}
            INSTALL_COMMAND ${CMAKE_COMMAND} -E copy 
                    ${TOOLCHAIN_DIR}/lib/clang/${LLVM_VER_DIR}/${TARGET_TRIPLE}/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1.0
                    ${CMAKE_BINARY_DIR}/target/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
                ${CMAKE_COMMAND} -E copy 
                    ${TOOLCHAIN_DIR}/lib/clang/${LLVM_VER_DIR}/${TARGET_TRIPLE}/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1.0
                    ${CMAKE_BINARY_DIR}/target/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
                chmod +x ${CMAKE_BINARY_DIR}/target/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1 &&
                chmod +x ${CMAKE_BINARY_DIR}/target/lib/libc++abi${CMAKE_SHARED_LIBRARY_SUFFIX}.1
        )
    endif()
endif()


if(NOT ENGINE_REPO)
    set(ENGINE_REPO https://github.com/flutter/engine.git)
endif()

set(ENGINE_SRC_PATH ${CMAKE_BINARY_DIR}/engine-prefix/src/engine)
include(engine_options)

set(ENGINE_INCLUDE_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})
set(ENGINE_LIBRARIES_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})

# update patch file with toolchain dirs
configure_file(cmake/patches/engine_compiler_build.patch.in ${CMAKE_BINARY_DIR}/engine_compiler_build.patch @ONLY)

if(NOT ANDROID)
    set(DISABLE_ANDROID_HOOKS --custom-var=download_android_deps=false)
endif()

find_program(gclient REQUIRED)
ExternalProject_Add(engine
    DOWNLOAD_COMMAND
        cd ${ENGINE_SRC_PATH} &&
        gclient config --name=src/flutter --unmanaged ${DISABLE_ANDROID_HOOKS} https://github.com/flutter/engine.git &&
        gclient sync -j8
    PATCH_COMMAND
        cd ${ENGINE_SRC_PATH} && 
        cd src && git checkout build/config/compiler/BUILD.gn && git apply ${CMAKE_BINARY_DIR}/engine_compiler_build.patch &&
        cd flutter && git apply ${CMAKE_SOURCE_DIR}/cmake/patches/engine.patch && cd .. &&
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
        ${CMAKE_COMMAND} -E copy ${ENGINE_LIBRARIES_DIR}/libflutter_linux${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_BINARY_DIR}/target/lib
)
if(BUILD_TOOLCHAIN)
    add_dependencies(engine toolchain)
endif()

include_directories(${ENGINE_INCLUDE_DIR})
link_directories(${ENGINE_LIBRARIES_DIR})
