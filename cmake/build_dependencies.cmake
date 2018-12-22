include (ExternalProject)

include(engine_options)

if(NOT TOOLCHAIN_DIR)
    set(BUILD_TOOLCHAIN true)
    set(TOOLCHAIN_DIR ${CMAKE_SOURCE_DIR}/sdk/toolchain)
endif()

if(NOT TARGET_SYSROOT)
    set(TARGET_SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)
endif()

if(NOT TARGET_TRIPLE)
    set(TARGET_TRIPLE ${TARGET_ARCH}-linux-gnueabihf)
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
    CONFIGURE_COMMAND cd src && flutter/tools/gn ${ENGINE_FLAGS}
    BUILD_COMMAND cd src && autoninja -C ${ENGINE_OUT_DIR}
    INSTALL_COMMAND ""
)

set(ENGINE_INCLUDE_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})
set(ENGINE_LIBRARIES_DIR ${ENGINE_SRC_PATH}/src/${ENGINE_OUT_DIR})

include_directories(${ENGINE_INCLUDE_DIR})
link_directories(${ENGINE_LIBRARIES_DIR})


if(BUILD_TOOLCHAIN)

    set(LLVM_SRC_DIR ${CMAKE_BINARY_DIR}/llvm)

    if(NOT LLVM_TARGETS_TO_BUILD)
        set(LLVM_TARGETS_TO_BUILD ARM|AArch64|X86)
    endif()

    #
    # built for host
    #
    option(BUILD_COMPILER_RT "Checkout and build compiler-rt" OFF)
    option(BUILD_LIBCXXABI "Checkout and build libcxxabi" ON)
    option(BUILD_LIBCXX "Checkout and build libcxx" ON)
    option(BUILD_LLD "Checkout and build lld" OFF)

    set(LLVM_CHECKOUT
        svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm &&
        cd llvm/tools &&
        svn co http://llvm.org/svn/llvm-project/cfe/trunk clang)

    if(BUILD_COMPILER_RT)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
            cd ${LLVM_SRC_DIR}/projects &&
            svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt)
    endif()

    if(BUILD_LIBCXXABI)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} && 
            cd ${LLVM_SRC_DIR}/projects &&
            svn co http://llvm.org/svn/llvm-project/libcxxabi/trunk libcxxabi)
    endif()
    
    if(BUILD_LIBCXX)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
            cd ${LLVM_SRC_DIR}/projects &&
            svn co http://llvm.org/svn/llvm-project/libcxx/trunk libcxx)
    endif()

    if(BUILD_LLD)
        set(LLVM_CHECKOUT ${LLVM_CHECKOUT} &&
            cd ${CMAKE_BINARY_DIR} &&
            svn co http://llvm.org/svn/llvm-project/lld/trunk lld)
        list(APPEND LLVM_PROJECTS lld)
    endif()

    ExternalProject_Add(clang
        DOWNLOAD_COMMAND cd ${CMAKE_BINARY_DIR} && ${LLVM_CHECKOUT}
        SOURCE_DIR ${LLVM_SRC_DIR}
        UPDATE_COMMAND ""
        BUILD_IN_SOURCE 0
        LIST_SEPARATOR |
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
            -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
            -DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}
            -DLLVM_ENABLE_LLD=${BUILD_LLD}
#            -DLLVM_ENABLE_PROJECTS=${LLVM_PROJECTS}
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
        --enable-lto
    )
    add_dependencies(binutils clang)

    #
    # cross compile for target
    #

    configure_file(cmake/clang.toolchain.cmake.in ${CMAKE_BINARY_DIR}/toolchain.cmake @ONLY)

    if(BUILD_COMPILER_RT)
        ExternalProject_Add(compiler-rt
            DOWNLOAD_COMMAND ""
            BUILD_IN_SOURCE 0
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/compiler-rt
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}/lib/clang/8.0.0
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DLLVM_CONFIG_PATH=${TOOLCHAIN_DIR}/bin/llvm-config
                -DCOMPILER_RT_STANDALONE_BUILD=ON
                -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
                -DCOMPILER_RT_HAS_FPIC_FLAG=ON
                -DCOMPILER_RT_BUILD_XRAY=OFF
                -DCOMPILER_RT_BUILD_SANITIZERS=OFF
        )
        add_dependencies(compiler-rt clang binutils)
    endif()

    if(BUILD_LIBCXXABI)
        ExternalProject_Add(libcxxabi
            DOWNLOAD_COMMAND ""
            BUILD_IN_SOURCE 0
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/libcxxabi
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DLLVM_CONFIG_PATH=${TOOLCHAIN_DIR}/bin/llvm-config
                -DLIBCXXABI_SYSROOT=${TARGET_SYSROOT}
                -DLIBCXXABI_TARGET_TRIPLE=${TARGET_TRIPLE}
#                -DLIBCXXABI_USE_COMPILER_RT=${BUILD_COMPILER_RT}
        )
        add_dependencies(libcxxabi clang binutils)
        if(BUILD_COMPILER_RT)
            add_dependencies(libcxxabi compiler-rt)
        endif()
    endif()

    if(BUILD_LIBCXX)
        ExternalProject_Add(libcxx
            DOWNLOAD_COMMAND ""
            BUILD_IN_SOURCE 0
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${LLVM_SRC_DIR}/projects/libcxx
                -DCMAKE_TOOLCHAIN_FILE=${CMAKE_BINARY_DIR}/toolchain.cmake
                -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN_DIR}
                -DCMAKE_BUILD_TYPE=MinSizeRel
                -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
                -DLLVM_CONFIG_PATH=${TOOLCHAIN_DIR}/bin/llvm-config
                -DLIBCXX_SYSROOT=${TARGET_SYSROOT}
                -DLIBCXX_TARGET_TRIPLE=${TARGET_TRIPLE}
#                -DLIBCXX_USE_COMPILER_RT=${BUILD_COMPILER_RT}
        )
        add_dependencies(libcxx libcxxabi)
        if(BUILD_COMPILER_RT)
            add_dependencies(libcxx compiler-rt)
        endif()
        add_dependencies(engine libcxx)
    endif()

endif()