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

option(ENGINE_UNOPTIMIZED "Unoptimized flag" OFF)
if(ENGINE_UNOPTIMIZED)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --unoptimized)
    set(APPEND_UNOPT _unopt)
endif()

if(NOT ENGINE_RUNTIME_MODE)
    set(ENGINE_RUNTIME_MODE "debug" CACHE STRING "Choose the runtime mode, options are: debug, profile, or release." FORCE)
    message(STATUS "ENGINE_RUNTIME_MODE not set, defaulting to debug.")
endif()
set(ENGINE_FLAGS ${ENGINE_FLAGS} --runtime-mode ${ENGINE_RUNTIME_MODE})
set(APPEND_RUNTIME_MODE _${ENGINE_RUNTIME_MODE})


option(ENGINE_DYNAMIC "Enable dynamic" ON)
if(ENGINE_DYNAMIC)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --dynamic)
endif()

option(ENGINE_SIMULATOR "Enable simulator" OFF)
if(ENGINE_SIMULATOR)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --simulator)
endif()

option(ENGINE_INTERPRETER "Enable interpreter" OFF)
if(ENGINE_INTERPRETER)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --interpreter)
endif()

option(ENGINE_DART_DEBUG "Enable dart-debug" OFF)
if(ENGINE_DART_DEBUG)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --dart-debug)
endif()

option(ENGINE_CLANG "Enable clang" ON)
if(ENGINE_CLANG)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --clang)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --no-clang)
endif()

option(ENGINE_GOMA "Enable goma" OFF)
if(ENGINE_GOMA)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --goma)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --no-goma)
endif()

option(ENGINE_LTO "Enable lto" ON)
if(ENGINE_LTO)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --lto)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --no-lto)
endif()

option(ENGINE_EMBEDDER_FOR_TARGET "Embedder for Target" ON)
if(ENGINE_EMBEDDER_FOR_TARGET)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --embedder-for-target)
endif()

option(ENGINE_ENABLE_VULCAN "Enable Vulcan" OFF)
if(ENGINE_ENABLE_VULCAN)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --enable-vulkan)
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
        set(APPEND_ARCH "_${TARGET_ARCH}")
    else()
        if(ANDROID_SYSROOT_ABI STREQUAL "arm")
            set(APPEND_ARCH "")
        else()
            set(TARGET_ARCH ${ANDROID_SYSROOT_ABI})
            set(APPEND_ARCH "_${TARGET_ARCH}")
        endif()
    endif()

    set(ENGINE_FLAGS ${ENGINE_FLAGS} --${TARGET_OS} --android-cpu ${TARGET_ARCH})

elseif(DARWIN)
set(ENGINE_FLAGS ${ENGINE_FLAGS} --ios --ios-cpu ${TARGET_ARCH})  # arm,arm64
    set(TARGET_OS ios)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} 
      --target-sysroot ${TARGET_SYSROOT}
      --target-toolchain ${TOOLCHAIN_DIR}
      --target-triple ${TARGET_TRIPLE}
      --target-os linux
      --linux-cpu ${TARGET_ARCH} # x64,x86,arm64,arm
    )
  
    set(TARGET_OS linux)
    set(APPEND_ARCH "_${TARGET_ARCH}")

endif()

if(TARGET_ARCH MATCHES "^arm")
    if(NOT ENGINE_ARM_FP)
        if(${TARGET_TRIPLE} MATCHES "hf$")
            set(ENGINE_FLAGS ${ENGINE_FLAGS} --arm-float-abi hard)
        elseif(${TARGET_TRIPLE} MATCHES "eabi$")
            set(ENGINE_FLAGS ${ENGINE_FLAGS} --arm-float-abi soft)
        endif()
    elseif(ENGINE_ARM_FP)
        if(ENGINE_ARM_FP STREQUAL "hard" OR ENGINE_ARM_FP STREQUAL "soft" OR ENGINE_ARM_FP STREQUAL "softfp")
           set(ENGINE_FLAGS ${ENGINE_FLAGS} --arm-float-abi ${ENGINE_ARM_FP})
        endif()
    endif()
endif()


set(ENGINE_OUT_DIR out/${TARGET_OS}${APPEND_RUNTIME_MODE}${APPEND_UNOPT}${APPEND_ARCH})
