
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
