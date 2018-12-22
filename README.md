# flutter_embedded

This repo is currently about build automation for Tip of the Tree Clang, Binutils, and Flutter Engine artifacts.  The useage target is for an embedded system.

# Pre-requisites

1. CMake 3.11 or greater

2. Setup depot_tools and add to path.  This provides gclient, ninja, autoninja, etc.

    http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

3. I would recommend replicating these two pages, to ensure your machine is configured and working prior to diving into automation scripts.

    https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment

    https://github.com/flutter/flutter/wiki/Compiling-the-engine


# Build Tip-Of-Tree Clang, Latest Binutils, and Flutter Engine master branch for Linux arm

    git clone https://github.com/jwinarske/flutter_embedded
    cd flutter_embedded
    mkdir build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -GNinja
    autoninja


# Override Variables
To use the override variables, pass them in with the cmake command.  One example

    cmake -DTOOLCHAIN_DIR=~/Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64 -DTARGET_SYSROOT=~/Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/sysroot -DTARGET_TRIPLE=arm-linux-androideabi-clang -DENGINE_REPO=https://github.com/jwinarske/engine -GNinja -DCMAKE_BUILD_TYPE=Debug


### TOOLCHAIN_DIR
This is the directory of the installed toolchain.  The default value used is "${CMAKE_SOURCE_DIR}/sdk/toolchain".  When the toolchain is built, it's installed to this directory.  If TOOLCHAIN_DIR is not set, it will build the toolchain.

### TARGET_SYSROOT
This is the location of the target sysroot.  The default value is "${CMAKE_SOURCE_DIR}/sdk/sysroot".  One approach would be to download target image such as a Raspberry Pi image, and mount it.  Setting TARGET_SYSROOT to the rootfs directory.

### TARGET_TRIPLE
This is the triple of your toolchain.  The default value used is "arm-linux-gnueabihf"

### TARGET_ARCH
This is the target architecture of your build.  It must  match your toolchain, and that which the flutter engine build supports.

### ENGINE_REPO
This is the repo of the flutter engine.  The default value is https://github.com/flutter/engine.git.  If you want to use your own fork, set this variable to point to your fork's url.

### LLVM_TARGETS_TO_BUILD
List of Targets LLVM should be built with.  Relavant to Flutter the options are:
"AArch64;ARM;X86".  Host architecture (x86_64) is implicit, as that is the expected build host.  If crosscompiling compiler-rt, libcxxabi, and libcxx the current scheme expects only a single value for LLVM_TARGETS_TO_BUILD.

### BUILD_COMPILER_RT
Checks out and builds compiler-rt for host and target.  Default value is ON, and valid only when TOOLCHAIN_DIR is not set.

### BUILD_LIBCXXABI
Checks out and builds libcxxabi for host and target.  Default value is ON, and valid only when TOOLCHAIN_DIR is not set.

### BUILD_LIBCXX
Checks out and builds libcxx.  Default value is ON, and valid only when TOOLCHAIN_DIR is not set.

### BUILD_LLD
Checks out and builds lld.  Default value is OFF, and valid only when TOOLCHAIN_DIR is not set.  This option enables the use of "-fuse-ld=lld".

### ENGINE_UNOPTIMIZED
Unoptimized flag, defaults to OFF

### ENGINE_RUNTIME_MODE
If ENGINE_RUNTIME_MODE is not set to debug, profile, or release, it will default to debug.

### ENGINE_DYNAMIC
Enable Dynamic, defaults to off.

### ENGINE_SIMULATOR
Enable simulator, defaults to OFF

### ENGINE_INTERPRETER
Enable interpreter, defaults to OFF

### ENGINE_DART_DEBUG
Enable dart-debug, defaults to OFF

### ENGINE_CLANG
Enable clang, defaults to ON

### ENGINE_GOMA
Enable goma, defaults to OFF

### ENGINE_LTO
Enable link-time optimization, defaults to ON

### ENGINE_EMBEDDER_FOR_TARGET
Embedder for Target, defaults to ON

### ENGINE_ENABLE_VULCAN
Enable Vulcan, defaults to OFF

# Android
Example building Android engine.  The flutter engine uses it's own NDK copy.  So passing in the toolchain file is for project builds (your own executables and libraries).

    cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=~/Android/Sdk/ndk-bundle/build/cmake/android.toolchain.cmake -DANDROID_ABI=armeabi-v7a
    autoninja
    cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=~/Android/Sdk/ndk-bundle/build/cmake/android.toolchain.cmake -DENGINE_ENABLE_VULCAN=on -DANDROID_ABI=x86_64
    autoninja
    cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=~/Android/Sdk/ndk-bundle/build/cmake/android.toolchain.cmake -DENGINE_ENABLE_VULCAN=off -DANDROID_ABI=armeabi-v7a
    autoninja


# Reference Links
http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

https://github.com/flutter/flutter/wiki/Compiling-the-engine
https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment

https://clang.llvm.org/get_started.html
https://libcxx.llvm.org/docs/BuildingLibcxx.html

https://medium.com/@zw3rk/making-a-raspbian-cross-compilation-sdk-830fe56d75ba
https://medium.com/@au42/the-useful-raspberrypi-cross-compile-guide-ea56054de187
https://www.raspberrypi.org/downloads/raspbian/

https://medium.com/flutter-io/flutter-on-raspberry-pi-mostly-from-scratch-2824c5e7dcb1

https://android.googlesource.com/platform/ndk/+/master/docs/BuildSystemMaintainers.md#libc
