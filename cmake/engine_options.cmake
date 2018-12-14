if(NOT TARGET_ARCHITECTURE)
    set(TARGET_ARCHITECTURE arm)
endif()

option(ENGINE_UNOPTIMIZED "Unoptimized flag" OFF)
if(ENGINE_UNOPTIMIZED)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --unoptimized)
    set(APPEND_UNOPT _unopt)
endif()

if(NOT ENGINE_RUNTIME_MODE)
    set(ENGINE_RUNTIME_MODE "debug" CACHE STRING "Choose the runtime mode, options are: debug, profile, or release." FORCE)
    message(STATUS "ENGINE_RUNTIME_MODE not set, defaulting to debug.")
endif()
set(ENGINE_FLAGS ${ENGINE_FLAGS} --runtime-mode ${ENGINE_RUNTIME_MODE})
set(APPEND_RUNTIME_MODE _${ENGINE_RUNTIME_MODE})


option(ENGINE_DYNAMIC "Enable dynamic" OFF)
if(ENGINE_DYNAMIC)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --dynamic)
endif()

option(ENGINE_SIMULATOR "Enable simulator" OFF)
if(ENGINE_SIMULATOR)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --simulator)
endif()

option(ENGINE_INTERPRETER "Enable interpreter" OFF)
if(ENGINE_INTERPRETER)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --interpreter)
endif()

option(ENGINE_DART_DEBUG "Enable dart-debug" OFF)
if(ENGINE_DART_DEBUG)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --dart-debug)
endif()

option(ENGINE_CLANG "Enable clang" ON)
if(ENGINE_CLANG)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --clang)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --no-clang)
endif()

option(ENGINE_GOMA "Enable goma" OFF)
if(ENGINE_GOMA)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --goma)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --no-goma)
endif()

option(ENGINE_LTO "Enable lto" OFF)
if(ENGINE_LTO)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --lto)
else()
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --no-lto)
endif()

option(ENGINE_EMBEDDER_FOR_TARGET "Embedder for Target" OFF)
if(ENGINE_EMBEDDER_FOR_TARGET)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --embedder-for-target)
endif()

option(ENGINE_ENABLE_VULCAN "Enable Vulcan" OFF)
if(ENGINE_ENABLE_VULCAN)
    set(ENGINE_FLAGS ${ENGINE_FLAGS} --enable-vulkan)
endif()


if(ANDROID)
    # variables set in android.toolchain.cmake
    set(TOOLCHAIN_DIR ${ANDROID_TOOLCHAIN_ROOT})
    set(TARGET_SYSROOT ${ANDROID_SYSROOT})
    set(TARGET_TRIPLE ${ANDROID_LLVM_TRIPLE})

    #--android-cpu {arm,x64,x86,arm64}
    
    if(ANDROID_SYSROOT_ABI STREQUAL "x86_64")
        set(APPEND_ARCH "_x64")
        set(TARGET_ARCHITECTURE x64)
        set(FLAG_CPU_CONFIG --android-cpu x64)
    else()
        if(ANDROID_SYSROOT_ABI STREQUAL "arm")
            set(APPEND_ARCH "")
        else()
            set(APPEND_ARCH "_${ANDROID_SYSROOT_ABI}")
            set(FLAG_CPU_CONFIG --android-cpu ${ANDROID_SYSROOT_ABI})
        endif()
    endif()

    set(ENGINE_CONFIG --android ${FLAG_CPU_CONFIG})
    set(TARGET_OS android)
    

elseif(DARWIN)
    set(ENGINE_CONFIG --ios --ios-cpu ${TARGET_ARCHITECTURE})  # arm,arm64
    set(TARGET_OS ios)
else()
    set(ENGINE_CONFIG 
      --target-sysroot ${TARGET_SYSROOT}
      --target-toolchain ${TOOLCHAIN_DIR}
      --target-triple ${TARGET_TRIPLE}
      --target-os linux
      --linux-cpu ${TARGET_ARCHITECTURE} # x64,x86,arm64,arm
      --no-lto
    )
  
    set(TARGET_OS linux)
endif()

if(TARGET_ARCHITECTURE MATCHES "^arm")
    if(ENGINE_ARM_FP)
        if(ENGINE_ARM_FP STREQUAL "hard" OR 
           ENGINE_ARM_FP STREQUAL "soft" OR 
           ENGINE_ARM_FP STREQUAL "softfp")
            set(ENGINE_FLAGS ${ENGINE_FLAGS} --arm-float-abi ${ENGINE_ARM_FP})
        endif()
    endif()
endif()

if(NOT TOOLCHAIN_DIR)
    set(BUILD_TOOLCHAIN true)
    set(TOOLCHAIN_DIR ${CMAKE_SOURCE_DIR}/sdk/toolchain)
endif()

if(NOT TARGET_SYSROOT)
    set(TARGET_SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)
endif()

if(NOT TARGET_TRIPLE)
    set(TARGET_TRIPLE ${TARGET_ARCHITECTURE}-linux-gnueabihf)
endif()


set(ENGINE_OUT_DIR out/${TARGET_OS}${APPEND_RUNTIME_MODE}${APPEND_UNOPT}${APPEND_ARCHITECTURE})
