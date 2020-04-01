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


option(ENGINE_UNOPTIMIZED "Unoptimized flag" OFF)
option(ENGINE_INTERPRETER "Enable interpreter" OFF)
option(ENGINE_DART_DEBUG "Enable dart-debug" OFF)
option(ENGINE_FULL_DART_DEBUG "Enable full-dart-debug" OFF)
option(ENGINE_SIMULATOR "Enable Simulator" OFF)
option(ENGINE_GOMA "Enable goma" OFF)
option(ENGINE_LTO "Enable lto" ON)
option(ENGINE_CLANG "Enable clang" ON)
option(ENGINE_EMBEDDER_FOR_TARGET "Embedder for Target" ON)
option(ENGINE_ENABLE_VULCAN "Enable Vulcan" OFF)
option(ENGINE_ENABLE_FONTCONFIG "Enable Font Config" ON)
option(ENGINE_ENABLE_SKSHAPER "Enable skshaper" OFF)
option(ENGINE_ENABLE_VULCAN_VALIDATION_LAYERS "Enable Vulcan Validation Layers" OFF)
option(ENGINE_COVERAGE "Enable Code Coverage" OFF)
option(ENGINE_FULL_DART_SDK "Enable Full Dart SDK" ON)
option(ENGINE_DISABLE_DESKTOP "Disable Desktop" ON)


if(NOT ENGINE_PATCH_CLR)
    set(ENGINE_PATCH_CLR
        cd ${ENGINE_SRC_PATH}/src/third_party/icu &&
        git checkout .
    )
endif()

if(NOT ENGINE_PATCH_SET)
    set(ENGINE_PATCH_SET
        cd ${ENGINE_SRC_PATH}/src/third_party/icu &&
        git apply ${CMAKE_SOURCE_DIR}/cmake/files/icu.patch
    )
endif()
if(NOT CHANNEL)
    set(CHANNEL "stable" CACHE STRING "Choose the channel, options are: master, dev, beta, stable" FORCE)
    message(STATUS "Flutter Channel not set, defaulting to stable")
endif()

if(${PREV_CHANNEL} NOT STREQUAL ${CHANNEL})
    message(STATUS "Switching Flutter Channel")
    set(PREV_CHANNEL ${CHANNEL})
    set(ENGINE_FORCE_DOWNLOAD ON)
endif()

message(STATUS "Flutter Channel ........ ${CHANNEL}")

include(FetchContent)
FetchContent_Declare(engine-version
    URL https://raw.githubusercontent.com/flutter/flutter/${CHANNEL}/bin/internal/engine.version
    DOWNLOAD_NAME engine.version
    DOWNLOAD_NO_EXTRACT TRUE
    DOWNLOAD_DIR ${CMAKE_BINARY_DIR}
)

FetchContent_GetProperties(engine-version)
if(NOT engine-version_POPULATED)
    FetchContent_Populate(engine-version)
    file(READ ${CMAKE_BINARY_DIR}/engine.version FLUTTER_ENGINE_SHA)
    string(REPLACE "\n" "" FLUTTER_ENGINE_SHA ${FLUTTER_ENGINE_SHA})
else()
    MESSAGE(FATAL "Unable to determine engine-version, please override FLUTTER_ENGINE_SHA")
endif()

message(STATUS "Engine SHA1 ............ ${FLUTTER_ENGINE_SHA}")


if(ENGINE_UNOPTIMIZED)
    list(APPEND ENGINE_FLAGS --unoptimized)
endif()

if(NOT ENGINE_RUNTIME_MODE)
    set(ENGINE_RUNTIME_MODE "debug" CACHE STRING "Choose the runtime mode, options are: debug, profile, release, or jit_release." FORCE)
    message(STATUS "ENGINE_RUNTIME_MODE not set, defaulting to debug")
endif()
if(${PREV_ENGINE_RUNTIME_MODE} NOT STREQUAL ${ENGINE_RUNTIME_MODE})
    message(STATUS "Switching Engine Runtime Mode")
    set(PREV_ENGINE_RUNTIME_MODE ${ENGINE_RUNTIME_MODE})
    set(ENGINE_FORCE_DOWNLOAD ON)
endif()

