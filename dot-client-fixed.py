solutions = [{
  "managed": False,
  "name": "src/flutter",
  "url": "https://github.com/flutter/engine.git",
  "deps_file": "DEPS",
  "custom_vars": {
    "download_linux_deps": True,
    "download_android_deps": False
  },
  
  # Use custom libcxx repo & commit here since the default one is deleted
  "custom_deps": {
    'src/third_party/libcxx': 'https://llvm.googlesource.com/llvm-project/libcxx@54c3dc7343f40254bdb069699202e6d65eda66a2', 
  },
}]
