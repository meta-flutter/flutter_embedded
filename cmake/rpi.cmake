

option(BUILD_PI_USERLAND "Build Pi userland repo" OFF)
if(BUILD_PI_USERLAND)

    ExternalProject_Add(pi_userland
        GIT_REPOSITORY https://github.com/jwinarske/userland.git
        GIT_TAG vidtext_fix
        BUILD_IN_SOURCE 0
        PATCH_COMMAND rm -rf ${TARGET_SYSROOT}/opt/vc
        UPDATE_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
            -DCMAKE_INSTALL_PREFIX=${TARGET_SYSROOT}
            -DVMCS_INSTALL_PREFIX=${TARGET_SYSROOT}/opt/vc
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
    )
    if(BUILD_TOOLCHAIN)
        add_dependencies(pi_userland clang)
    endif()  
endif()

option(BUILD_HELLO_PI "Build the apps in /opt/vc/src/hello_pi" ON)
if(BUILD_HELLO_PI)

    # These are C apps...
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
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
    )
    if(BUILD_TOOLCHAIN)
        add_dependencies(hello_pi clang)
    endif()  

endif()


#
# build flutter executable
#

set(FLUTTER_TARGET_NAME "Raspberry Pi")
ExternalProject_Add(rpi_flutter
    GIT_REPOSITORY https://github.com/jwinarske/flutter_from_scratch.git
    GIT_TAG clang_fixes
    PATCH_COMMAND ""
    BUILD_IN_SOURCE 0
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
        -DENGINE_INCLUDE_DIR=${ENGINE_INCLUDE_DIR}
        -DENGINE_LIBRARIES_DIR=${ENGINE_LIBRARIES_DIR}
)
add_dependencies(rpi_flutter engine)

ExternalProject_Add(sdl2
    URL http://www.libsdl.org/release/SDL2-2.0.9.tar.gz
    URL_MD5 f2ecfba915c54f7200f504d8b48a5dfe
    PATCH_COMMAND "" #create symlink to dbus-1
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
        -DPULSEAUDIO=OFF
        -DPULSEAUDIO_SHARED=OFF
        -DVIDEO_KMSDRM=OFF
        -DVIDEO_VULKAN=OFF
)

#ExternalProject_Add(glus
    #GIT_REPOSITORY https://github.com/McNopper/GLUS.git
    #GIT_TAG v2.0
    #UPDATE_COMMAND ""
    #CMAKE_ARGS ../glus/GLUS
        #-DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/app.toolchain.cmake
        #-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/target
        #-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        #-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
#)