# flutter_embedded

This repo is currently about build automation for Tip of the Tree Clang, Binutils, and Flutter Engine artifacts.  The useage target is for an embedded system.

# Motivation
See if Embedded Flutter is a compeling alternative to Chromium ContentShell+JS+CSS, and QT.

Areas of interest are memory footprint, stack latency, and where does it fit in the UI Framework landscape.

I can build a ContentShell browser that with the smallest of pages, only has a 15MB system heap footprint.  As the application complexity increases, the memory usage goes up well over the 100MB mark.  This is too much for an embeded device.

In regards to latency, my test case will be CAN bus signal from an Automotive ODBC-II connector, rendering a gauge.


# Project Status
Currently there are patches required for this build to run end-to-end, which affect the LLVM projects, and Flutter Engine.  After I have the patch logic implemented, I will implement a Travis-ci project.

With proper patches in place, the default build configuration (provided a proper sysroot), will generate bits that execute on a Raspberry Pi.

Work Items
    
    1. Memory Profiling and optimization.  With Debug engine running a simple app on the PI, it's allocating around 150MB, with 12 threads.
    2. Platform Channel handler.  This will allow Dart to call C/C++ code.  Think CAN bus, I2C, SPI, RS-232, RS-485, MIDI, Audio, Espresso Machine I/O, etc.
    3. Support all 4 machine architectures to build on Linux.  Currently only ARM has been tested.
    4. Depending on demand and use cases, add support for building on Mac and Windows (although it may already work)...

Planned Targets in no particular order (I can be persuaded with money to support specific targets)

    Raspberry Pi - Standalone
    DragonBoard 410c - Standalone/Yocto meta layer
    Ultra96 - Standalone/Yocto meta layer
    SabreLite - Standalone/Yocto meta layer
    Intel Target - TBD

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

Note: Your build folder can be wherever you want...

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

    cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=~/Android/Sdk/ndk-bundle/build/cmake/android.toolchain.cmake -DANDROID_ABI=armeabi-v7a -DANDROID_PLATFORM=17
    autoninja
    cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=~/Android/Sdk/ndk-bundle/build/cmake/android.toolchain.cmake -DENGINE_ENABLE_VULCAN=on -DANDROID_ABI=x86_64
    autoninja
    cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=~/Android/Sdk/ndk-bundle/build/cmake/android.toolchain.cmake -DENGINE_ENABLE_VULCAN=off -DANDROID_ABI=armeabi-v7a
    autoninja

# Raspberry Pi

To generate target binaries for a Raspberry Pi, you need a valid sysroot, prior to building

### sysroot
Download Raspbian Lite image from Raspbian Image Download Page

    https://downloads.raspberrypi.org/raspbian_lite_latest


Extract the archive, which will give you a .img file. If on Ubuntu Bionic, double click the img file. It will auto-mount the partitions present. You're interested in the rootfs partition. From terminal or nautilus, copy the /lib, /opt, and /usr directories from the rootfs mount. Copy these to the default sysroot folder

    cd /media/$USER/rootfs
    cp -r lib {flutter_embedded git clone root}/sdk/sysroot
    cp -r opt {flutter_embedded git clone root}/sdk/sysroot
    cp -r usr {flutter_embedded git clone root}/sdk/sysroot
    
### sdk folder

The sdk folder will look like this after the toolchain has built properly

    ./sdk
    |-- sysroot
    |   |-- lib
    |   |-- opt
    |   `-- usr
    `-- toolchain
        |-- arm-linux-gnueabihf
        |-- bin
        |-- include
        |-- lib
        |-- libexec
        `-- share

### Default Font Requirement

    /usr/share/fonts/Arial.ttf

If the above font is not present, you will see this error when attemping to launch Flutter

    LOG: /home/joel/git/flutter_embedded/build/rpi_flutter-prefix/src/rpi_flutter/flutter/main.cc:66: Display Size: 800 x 480
    flutter: Observatory listening on http://127.0.0.1:34949/
    [ERROR:flutter/third_party/txt/src/minikin/FontFamily.cpp(184)] Could not get cmap table size!

### Push Native Flutter build artifacts to Target

    scp -r {build folder}/target/* pi@raspberrypi.local:/home/pi

### Build your Flutter Application

    cd {flutter app project folder}
    flutter build bundle

### Push built Flutter Application to Target

    scp -r {flutter app root }/build/* pi@raspberrypi.local:/home/pi

### Execute Flutter on Target
Presuming you built your Flutter app, and pushed the build folder to your target, you can run it with this

    TSLIB_CONFFILE=/etc/ts.conf TSLIB_PLUGINDIR=/home/pi/lib/ts TSLIB_CALIBFILE=/etc/pointercal LD_LIBRARY_PATH=./lib ./bin/flutter ./build/flutter_assets/

*If your touch screen is not auto-detected correctly, specify the /dev/input/event[n] using the environmental variable TSLIB_TSDEVICE*

This can be run from a SSH session, or directly on the device.  You should see output like this, prior to the app being rendered

    LOG: /home/joel/git/flutter_embedded/build/rpi_flutter-prefix/src/rpi_flutter/flutter/main.cc:66: Display Size: 800 x 480
    flutter: Observatory listening on http://127.0.0.1:34949/

### Raspberry Pi 7" Touch Display

Verify your touch display is working correctly on your Raspberry Pi using evtest

    sudo apt-get install evtest

Running it, you should see something like

    $ evtest
    No device specified, trying to scan all of /dev/input/event*
    Not running as root, no devices may be available.
    Available devices:
    /dev/input/event0:	HID 0c45:7403
    /dev/input/event1:	HID 0c45:7403
    /dev/input/event2:	FT5406 memory based driver
    Select the device event number [0-2]:

The touch device in this case, is /dev/input/event2.  Selecting 2 will enable touch data to print to the console.

### Touch Panel Calibration

    sudo LD_LIBRARY_PATH=./lib TSLIB_CONFFILE=/etc/ts.conf TSLIB_PLUGINDIR=/home/pi/lib/ts TSLIB_CALIBFILE=/etc/pointercal ./bin/ts_calibrate

## Touch Panel Applications

    sudo LD_LIBRARY_PATH=./lib TSLIB_CONFFILE=/etc/ts.conf TSLIB_PLUGINDIR=/home/pi/lib/ts TSLIB_CALIBFILE=/etc/pointercal ./bin/ts_test
    sudo LD_LIBRARY_PATH=./lib TSLIB_CONFFILE=/etc/ts.conf TSLIB_PLUGINDIR=/home/pi/lib/ts TSLIB_CALIBFILE=/etc/pointercal ./bin/ts_print

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

https://github.com/kergoth/tslib

http://geomodule.com/sw-eng-notes/2017/03/25/raspberry-pi-debugging-with-gdb-command-line/