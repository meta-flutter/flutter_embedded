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

configure_file(cmake/target.clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/target.toolchain.cmake @ONLY)

if(BUILD_TSLIB AND NOT ANDROID)
    ExternalProject_Add(tslib
        GIT_REPOSITORY https://github.com/kergoth/tslib.git
        GIT_TAG master
        GIT_SHALLOW true
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${TARGET_SYSROOT}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
        -DENABLE_TOOLS=ON
    )
    add_dependencies(tslib engine)
endif()

#
# build flutter glfw example
#
if(BUILD_GLFW_FLUTTER)

    if(BUILD_PLATFORM_SYSROOT)
        ExternalProject_Add(glfw
            GIT_REPOSITORY https://github.com/glfw/glfw.git
            GIT_TAG 3.3.2
            GIT_SHALLOW true
            BUILD_IN_SOURCE 0
            UPDATE_COMMAND ""
            CMAKE_ARGS
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TARGET_SYSROOT}/usr
                -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                -DBUILD_SHARED_LIBS=ON
                -DGLFW_BUILD_EXAMPLES=OFF
                -DGLFW_BUILD_TESTS=OFF
                -DGLFW_BUILD_DOCS=OFF
                -DGLFW_USE_OSMESA=ON
                -DCMAKE_VERBOSE_MAKEFILE=TRUE
                -DCMAKE_THREAD_LIBS_INIT=-lpthread
                -DCMAKE_HAVE_THREADS_LIBRARY=1
                -DCMAKE_USE_PTHREADS_INIT=1
                -DTHREADS_PREFER_PTHREAD_FLAG=ON
        )
        add_dependencies(glfw engine)
    endif()

    ExternalProject_Add(glfw_flutter
        DOWNLOAD_COMMAND ""
        PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cmake/flutter.glfw.cmake ${THIRD_PARTY_DIR}/engine/src/flutter/examples/glfw/CMakeLists.txt
        SOURCE_DIR ${THIRD_PARTY_DIR}/engine/src/flutter/examples/glfw
        BUILD_IN_SOURCE 0
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
#            -DGLFW_LIB=${TARGET_SYSROOT}/usr/lib/libglfw3.so
            -DFLUTTER_LIB=${ENGINE_LIBRARIES_DIR}/libflutter_engine.so
            -DCPACK_DEBIAN_PACKAGE_ARCHITECTURE=${PACKAGE_ARCH}
        INSTALL_COMMAND ""
    )
    add_dependencies(glfw_flutter engine)
    if(BUILD_PLATFORM_SYSROOT)
        add_dependencies(glfw_flutter glfw)
    endif()

    ExternalProject_Add_Step(glfw_flutter package
        DEPENDEES install
        COMMAND cpack --config ./glfw_flutter-prefix/src/glfw_flutter-build/CPackConfig.cmake
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Creating flutter-glfw Package"
        BYPRODUCTS flutter-glfw-1.0.0-Linux-${PACKAGE_ARCH}.deb
        ALWAYS FALSE
    )

endif()

if(BUILD_FLUTTER_PI)

    set(FLUTTER_PI_SOURCE_DIR ${CMAKE_BINARY_DIR}/flutter-pi-prefix/src/flutter-pi)
    ExternalProject_Add(flutter-pi
        GIT_REPOSITORY https://github.com/ardera/flutter-pi.git
        GIT_TAG master
        GIT_SHALLOW true
        BUILD_IN_SOURCE 0
        PATCH_COMMAND 
            ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cmake/flutter.pi.cmake ${FLUTTER_PI_SOURCE_DIR}/CMakeLists.txt &&
            ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/${CHANNEL}/${ENGINE_HEADER} ${FLUTTER_PI_SOURCE_DIR}-build
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=ON
            -DFLUTTER_ENGINE_LIBRARY=${CMAKE_BINARY_DIR}/${CHANNEL}/${ENGINE_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}
            -DPKG_CONFIG_PATH=${PKG_CONFIG_PATH}
            -DCPACK_DEBIAN_PACKAGE_ARCHITECTURE=${PACKAGE_ARCH}
        INSTALL_COMMAND ""
    )
    add_dependencies(flutter-pi engine)

    ExternalProject_Add_Step(flutter-pi package
        DEPENDEES install
        COMMAND cpack --config ${FLUTTER_PI_SOURCE_DIR}-build/CPackConfig.cmake
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Creating flutter-pi Package"
        BYPRODUCTS flutter-pi-1.0.0-Linux-${PACKAGE_ARCH}.deb
        ALWAYS FALSE
    )

endif()
