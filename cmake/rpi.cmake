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

set(RPI_INSTALL_RPATH /usr/lib/${TARGET_TRIPLE_RUNTIME}:${CMAKE_INSTALL_PREFIX}/lib${INSTALL_TRIPLE_SUFFIX})

if(BUILD_TSLIB AND NOT ANDROID)
    ExternalProject_Add(tslib
        GIT_REPOSITORY https://github.com/kergoth/tslib.git
        GIT_TAG master
        GIT_SHALLOW true
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
        -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_STAGING_PREFIX=${EXT_CMAKE_STAGING_PREFIX}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_RPATH=${RPI_INSTALL_RPATH}
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
        -DENABLE_TOOLS=ON
    )
    add_dependencies(tslib engine)
endif()

#
# build flutter glfw example
#
if(BUILD_GLFW_FLUTTER)

    ExternalProject_Add(glfw
        GIT_REPOSITORY https://github.com/glfw/glfw.git
        GIT_TAG 3.3.2
        GIT_SHALLOW true
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
            -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_STAGING_PREFIX=${EXT_CMAKE_STAGING_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DINSTALL_RPATH=${RPI_INSTALL_RPATH}
            -DCMAKE_INSTALL_RPATH=${RPI_INSTALL_RPATH}
            -DCMAKE_VERBOSE_MAKEFILE=ON
            -DCMAKE_THREAD_LIBS_INIT=-lpthread
            -DCMAKE_HAVE_THREADS_LIBRARY=1
            -DCMAKE_USE_PTHREADS_INIT=1
            -DTHREADS_PREFER_PTHREAD_FLAG=ON
            -DBUILD_SHARED_LIBS=ON
            -DGLFW_BUILD_EXAMPLES=OFF
            -DGLFW_BUILD_TESTS=OFF
            -DGLFW_BUILD_DOCS=OFF
            -DGLFW_USE_OSMESA=ON
    )
    add_dependencies(glfw engine)

    ExternalProject_Add(flutter-glfw
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${THIRD_PARTY_DIR}/engine/src/flutter/examples/glfw
        BUILD_IN_SOURCE 0
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
            -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_STAGING_PREFIX=${EXT_CMAKE_STAGING_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_INSTALL_RPATH=${RPI_INSTALL_RPATH}
            -DCMAKE_VERBOSE_MAKEFILE=ON
            -DGLFW_LIB=${EXT_CMAKE_STAGING_PREFIX}/lib/libglfw.so.3.3
            -DGLFW_INCLUDE_PATH=${EXT_CMAKE_STAGING_PREFIX}/include/GLFW
            -DFLUTTER_LIB=${ENGINE_LIBRARIES_DIR}/libflutter_engine.so
            -DCPACK_DEBIAN_PACKAGE_ARCHITECTURE=${PACKAGE_ARCH}
    )
    add_dependencies(flutter-glfw engine)
    add_dependencies(flutter-glfw glfw)

    ExternalProject_Add_Step(flutter-glfw package
        DEPENDEES install
        COMMAND cpack --config ${CMAKE_BINARY_DIR}/flutter-glfw-prefix/src/flutter-glfw-build/CPackConfig.cmake
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Creating flutter-glfw Package"
        BYPRODUCTS flutter-glfw-1.0.0-Linux-${PACKAGE_ARCH}.deb
        ALWAYS FALSE
    )

    #
    # Add to main package
    #
    install(FILES
        ${EXT_CMAKE_STAGING_PREFIX}/lib/libglfw.so
        ${EXT_CMAKE_STAGING_PREFIX}/lib/libglfw.so.3
        ${EXT_CMAKE_STAGING_PREFIX}/lib/libglfw.so.3.3

        DESTINATION
        lib${INSTALL_TRIPLE_SUFFIX}
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
            ${CMAKE_COMMAND} -E copy ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR}/${ENGINE_HEADER} ${FLUTTER_PI_SOURCE_DIR}-build
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/target.toolchain.cmake
            -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_STAGING_PREFIX=${EXT_CMAKE_STAGING_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_INSTALL_RPATH=${RPI_INSTALL_RPATH}
            -DCMAKE_VERBOSE_MAKEFILE=ON
            -DFLUTTER_ENGINE_LIBRARY=${ENGINE_LIBRARIES_DIR}/libflutter_engine.so
            -DPKG_CONFIG_PATH=${PKG_CONFIG_PATH}
            -DCPACK_DEBIAN_PACKAGE_ARCHITECTURE=${PACKAGE_ARCH}
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
