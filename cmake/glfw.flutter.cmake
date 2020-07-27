#
# build flutter glfw example
#
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
