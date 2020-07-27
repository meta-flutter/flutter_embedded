#
# MIT License
#
# Copyright (c) 2018-2020 Joel Winarske
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

include(ExternalProject)

#
# Avoid downloading img file, and the ensuing su mount.
# Useful when you don't have the target available.
#
if(BUILD_PLATFORM_SYSROOT)

    if(BUILD_PLATFORM_SYSROOT_RPI)

        # Shop for Raspbian rootfs releases here: 
        #  https://downloads.raspberrypi.org/raspbian/archive/
        #
        if(NOT ROOTFS_ARCHIVE_VERSION)
            set(ROOTFS_ARCHIVE_VERSION 2020-02-14-13:48)
        endif()

        if(NOT ROOTFS_ARCHIVE_MD5)
            set(ROOTFS_ARCHIVE_MD5 922e717dd1f2968e41c9f7c6b17dda13)
        endif()

        if(NOT ROOTFS_ARCHIVE_BASE_URL)
            set(ROOTFS_ARCHIVE_BASE_URL http://director.downloads.raspberrypi.org/raspbian/archive/)
        endif()

        if(NOT ROOTFS_ARCHIVE_NAME)
            set(ROOTFS_ARCHIVE_NAME root)
        endif()

        if(NOT ROOTFS_ARCHIVE_EXT)
            set(ROOTFS_ARCHIVE_EXT tar.xz)
        endif()

        set(ROOTFS_ARCHIVE_URL ${ROOTFS_ARCHIVE_BASE_URL}${ROOTFS_ARCHIVE_VERSION}/${ROOTFS_ARCHIVE_NAME}.${ROOTFS_ARCHIVE_EXT})
        MESSAGE(STATUS "Rootfs Archive Url ..... ${ROOTFS_ARCHIVE_URL}")

        # limit what is extracted saving time and space
        set(ARCHIVE_FILE_PATH ${CMAKE_BINARY_DIR}/sysroot-prefix/src/${ROOTFS_ARCHIVE_NAME}.${ROOTFS_ARCHIVE_EXT})
        set(ARCHIVE_EXTRACT_CMD
            cd ${TARGET_SYSROOT} &&
            tar -xf ${ARCHIVE_FILE_PATH} ./lib/ > /dev/null &&
            tar -xf ${ARCHIVE_FILE_PATH} ./usr/ > /dev/null &&
            tar -xf ${ARCHIVE_FILE_PATH} ./opt/vc/ > /dev/null
            )

    endif()

    ExternalProject_Add(sysroot
        URL ${ROOTFS_ARCHIVE_URL}
        URL_MD5 ${ROOTFS_ARCHIVE_MD5}
        DOWNLOAD_NO_EXTRACT true
        PATCH_COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET_SYSROOT}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ${ARCHIVE_EXTRACT_CMD}
    )

    set(SYMLINK_FIXUP_SCRIPT ${CMAKE_BINARY_DIR}/symlink_fixups-prefix/src/sysroot-relativelinks.py)
    ExternalProject_Add(symlink_fixups
        URL https://raw.githubusercontent.com/Kukkimonsuta/rpi-buildqt/master/scripts/utils/sysroot-relativelinks.py
        DOWNLOAD_NO_EXTRACT true
        CONFIGURE_COMMAND chmod +x ${SYMLINK_FIXUP_SCRIPT}
        BUILD_COMMAND ${SYMLINK_FIXUP_SCRIPT} ${TARGET_SYSROOT}
        INSTALL_COMMAND ""
    )
    add_dependencies(symlink_fixups sysroot)