list(APPEND ENGINE_FLAGS --runtime-mode ${ENGINE_RUNTIME_MODE})

if(ENGINE_INTERPRETER)
    list(APPEND ENGINE_FLAGS --interpreter)
endif()

if(ENGINE_DART_DEBUG)
    list(APPEND ENGINE_FLAGS --dart-debug)
endif()

if(ENGINE_FULL_DART_DEBUG)
    list(APPEND ENGINE_FLAGS --full-dart-debug)
endif()

if(ENGINE_SIMULATOR)
    list(APPEND ENGINE_FLAGS --simulator)
endif()

if(ENGINE_GOMA)
    list(APPEND ENGINE_FLAGS --goma)
else()
    list(APPEND ENGINE_FLAGS --no-goma)
endif()

if(ENGINE_LTO)
    list(APPEND ENGINE_FLAGS --lto)
else()
    list(APPEND ENGINE_FLAGS --no-lto)
endif()

if(ENGINE_CLANG)
    list(APPEND ENGINE_FLAGS --clang)
else()
    list(APPEND ENGINE_FLAGS --no-clang)
endif()

if(ENGINE_ENABLE_VULCAN)
    list(APPEND ENGINE_FLAGS --enable-vulkan)
endif()

if(ENGINE_ENABLE_FONTCONFIG)
    list(APPEND ENGINE_FLAGS --enable-fontconfig)
endif()

if(ENGINE_ENABLE_SKSHAPER)
    list(APPEND ENGINE_FLAGS --enable-skshaper)
endif()

if(ENGINE_ENABLE_VULCAN_VALIDATION_LAYERS)
    list(APPEND ENGINE_FLAGS --enable-vulkan-validation-layers)
endif()

if(ENGINE_EMBEDDER_FOR_TARGET)
    list(APPEND ENGINE_FLAGS --embedder-for-target)
endif()

if(ENGINE_COVERAGE)
    list(APPEND ENGINE_FLAGS --coverage)
endif()

if(ENGINE_FULL_DART_SDK)
    list(APPEND ENGINE_FLAGS --full-dart-sdk)
else()
    list(APPEND ENGINE_FLAGS --no-full-dart-sdk)
endif()

# flag not present in stable
if(NOT ${CHANNEL} STREQUAL "stable")
    if(ENGINE_DISABLE_DESKTOP)
         list(APPEND ENGINE_FLAGS --disable-desktop-embeddings)
    endif()
endif()

set(ENGINE_LIB_FLAGS)

if(ANDROID)

    set(TARGET_OS android)

    # "ANDROID_" prefixed variables are set in android.toolchain.cmake
    set(TOOLCHAIN_DIR ${ANDROID_TOOLCHAIN_ROOT})
    set(TARGET_SYSROOT ${ANDROID_SYSROOT})
    set(TARGET_TRIPLE ${ANDROID_LLVM_TRIPLE})

    # arm,x64,x86,arm64
    if(ANDROID_SYSROOT_ABI STREQUAL "x86_64")
        set(TARGET_ARCH x64)
    else()
        set(TARGET_ARCH ${ANDROID_SYSROOT_ABI})
    endif()

    list(APPEND ENGINE_FLAGS --android --android-cpu ${TARGET_ARCH})

elseif(DARWIN)
    list(APPEND ENGINE_FLAGS --ios --ios-cpu ${TARGET_ARCH})  # arm,arm64
    set(TARGET_OS ios)
