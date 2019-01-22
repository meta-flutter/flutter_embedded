include(ExternalProject)

find_program(ln REQUIRED)
find_program(tar REQUIRED)
find_program(wget REQUIRED)

set(SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)

set(ROOT_ARCHIVE root.tar.xz)
set(ROOT_ARCHIVE_PATH ${CMAKE_BINARY_DIR}/sysroot-prefix/src/${ROOT_ARCHIVE})

ExternalProject_Add(sysroot
    DOWNLOAD_COMMAND wget -nv https://downloads.raspberrypi.org/raspbian/archive/2018-11-15-21:02/${ROOT_ARCHIVE}
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E remove_directory ${SYSROOT}
    BUILD_COMMAND ""
    INSTALL_COMMAND 
      ${CMAKE_COMMAND} -E make_directory ${SYSROOT} && 
      cd ${SYSROOT} &&
      tar -xvf ${ROOT_ARCHIVE_PATH} ./opt/vc/ > /dev/null &&
      tar -xvf ${ROOT_ARCHIVE_PATH} ./lib/ > /dev/null &&
      tar -xvf ${ROOT_ARCHIVE_PATH} ./usr/ > /dev/null &&
      # dangling symlinks
      cd ./usr/lib/arm-linux-gnueabihf &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libz.so.1.2.8 libdl.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libz.so.1.2.8 libz.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/librt.so.1 librt.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnss_nisplus.so.2 libnss_nisplus.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libdl.so.2 libdl.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnss_files.so.2 libnss_files.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libm.so.6 libm.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libutil.so.1 libutil.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libresolv.so.2 libresolv.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnsl.so.1 libnsl.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libBrokenLocale.so.1 libBrokenLocale.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libthread_db.so.1 libthread_db.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libanl.so.1 libanl.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnss_nis.so.2 libnss_nis.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libmnl.so.0.2.0 libmnl.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libmnl.so.0.2.0 libmnl.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libcidn.so.1 libcidn.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnss_compat.so.2 libnss_compat.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libcrypt.so.1 libcrypt.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libexpat.so.1.6.2 libexpat.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnss_hesiod.so.2 libnss_hesiod.so &&
      ln -f -s ../../../lib/arm-linux-gnueabihf/libnss_dns.so.2 libnss_dns.so &&
      # missing symlinks
      ln -f -s ../../../lib/arm-linux-gnueabihf/libdbus-1.so.3 libdbus-1.so
)