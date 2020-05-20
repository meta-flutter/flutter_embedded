# flutter_embedded

This repo is focused on building alternative Flutter Shells for Embedded Linux.

# Project Status

**[Note: armv6 is not supported by Google](https://github.com/flutter/flutter/issues/22380#issuecomment-629291519)**

To generate DEB packages issue `make package` from your build folder.  If you built with default flags you will see these in your build directory:

    libflutter_engine-debug-dev-1.0.0-Linux-armhf.deb
    flutter-glfw-1.0.0-Linux-armhf.deb

You can now select the desired channel, the default is stable.  Use this `cmake .. -DCHANNEL=beta` to swtich channels.
Master, dev, beta, and stable have all been tested building armv7 image for Raspberry Pi..

flutter-pi has been added as an optional shell to build.

No external toolchain is required.  I'm using the repo CIPD sync artifact - Clang Toolchain.

The default build configuration (provided a properly configured sysroot), will cross-compile armv7a flutter engine, and selected shells.

If your are using a sysroot different than that included as default, you will need to override a few variables.  See examples below.

Yocto Layer to build Engine, Wayland shell, and Gallery App can be found here:  [meta-flutter](https://github.com/jwinarske/meta-flutter)


## Pre-requisites to build Flutter Engine and flutter_glfw

1. CMake 3.15 or greater

2. Sysroot compatible with the Clang runtime flavors

3. Linux system to build on


  *Notes:*
  *LLVM runtime libraries do not support soft floating point. Google does not support armv6 in Dart.  It's fairly straight forward to patch and build for armv6, but you will hit problems in Dart.*


## Build engine and flutter_glfw (stable channel) example shell for RPI

    git clone https://github.com/jwinarske/flutter_embedded
    cd flutter_embedded
    mkdir build && cd build
    cmake ..
    make package -j8

To enable build spew:

    make -j8 VERBOSE=1

*Note: Your build folder can be wherever you want*

## Build engine (stable channel) and flutter-pi for RPI (mounted SD card)

    git clone https://github.com/jwinarske/flutter_embedded
    cd flutter_embedded
    mkdir build && cd build
    cmake .. -DBUILD_PLATFORM_SYSROOT=OFF -DTARGET_SYSROOT=/media/joel/rootfs -DBUILD_FLUTTER_PI=ON -DBUILD_GLFW_FLUTTER=OFF
    make package -j8

*Note*: this requires the following pacakges installed on your target: 

    sudo apt install libgl1-mesa-dev libgles2-mesa-dev ibegl-mesa0 libdrm-dev libgbm-dev gpiod libgpiod-dev

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


## Build gtk3+ dependent engine (stable channel) for HOST

    git clone https://github.com/jwinarske/flutter_embedded
    cd flutter_embedded
    mkdir build && cd build
    cmake .. -DENGINE_DISABLE_DESKTOP=OFF -DENGINE_EMBEDDER_FOR_TARGET=OFF -DBUILD_FLUTTER_RPI=OFF -DBUILD_PLATFORM_SYSROOT=OFF -DTARGET_SYSROOT=/usr -DTARGET_ARCH=x64 -DBUILD_PLATFORM_SYSROOT_RPI=OFF
    make package -j8

To switch to building flutter_glfw (TARGET) be sure to undefine the variables set prior.

    cmake .. -UENGINE_DISABLE_DESKTOP -UENGINE_EMBEDDER_FOR_TARGET -DBUILD_FLUTTER_RPI=ON -DBUILD_PLATFORM_SYSROOT=ON -UTARGET_SYSROOT -UTARGET_ARCH -DBUILD_PLATFORM_SYSROOT_RPI=ON
    make package -j8

## Build gtk3+ dependent engine (stable channel) for TARGET

    git clone https://github.com/jwinarske/flutter_embedded
    cd flutter_embedded
    mkdir build && cd build
    cmake .. -DENGINE_DISABLE_DESKTOP=OFF -DENGINE_EMBEDDER_FOR_TARGET=OFF
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

### sysroot - Default

    The target sysroot is created from this rootfs archive:
        https://downloads.raspberrypi.org/raspbian/archive/2020-02-14-13:48/root.tar.xz

    The resultant build artifacts are compatible with any 2020-02-14 Raspbian image.  If you need a different rootfs version, you will need to update the wget command in flutter_embedded/cmake/rpi.sysroot.cmake.

### sysroot - Override / create from Raspbian img file

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

### Flutter Engine Default Font for Linux

    Arial.ttf

Check your target using

    fc-match Arial

It should return    

    Arial.ttf: "Arial" "Normal"

If the Arial font is not present, you get this fatal error when attemping to launch Flutter

    LOG: /home/joel/git/flutter_embedded/build/rpi_flutter-prefix/src/rpi_flutter/flutter/main.cc:66: Display Size: 800 x 480
    flutter: Observatory listening on http://127.0.0.1:34949/
    [ERROR:flutter/third_party/txt/src/minikin/FontFamily.cpp(184)] Could not get cmap table size!

### Install Arial Font

    sudo apt-get install ttf-mscorefonts-installer
    sudo fc-cache

### Push Native Flutter build artifacts to Target

    scp -r {build folder}/target/* pi@raspberrypi.local:/home/pi

### Enable Linux as a Platform in your Flutter Repo

    cd <flutter git root (not this repo)>
    git apply <flutter_embedded repo>/cmake/flutter_platform.patch

Note that that Flutter repo does not have TargetPlatform.linux as part of Material design.  You have to add it by hand, or override debugDefaultTargetPlatformOverride and set it to a supported one...  There are a couple of cases that need a unique implementation for Linux.  Vibrate, etc.

Apply this changelist, if not present.  https://github.com/flutter/flutter/pull/24932/files

When adding in Linux support to the Dart code, start by adding "case TargetPlatform.linux:" to all switch cases found via

    cd {flutter repo}
    grep -r "case TargetPlatform.android:"

### Build your Flutter Application

    cd {flutter app project folder}
    flutter build bundle

*Note: You either need to override TargetPlatform prior to running the app*

## Tested Flutter Examples

Tested apps post Flutter Dart "linux" platfrom add
    
    flutter/examples/catalog * Generates rendered text: "Instead run", "flutter run lib/xxx.dart"
    flutter/examples/flutter_gallery * key test case for platform
    flutter/examples/flutter_view
    flutter/examples/hello_world
    flutter/examples/layers * Generates rendered text: "Instead run", "flutter run lib/xxx.dart"
    flutter/examples/platform_channel
    flutter/examples/platform_view * Android view not impl.. no-op btn
    flutter/examples/stocks
    flutter-desktop-embedding/example/flutter_app

### Push built Flutter Application to Target

    scp -r {flutter app root }/build/* pi@raspberrypi.local:/home/pi

### Execute Flutter on Target
Presuming you built your Flutter app, and pushed the build folder to your target, you can run it with this

    TSLIB_CONFFILE=/etc/ts.conf TSLIB_PLUGINDIR=/home/pi/lib/ts TSLIB_CALIBFILE=/etc/pointercal LD_LIBRARY_PATH=./lib ./bin/flutter ./build/flutter_assets/

*If your touch screen is not auto-detected correctly, specify the /dev/input/event[n] using the environmental variable TSLIB_TSDEVICE*

This can be run from a SSH session, or directly on the device.  You should see output like this, prior to the app being rendered

    LOG: /home/joel/git/flutter_embedded/build/rpi_flutter-prefix/src/rpi_flutter/flutter/main.cc:66: Display Size: 800 x 480
    flutter: Observatory listening on http://127.0.0.1:34949/

*Note: If you get unknown platform exception, you either need to override debugDefaultTargetPlatformOverride, or 
"Enable Linux as a Platform in your Flutter Repo"*

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
