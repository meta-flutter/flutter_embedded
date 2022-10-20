# flutter engine binaries for armv7, aarch64

This repo contains flutter engine binaries (in the https://github.com/ardera/flutter-engine-binaries-for-arm filesystem layout) for armv7 and aarch64.
The binaries come in 2 variants: generic, and tuned for the Pi 4 CPU.

# 📦 Downloads

### **See [Releases](https://github.com/ardera/flutter_embedded/releases).**

# 🛠️ Build Config and Compiler Invocation
## Build Config
The engine build is configured with:
```
$ ./src/flutter/tools/gn \
  --runtime-mode <debug / profile / release> \
  --target-os linux \
  --linux-cpu <arm / arm64> \
  --arm-float-abi hard \
  --target-dir build \
  --embedder-for-target \
  --disable-desktop-embeddings \
  --no-build-glfw-shell \
  --no-build-embedder-examples \
  --no-goma
```

`--arm-float-abi hard` is only specified when building for armv7.

After that, the following args are added to the `args.gn` file for the generic flavor:
```
arm_cpu = "generic"
arm_tune = "generic"
```

When tuning for pi 4, the following args are specified instead:
```
arm_cpu = "cortex-a72+nocrypto"
arm_tune = "cortex-a72"
```

For both armv7 and aarch64, the engine is built against the sysroot provided by the engine build scripts, which is some debian sid sysroot from 2020.
(See https://github.com/flutter/buildroot/blob/master/build/linux/sysroot_scripts/install-sysroot.py)

## Compiler Invocation
This will result in the clang compiler being invoked with the following args:

| artifact        | compiler arguments                                                           |
| --------------- | ---------------------------------------------------------------------------- |
| armv7-generic   | `--target=armv7-linux-gnueabihf -mcpu=generic             -mtune=generic`    |
| pi4             | `--target=armv7-linux-gnueabihf -mcpu=cortex-a72+nocrypto -mtune=cortex-a72` |
| aarch64-generic | `--target=aarch64-linux-gnu     -mcpu=generic             -mtune=generic`    |
| pi4-64          | `--target=aarch64-linux-gnu     -mcpu=cortex-a72+nocrypto -mtune=cortex-a72` |
