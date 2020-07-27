
include(ExternalProject)

ExternalProject_Add(vulkan-headers
    GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
    GIT_TAG v1.2.144
    GIT_SHALLOW true
    BUILD_IN_SOURCE 0
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_VERBOSE_MAKEFILE=TRUE
)

ExternalProject_Add(vulkan-loader
    GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Loader.git
    GIT_TAG sdk-1.2.141.0
    GIT_SHALLOW true
    BUILD_IN_SOURCE 0
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_VERBOSE_MAKEFILE=TRUE
        -DVULKAN_HEADERS_INSTALL_DIR=${CMAKE_INSTALL_PREFIX}
#        -DBUILD_WSI_XCB_SUPPORT=OFF
#        -DBUILD_WSI_XLIB_SUPPORT=OFF
#        -DBUILD_WSI_WAYLAND_SUPPORT=OFF
)
add_dependencies(vulkan-loader vulkan-headers)