else()
    # Use toolchain base triple, tuning will happen elsewhere
    if(${TARGET_ARCH} STREQUAL "arm")

        set(TARGET_TRIPLE armv7-unknown-linux-gnueabihf)
        set(TARGET_TRIPLE_RUNTIME arm-linux-gnueabihf)
        
        # if must match target arch or it will fail install
        set(PACKAGE_ARCH armhf)

        if(NOT PKG_CONFIG_PATH)
            set(PKG_CONFIG_PATH ${TARGET_SYSROOT}/usr/lib/${TARGET_TRIPLE_RUNTIME}/pkgconfig:/usr/share/pkgconfig)
        endif()

        set(ENGINE_OUT_DIR out/linux_${ENGINE_RUNTIME_MODE}_arm)

        if(BUILD_PLATFORM_SYSROOT_RPI)
            set(TARGET_TRIPLE armv7-neon-vfpv4-linux-gnueabihf)
            set(TUNEABI cortexa7t2hf)
            set(PACKAGE_LIB_PATH_SUFFIX /${TARGET_TRIPLE_RUNTIME})
        endif()

        # missing in stable channel
        if(${CHANNEL} STREQUAL "stable")
            set(LLVM_VERSION 8.0.0)
        else()
            set(LLVM_VERSION 11.0.0)
        endif()

        configure_file(cmake/files/libclang_rt.builtins-armhf.a
            ${THIRD_PARTY_DIR}/engine/src/buildtools/linux-x64/clang/lib/clang/${LLVM_VERSION}/lib/linux/libclang_rt.builtins-armhf.a
            COPYONLY
        )

        # Engine Link Flags
        list(APPEND ENGINE_LIB_FLAGS -Wl,-z,notext)
        list(APPEND ENGINE_LIB_FLAGS -nostdlib++)
        list(APPEND ENGINE_LIB_FLAGS -fuse-ld=lld)
        string(REPLACE ";" " " ENGINE_LIB_FLAGS "${ENGINE_LIB_FLAGS}")
        
        # Target CXX Flags
        list(APPEND TARGET_CXX_FLAGS -I${THIRD_PARTY_DIR}/engine/src/buildtools/linux-x64/clang/include)
        if(BUILD_FLUTTER_RPI)
            list(APPEND TARGET_CXX_FLAGS -I${TARGET_SYSROOT}/opt/vc/include)
            list(APPEND TARGET_CXX_LINK_FLAGS -Wl,-rpath,'$ORIGIN/usr/lib/${TARGET_TRIPLE_RUNTIME}/')
        endif()
        if(BUILD_GLFW_FLUTTER)
            list(APPEND TARGET_CXX_FLAGS -DGLFW_EXPOSE_NATIVE_EGL)
            list(APPEND TARGET_CXX_FLAGS -DGLFW_INCLUDE_ES2)
        endif()
        list(APPEND TARGET_CXX_FLAGS -flto=thin)
        string(REPLACE ";" " " TARGET_CXX_FLAGS "${TARGET_CXX_FLAGS}")

        # Target Link Flags
        if(${CHANNEL} STREQUAL "stable")
            list(APPEND TARGET_CXX_LINK_FLAGS -L${THIRD_PARTY_DIR}/engine/src/buildtools/linux-x64/clang/lib/clang/${LLVM_VERSION}/armv7-linux-gnueabihf/lib)
        else()
            list(APPEND TARGET_CXX_LINK_FLAGS ${THIRD_PARTY_DIR}/engine/src/buildtools/linux-x64/clang/lib/armv7-unknown-linux-gnueabihf/c++/libc++.a)
            list(APPEND TARGET_CXX_LINK_FLAGS -L${THIRD_PARTY_DIR}/engine/src/buildtools/linux-x64/clang/lib/clang/${LLVM_VERSION}/lib/armv7-unknown-linux-gnueabihf)
            list(APPEND TARGET_CXX_LINK_FLAGS -nostdlib++)
        endif()
        list(APPEND TARGET_CXX_LINK_FLAGS -fuse-ld=lld)
        list(APPEND TARGET_CXX_LINK_FLAGS -L${TARGET_SYSROOT}/lib/arm-linux-gnueabihf)
        string(REPLACE ";" " " TARGET_CXX_LINK_FLAGS "${TARGET_CXX_LINK_FLAGS}")

    elseif(${TARGET_ARCH} STREQUAL "arm64")

        set(TARGET_TRIPLE aarch64-unknown-linux-gnu)
        set(ENGINE_OUT_DIR out/linux_${ENGINE_RUNTIME_MODE}_arm64)
    elseif(${TARGET_ARCH} STREQUAL "x64")
        set(TARGET_TRIPLE x86_64-unknown-linux-gnu)
        if(NOT PKG_CONFIG_PATH)
            set(PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig)
        endif()
        set(ENGINE_OUT_DIR out/linux_${ENGINE_RUNTIME_MODE}_x64)
        set(TARGET_SYSROOT ${THIRD_PARTY_DIR}/engine/src/build/linux/debian_sid_amd64-sysroot)
    elseif(${TARGET_ARCH} STREQUAL "x86")
        set(TARGET_TRIPLE i386-unknown-linux-gnu)
        set(ENGINE_OUT_DIR out/linux_${ENGINE_RUNTIME_MODE}_x86)
    endif()

    if(NOT ENGINE_DISABLE_DESKTOP AND NOT ENGINE_EMBEDDER_FOR_TARGET)
        set(ENGINE_NAME libflutter_linux_gtk)
        set(ENGINE_COPY_HEADER ${CMAKE_COMMAND} -E copy_directory ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/flutter_linux ${CMAKE_BINARY_DIR}/${CHANNEL})
    else()
        set(ENGINE_NAME libflutter_engine)
        set(ENGINE_HEADER flutter_embedder.h)
        set(ENGINE_COPY_HEADER ${CMAKE_COMMAND} -E copy ${THIRD_PARTY_DIR}/engine/src/${ENGINE_OUT_DIR}/${ENGINE_HEADER} ${CMAKE_BINARY_DIR}/${CHANNEL})
    endif()

    list(APPEND ENGINE_FLAGS --target-os linux)
    list(APPEND ENGINE_FLAGS --linux-cpu ${TARGET_ARCH})
    list(APPEND ENGINE_FLAGS --target-sysroot ${TARGET_SYSROOT})
    list(APPEND ENGINE_FLAGS --target-toolchain ${TOOLCHAIN_DIR})
    list(APPEND ENGINE_FLAGS --target-triple ${TARGET_TRIPLE})
  
    set(TARGET_OS linux)

