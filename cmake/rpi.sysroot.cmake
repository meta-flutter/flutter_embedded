include(ExternalProject)

find_program(tar REQUIRED)
find_program(wget REQUIRED)

set(SYSROOT ${CMAKE_SOURCE_DIR}/sdk/sysroot)

set(ROOT_ARCHIVE root.tar.xz)
set(ROOT_ARCHIVE_PATH ${CMAKE_BINARY_DIR}/sysroot-prefix/src/${ROOT_ARCHIVE})

ExternalProject_Add(sysroot
    DOWNLOAD_COMMAND wget https://downloads.raspberrypi.org/raspbian/archive/2018-11-15-21:02/${ROOT_ARCHIVE}
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E remove_directory ${SYSROOT}
    BUILD_COMMAND ""
    INSTALL_COMMAND 
      ${CMAKE_COMMAND} -E make_directory ${SYSROOT} && 
      cd ${SYSROOT} &&
      tar -xvf ${ROOT_ARCHIVE_PATH} ./opt/vc/ &&
      tar -xvf ${ROOT_ARCHIVE_PATH} ./lib/ &&
      tar -xvf ${ROOT_ARCHIVE_PATH} ./usr/
)