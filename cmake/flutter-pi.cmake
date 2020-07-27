
set(FLUTTER_PI_SOURCE_DIR ${CMAKE_BINARY_DIR}/flutter-pi-prefix/src/flutter-pi)

ExternalProject_Add(flutter-pi
    GIT_REPOSITORY https://github.com/ardera/flutter-pi.git
    GIT_TAG master
    GIT_SHALLOW true
    BUILD_IN_SOURCE 0
    PATCH_COMMAND 
        ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cmake/files/flutter-pi.cmake ${FLUTTER_PI_SOURCE_DIR}/CMakeLists.txt &&
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