endif()

MESSAGE(STATUS "ENGINE_LIB_FLAGS........ ${ENGINE_LIB_FLAGS}")

#set(ENV{PKG_CONFIG_PATH} ${PKG_CONFIG_PATH})
message(STATUS "PKG_CONFIG_PATH ........ ${PKG_CONFIG_PATH}")

if(TARGET_ARCH MATCHES "^arm")
    if(NOT ENGINE_ARM_FP)
        if(${TARGET_TRIPLE} MATCHES "hf$")
            list(APPEND ENGINE_FLAGS --arm-float-abi hard)
        elseif(${TARGET_TRIPLE} MATCHES "eabi$")
            list(APPEND ENGINE_FLAGS --arm-float-abi soft)
        endif()
    elseif(ENGINE_ARM_FP)
        if(ENGINE_ARM_FP STREQUAL "hard" OR ENGINE_ARM_FP STREQUAL "soft" OR ENGINE_ARM_FP STREQUAL "softfp")
            list(APPEND ENGINE_FLAGS --arm-float-abi ${ENGINE_ARM_FP})
        endif()
    endif()
endif()


if(NOT ANDROID)
    set(DOWNLOAD_ANDROID_DEPS "False")
else()
    set(DOWNLOAD_ANDROID_DEPS "True")
endif()

if(NOT MSVC)
    set(DOWNLOAD_MSVC_DEPS "False")
else()
    set(DOWNLOAD_MSVC_DEPS "True")
endif()

set(GCLIENT_CONFIG "solutions=[{\"managed\":False,\"name\":\"src/flutter\",\"url\":\"${ENGINE_REPO}\",\"custom_vars\":{\"download_android_deps\":${DOWNLOAD_ANDROID_DEPS},\"download_windows_deps\":${DOWNLOAD_MSVC_DEPS},}}]")


set(ARGS_GN_FILE ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR}/args.gn)

set(ARGS_GN_APPEND "arm_tune = \"${TUNEABI}\"")


string(REPLACE ";" " " ENGINE_FLAGS_PRETTY "${ENGINE_FLAGS}")
message(STATUS "Engine Flags ........... ${ENGINE_FLAGS_PRETTY}")


if(ENGINE_FORCE_DOWNLOAD)
    set(ENGINE_FORCE_DOWNLOAD OFF)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove engine-prefix/src/engine-stamp/*
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endif()


configure_file(${CMAKE_SOURCE_DIR}/cmake/files/BUILD.gn ${CMAKE_BINARY_DIR}/BUILD.gn @ONLY)
