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

option(BUILD_PLATFORM_SYSROOT "Build Platform sysroot" ON)
option(BUILD_PLATFORM_SYSROOT_RPI "Build Raspberry Pi Sysroot" ON)

option(BUILD_FLUTTER_RPI "Build RPI Flutter Shell" OFF)
option(BUILD_PI_USERLAND "Build Pi userland repo - !!replaces sysroot/opt/vc!!" OFF)
option(BUILD_HELLO_PI "Build the apps in {sysroot}/opt/vc/src/hello_pi" ON)
option(BUILD_TSLIB "Checkout and build tslib for target" ON)

option(BUILD_FLUTTER_WAYLAND "Build Wayland Flutter Shell" ON)

if(NOT TARGET_ARCH)
    set(TARGET_ARCH "arm" CACHE STRING "Choose the target arch, options are: x64, x86, arm64, or arm." FORCE)
    message(STATUS "ENGINE_RUNTIME_MODE not set, defaulting to arm.")
endif()

if(NOT TARGET_SYSROOT)
    set(TARGET_SYSROOT "${CMAKE_SOURCE_DIR}/sysroot")
endif()

if(NOT THIRD_PARTY_DIR)
    SET(THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/third_party")
endif()

if(NOT TOOLCHAIN_DIR)
    # TODO - only tested with linux
    set(TOOLCHAIN_DIR "${THIRD_PARTY_DIR}/engine/src/buildtools/linux-x64/clang")
endif()

if(NOT DEPOT_TOOLS_DIR)
    SET(DEPOT_TOOLS_DIR "${THIRD_PARTY_DIR}/depot_tools")
endif()
