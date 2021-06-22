# flutter_embedded

This repo is used for CI automation to build flutter-engine embedder for Linux.

# Project Status

x86_86 and aarch64 functional

No external toolchain is required, it uses toolchain pulled as part of engine build - Clang Toolchain.

If your are using a sysroot different than that included as default, you will need to override a few variables.  See examples below.

The original Yocto Layer to build Engine with variety of Flutter embedders:  [meta-flutter](https://github.com/jwinarske/meta-flutter)


# Build Example

See CI build jobs here: https://github.com/jwinarske/flutter_embedded/blob/ci/.github/workflows/blank.yml

## Switching channels
To switch channels add variable CHANNEL to cmake invocation.  Like this

    cmake .. -DCHANNEL=beta
    make package -j8

To build all channels of Engine/GLFW shell for Raspberry Pi armv7 in your nightly CI build job, you could do this

    git clone https://github.com/jwinarske/flutter_embedded
    cd flutter_embedded
    mkdir build && cd build
    cmake ..
    make package -j8
    cmake .. -DCHANNEL=beta
    make package -j8
    cmake .. -DCHANNEL=dev
    make package -j8
    cmake .. -DCHANNEL=master
    make package -j8
    cmake .. -DCHANNEL=stable -DENGINE_RUNTIME_MODE=release
    make package -j8
    cmake .. -DCHANNEL=beta
    make package -j8
    cmake .. -DCHANNEL=dev
    make package -j8
    cmake .. -DCHANNEL=master
    make package -j8

# Override Variables
To use the override variables, pass them in with the cmake command.  One example

    cmake -DTOOLCHAIN_DIR=~/Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64 -DTARGET_SYSROOT=~/Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/sysroot  -DENGINE_REPO=https://github.com/jwinarske/engine -DCMAKE_BUILD_TYPE=Release

### TARGET_SYSROOT
This is the location of the target sysroot.  The default value is "${CMAKE_SOURCE_DIR}/sdk/sysroot".  One approach would be to download target image such as a Raspberry Pi image, and mount it.  Setting TARGET_SYSROOT to the rootfs directory.

### TARGET_ARCH
This is the target architecture of your build.  It must  match your toolchain, and that which the flutter engine build supports.

### ENGINE_REPO
This is the repo of the flutter engine.  The default value is https://github.com/flutter/engine.git.  If you want to use your own fork, set this variable to point to your fork's url.

### ENGINE_UNOPTIMIZED
Unoptimized flag, defaults to OFF

### ENGINE_RUNTIME_MODE
If ENGINE_RUNTIME_MODE is not set to `debug`, `profile`, or `release`, it defaults to `debug`.

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

### ENGINE_ENABLE_VULKAN
Enable Vulkan, defaults to OFF

## Native Flutter Target Debug
I am successfully able to single step the Flutter Embedder using Host Side gdb-multiarch, and latest Eclipse release.  Target side requires gdbserver installed.  LLDB will be at a later date.

    sudo apt-get install gdbserver

Change build flags in this file

    {build folder}/engine-prefix/src/engine/src/build/config/compiler/BUILD.gn

To include

    if (is_linux) {
        if (current_cpu != "x86") {
            cflags_cc += [ 
            "-ggdb",
            "-ggdb3",

Rebuild Engine

Copy Artifact

    scp {absolute build folder}/engine-prefix/src/engine/src/out/linux_debug_arm/so.unstripped/libflutter_engine.so pi@raspberrypi.local:/home/pi/lib

Inside Eclipse - Import C/C++ Executable, and select the Flutter binary.


*Configuration - via Debugger Dialog*

    Main / C/C++ Application: flutter

    Main / Connection: Remote Host

    Main / Remote Absolute File Path for C/C++ Application: /home/pi/bin/flutter

    Main / Commands to execute before application

        export LD_LIBRARY_PATH=/home/pi/lib

    Main / Skip download to target path [TRUE]

    Arguments: /home/pi/build/flutter_assets/

    Debugger / Main / GDB Debugger

        gdb-multiarch

    Debugger / Shared Libraries

        {absolute build folder}/engine-prefix/src/engine/src/out/linux_debug_arm/so.unstripped
        {absolute sdk folder}/sysroot/lib
        {absolute sdk folder}/toolchain/lib

    Debugger / Shared Libraries / Load shared library symbols automatically [TRUE]  


Set breakpoint at FlutterEngineRun().  

Run the debugger, once breakpoint hits, change to the Debugger Console window, and issue

    set step-mode on

Step into FlutterEngineRun()