#
# rsync sysroot
#
elseif(TARGET_HOSTNAME)

    MESSAGE(STATUS "Syncing sysroot from '${TARGET_HOSTNAME}'")

    set(TARGET_SYSROOT_RSYNC
        COMMAND mkdir -p ${TARGET_SYSROOT} && cd ${TARGET_SYSROOT}
        COMMAND rsync -avz
            --exclude=firmware
            --exclude=modules
            ${TARGET_HOSTNAME}:/lib/ lib/
        COMMAND rsync -avz
            --exclude=lib/chromium-browser/
            --exclude=lib/debug/
            --exclude=lib/firefox/
            --exclude=lib/gcc/
            --exclude=share/doc/
            --exclude=local/${QT_TARGET_FOLDER_NAME}/
            ${TARGET_HOSTNAME}:/usr/ usr/)

    if(BUILD_PLATFORM_RPI)
        set(TARGET_SYSROOT_RSYNC ${TARGET_SYSROOT_RSYNC}
            COMMAND mkdir -p ${TARGET_SYSROOT}/opt
            COMMAND rsync -avz ${TARGET_HOSTNAME}:/opt/vc opt/)
    endif()

    if(NOT TARGET_SYSROOT_DEPS)
        set(TARGET_SYSROOT_DEPS
        ttf-mscorefonts-installer fontconfig upower 
        libjpeg62-turbo-dev libpng-dev libfreetype6-dev 
        libssl-dev libicu-dev libxslt1-dev libdbus-1-dev 
        libfontconfig1-dev libcap-dev libudev-dev libpci-dev 
        libnss3-dev libasound2-dev libbz2-dev libgcrypt20-dev 
        libdrm-dev libcups2-dev libevent-dev libinput-dev 
        libts-dev libmtdev-dev libpcre3-dev libre2-dev 
        libwebp-dev libopus-dev unixodbc-dev libsqlite0-dev 
        libxcursor-dev libxcomposite-dev libxdamage-dev 
        libxrandr-dev libxtst-dev libxss-dev libxkbcommon-dev 
        libdouble-conversion-dev libbluetooth-dev 
        libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev 
        libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev 
        libatspi2.0-dev
        )
    endif()

    if(UPDATE_TARGET)
        find_program(ssh REQUIRED)
        set(SYSROOT_CONFIGURE_COMMAND
            ssh ${TARGET_HOSTNAME} sudo mkdir -p ${QT_TARGET_FOLDER_PATH} &&
            ssh ${TARGET_HOSTNAME} sudo apt-get update &&
            ssh ${TARGET_HOSTNAME} sudo apt-get install ${TARGET_SYSROOT_DEPS} -y &&
            ssh ${TARGET_HOSTNAME} sudo apt-get upgrade -y &&
            ssh ${TARGET_HOSTNAME} sudo apt autoremove -y
            )
        set(SYSROOT_INSTALL_COMMAND 
            COMMAND ssh ${TARGET_HOSTNAME} sudo reboot > /dev/null)
    else()
        set(SYSROOT_CONFIGURE_COMMAND "")
        set(SYSROOT_INSTALL_COMMAND "")
    endif()

    ExternalProject_Add(sysroot
        DOWNLOAD_COMMAND ""
        CONFIGURE_COMMAND ${SYSROOT_CONFIGURE_COMMAND}
        BUILD_COMMAND ${TARGET_SYSROOT_RSYNC}
        INSTALL_COMMAND ""
    )

    find_program(python REQUIRED)
    find_program(chmod REQUIRED)
    set(SYMLINK_FIXUP_SCRIPT ${CMAKE_BINARY_DIR}/symlink_fixups-prefix/src/sysroot-relativelinks.py)
    ExternalProject_Add(symlink_fixups
        URL https://raw.githubusercontent.com/Kukkimonsuta/rpi-buildqt/master/scripts/utils/sysroot-relativelinks.py
        DOWNLOAD_NO_EXTRACT true
        CONFIGURE_COMMAND chmod +x ${SYMLINK_FIXUP_SCRIPT}
        BUILD_COMMAND ${SYMLINK_FIXUP_SCRIPT} ${TARGET_SYSROOT}
        INSTALL_COMMAND ""
    )
    add_dependencies(symlink_fixups sysroot)

endif()


MESSAGE(STATUS "Target Sysroot ......... ${TARGET_SYSROOT}")
