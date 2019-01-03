#
# build /opt/vc/src/hello_pi apps
#

ExternalProject_Add(hello_pi
    PATCH_COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_SOURCE_DIR}/cmake/hello_pi.cmake
        ${TARGET_SYSROOT}/opt/vc/src/hello_pi/CMakeLists.txt
    SOURCE_DIR ${TARGET_SYSROOT}/opt/vc/src/hello_pi
    BUILD_IN_SOURCE 0
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
        -DCMAKE_BUILD_TYPE=MinSizeRel
        -DCMAKE_VERBOSE_MAKEFILE=OFF
)
if(BUILD_LIBCXX)
    add_dependencies(hello_pi libcxx)
endif()


#
# build flutter executable
#

set(FLUTTER_TARGET_NAME "Raspberry Pi")
ExternalProject_Add(rpi_flutter
    GIT_REPOSITORY https://github.com/chinmaygarde/flutter_from_scratch.git
    GIT_TAG master
    PATCH_COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_SOURCE_DIR}/cmake/rpi.flutter.cmake
        ${CMAKE_BINARY_DIR}/rpi_embedder-prefix/src/rpi_embedder/CMakeLists.txt
    BUILD_IN_SOURCE 0
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
        -DCMAKE_BUILD_TYPE=MinSizeRel
        -DCMAKE_VERBOSE_MAKEFILE=OFF
        -DENGINE_INCLUDE_DIR=${ENGINE_INCLUDE_DIR}
        -DENGINE_LIBRARIES_DIR=${ENGINE_LIBRARIES_DIR}
)
add_dependencies(rpi_flutter engine)
