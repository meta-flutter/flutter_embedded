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


if(ENGINE_UNOPTIMIZED)
    list(APPEND ENGINE_FLAGS --unoptimized)
endif()

if(NOT ENGINE_RUNTIME_MODE)
    set(ENGINE_RUNTIME_MODE "debug" CACHE STRING "Choose the runtime mode, options are: debug, profile, release, or jit_release." FORCE)
    message(STATUS "ENGINE_RUNTIME_MODE not set, defaulting to debug.")
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

if(ENGINE_DISABLE_DESKTOP)
    list(APPEND ENGINE_FLAGS --disable-desktop-embeddings)
endif()


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
    if(${TARGET_ARCH} STREQUAL "arm")
        set(TARGET_TRIPLE armv7-unknown-linux-gnueabihf)
    elseif(${TARGET_ARCH} STREQUAL "arm64")
        set(TARGET_TRIPLE aarch64-unknown-linux-gnu)
    elseif(${TARGET_ARCH} STREQUAL "x64")
        set(TARGET_TRIPLE x86_64-unknown-linux-gnu)
    elseif(${TARGET_ARCH} STREQUAL "x86")
        set(TARGET_TRIPLE i386-unknown-linux-gnu)
    endif()

    list(APPEND ENGINE_FLAGS --target-os linux)
    list(APPEND ENGINE_FLAGS --linux-cpu ${TARGET_ARCH})
    list(APPEND ENGINE_FLAGS --target-sysroot ${TARGET_SYSROOT})
    list(APPEND ENGINE_FLAGS --target-toolchain ${TOOLCHAIN_DIR})
    list(APPEND ENGINE_FLAGS --target-triple ${TARGET_TRIPLE})
  
    set(TARGET_OS linux)

endif()

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

set(GCLIENT_CONFIG "solutions=[{\"managed\":False,\"name\":\"src/flutter\",\"url\":\"git@github.com:flutter/engine.git\",\"custom_vars\":{\"download_android_deps\":${DOWNLOAD_ANDROID_DEPS},\"download_windows_deps\":${DOWNLOAD_MSVC_DEPS},}}]")

if(NOT PKG_CONFIG_PATH)
    set(PKG_CONFIG_PATH "/usr/lib/x86_64-linux-gnu/pkgconfig")
else()
    set(PKG_CONFIG_PATH "${PKG_CONFIG_PATH}")
endif()

string(REPLACE ";" " " ENGINE_FLAGS_PRETTY "${ENGINE_FLAGS}")
MESSAGE(STATUS "Engine Flags ........... ${ENGINE_FLAGS_PRETTY}")

if(NOT ENGINE_CUSTOM_LIB_FLAGS)
    # TODO - if rpi sysroot
    set(ENGINE_CUSTOM_LIB_FLAGS "$target_sysroot/usr/lib/arm-linux-gnueabihf/libpthread.a $target_sysroot/usr/lib/gcc/arm-linux-gnueabihf/8/libgcc_eh.a $target_sysroot/usr/lib/arm-linux-gnueabihf/libc.a -Wl,-z,notext")
endif()
MESSAGE(STATUS "custom_lib_flags ....... ${ENGINE_CUSTOM_LIB_FLAGS}")

# TODO - dynamically detect this path
set(ENGINE_OUT_DIR out/linux_debug_arm)
