include (ExternalProject)


if(NOT TOOLCHAIN_DIR)
    set(TOOLCHAIN_DIR ${CMAKE_SOURCE_DIR}/sdk/toolchain)
endif()

if(NOT TARGET_SYSROOT)
    set(TARGET_SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)
endif()

if(NOT TARGET_TRIPLE)
    set(TARGET_TRIPLE arm-linux-gnueabihf)
endif()

if(NOT TARGET_ARCHITECTURE)
    set(TARGET_ARCHITECTURE arm)
endif()

if(NOT ENGINE_REPO)
    set(ENGINE_REPO https://github.com/flutter/engine.git)
endif()


set(ENGINE_SRC_PATH ${CMAKE_BINARY_DIR}/engine-prefix/src/engine)
configure_file(cmake/engine.gclient.in ${ENGINE_SRC_PATH}/.gclient @ONLY)


find_program(gclient REQUIRED)

ExternalProject_Add(engine
    DOWNLOAD_COMMAND cd ${ENGINE_SRC_PATH} && gclient sync
    BUILD_IN_SOURCE 1
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND cd src && flutter/tools/gn 
    --target-sysroot ${TARGET_SYSROOT}
    --target-toolchain ${TOOLCHAIN_DIR}
    --target-triple ${TARGET_TRIPLE}
    --linux-cpu ${TARGET_ARCHITECTURE}
    --runtime-mode debug
    --embedder-for-target
    --no-lto
    --target-os linux
    --arm-float-abi hard
    #--unoptimized

    BUILD_COMMAND cd src && autoninja -C out/linux_debug_arm

    INSTALL_COMMAND ""
)

set(FLUTTER_ENGINE_LIBRARIES_DIR ${FLUTTER_ENGINE_SRC_PATH}/out)
set(FLUTTER_ENGINE_INCLUDE_DIR ${FLUTTER_ENGINE_SRC_PATH}/out)


include_directories(
    ${CMAKE_INSTALL_PREFIX}/include
    ${FLUTTER_ENGINE_INCLUDE_DIR}
)

link_directories(
    ${CMAKE_INSTALL_PREFIX}/lib
    ${CMAKE_INSTALL_PREFIX}/lib/static
    ${FLUTTER_ENGINE_LIBRARIES_DIR}
)

if(BUILD_TOOLCHAIN)

    set(LLVM_SRC_DIR ${CMAKE_BINARY_DIR}/llvm)

    set(TARGET_FLAGS "-D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -L${TARGET_SYSROOT}/lib/${TARGTE_TRIPLE} -ldl")


    configure_file(cmake/clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/toolchain.cmake @ONLY)


    #
    # build for host
    #

    ExternalProject_Add(clang

        DOWNLOAD_COMMAND cd ${CMAKE_BINARY_DIR} &&
            svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm &&
            cd llvm/tools &&
            svn co http://llvm.org/svn/llvm-project/cfe/trunk clang

        SOURCE_DIR ${LLVM_SRC_DIR}
        UPDATE_COMMAND ""
        BUILD_IN_SOURCE 0
        CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DLLVM_TARGETS_TO_BUILD=ARM
    )

    ExternalProject_Add(binutils
        URL http://ftp.gnu.org/gnu/binutils/binutils-2.31.tar.gz
        URL_MD5 2a14187976aa0c39ad92363cfbc06505
        BUILD_IN_SOURCE 1
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ./configure 
            --prefix=${TOOLCHAIN_DIR} 
            --target=${TARGET_TRIPLE}
            --enable-gold 
            --enable-ld 
        BUILD_COMMAND make
        INSTALL_COMMAND make install
    )

    #
    # cross compiler for target
    #

    ExternalProject_Add(libcxxabi

        DOWNLOAD_COMMAND cd ${CMAKE_BINARY_DIR}/llvm/projects &&
            svn co http://llvm.org/svn/llvm-project/libcxxabi/trunk libcxxabi

        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_BINARY_DIR}/llvm/projects/libcxxabi
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DLLVM_TARGETS_TO_BUILD=ARM
            -DLIBCXX_ENABLE_SHARED=false
            -DLIBCXXABI_ENABLE_EXCEPTIONS=false
    )
    add_dependencies(libcxxabi clang)

    ExternalProject_Add(libcxx

        DOWNLOAD_COMMAND cd ${CMAKE_BINARY_DIR}/llvm/projects &&
            svn co http://llvm.org/svn/llvm-project/libcxx/trunk libcxx
            
        BUILD_IN_SOURCE 0
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_BINARY_DIR}/llvm/projects/libcxx
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DLLVM_TARGETS_TO_BUILD=ARM
            -DLIBCXX_ENABLE_EXCEPTIONS=false
            -DLIBCXX_ENABLE_RTTI=false
            -DLIBCXX_ENABLE_SHARED=false
            -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=true
            -DLIBCXX_CXX_ABI=libcxxabi
            -DLIBCXX_CXX_ABI_INCLUDE_PATHS=${TOOLCHAIN_DIR}/include/c++/v1
            -DLIBCXX_CXX_ABI_LIBRARY_PATH=/sdk/toochain/lib
    )
    add_dependencies(libcxx clang)

    # only if building toolchain...
    add_dependencies(engine libcxx)
endif()

