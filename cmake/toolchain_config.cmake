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

if(NOT TARGET_ARCH)
    set(TARGET_ARCH arm)
endif()

if(NOT TOOLCHAIN_DIR)
    set(TOOLCHAIN_DIR ${CMAKE_SOURCE_DIR}/sdk/toolchain)
endif()

if(LLVM_CONFIG_PATH)
    include(llvm_config)
else()
    set(LLVM_CONFIG_PATH ${TOOLCHAIN_DIR}/bin/llvm-config CACHE PATH "llvm-config path")
endif()

if (USE_LLVM_BRANCH)
    set(USE_LLVM_BRANCH branches/${USE_LLVM_BRANCH})
else()
    set(USE_LLVM_BRANCH trunk)
endif()

if(NOT TARGET_SYSROOT)
    set(TARGET_SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)
endif()

if(NOT TARGET_TRIPLE)
    set(TARGET_TRIPLE ${TARGET_ARCH}-linux-gnueabihf)
endif()
