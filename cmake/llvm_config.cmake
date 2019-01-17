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

message(STATUS "llvm-config ............ ${LLVM_CONFIG_PATH}")

set(CONFIG_COMMAND ${LLVM_CONFIG_PATH}
    "--version"
    "--cflags"
    "--cxxflags"
    "--ldflags"
    )

execute_process(
    COMMAND ${CONFIG_COMMAND}
    RESULT_VARIABLE HAD_ERROR
    OUTPUT_VARIABLE CONFIG_OUTPUT
)

if(NOT HAD_ERROR)
    string(REGEX REPLACE "[ \t]*[\r\n]+[ \t]*" ";" CONFIG_OUTPUT ${CONFIG_OUTPUT})
else()
    string(REPLACE ";" " " CONFIG_COMMAND_STR "${CONFIG_COMMAND}")
    message(STATUS "${CONFIG_COMMAND_STR}")
    message(FATAL_ERROR "llvm-config failed with status ${HAD_ERROR}")
endif()

list(GET CONFIG_OUTPUT 0 __VERSION)
list(GET CONFIG_OUTPUT 1 __CFLAGS)
list(GET CONFIG_OUTPUT 2 __CXXFLAGS)
list(GET CONFIG_OUTPUT 3 __LDFLAGS)

string(REGEX REPLACE "svn" "" __VERSION ${__VERSION})
set(LLVM_VERSION ${__VERSION} CACHE PATH "llvm version")
set(LLVM_CFLAGS ${__CFLAGS} CACHE PATH "llvm c flags")
set(LLVM_CXXFLAGS ${__CXXFLAGS} CACHE PATH "llvm cxx flags")
set(LLVM_LDFLAGS ${__LDFLAGS} CACHE PATH "llvm linker flags")
