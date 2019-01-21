#
# MIT License
#
# Copyright (c) 2018 Joel Winarske
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

cmake_minimum_required(VERSION 3.11)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "MinSizeRel" CACHE STRING "Choose the type of build, options are: Debug, Release, or MinSizeRel." FORCE)
    message(STATUS "CMAKE_BUILD_TYPE not set, defaulting to MinSizeRel.")
endif()

project(hello_pi LANGUAGES C)

message(STATUS "Generator .............. ${CMAKE_GENERATOR}")
message(STATUS "Build Type ............. ${CMAKE_BUILD_TYPE}")


include_directories(
    ${CMAKE_SYSROOT}/opt/vc/include
    ${CMAKE_SYSROOT}/opt/vc/include/interface/vcos/pthreads
    ${CMAKE_SYSROOT}/opt/vc/include/interface/vmcs_host/linux
    ${CMAKE_SYSROOT}/opt/vc/src/hello_pi/libs/ilclient
    ${CMAKE_SYSROOT}/opt/vc/src/hello_pi/libs/vgfont
    ${CMAKE_SYSROOT}/usr/include/freetype2)

link_directories(
    ${CMAKE_SYSROOT}/opt/vc/lib)

add_definitions(
    -DSTANDALONE -D_LINUX -DTARGET_POSIX -D_REENTRANT 
    -D_LARGEFILE64_SOURCE  -D_FILE_OFFSET_BITS=64 
    -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST 
    -fPIC -DPIC -DUSE_VCHIQ_ARM -DHAVE_LIBOPENMAX=2
    -DUSE_EXTERNAL_OMX -DOMX -DOMX_SKIP64BIT)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -U_FORTIFY_SOURCE -Wall -g -ftree-vectorize -pipe -Wno-deprecated-declarations")

add_library(ilclient STATIC libs/ilclient/ilclient.c libs/ilclient/ilcore.c)
add_library(vgfont STATIC libs/vgfont/font.c libs/vgfont/graphics.c libs/vgfont/vgft.c)

add_executable(hello_audio hello_audio/audio.c hello_audio/sinewave.c)
target_link_libraries(hello_audio ilclient)

add_dependencies(hello_audio ilclient)
target_link_libraries(hello_audio openmaxil bcm_host vcos pthread)

add_executable(hello_dispmanx hello_dispmanx/dispmanx.c)
target_link_libraries(hello_dispmanx bcm_host)

add_executable(hello_encode hello_encode/encode.c)
target_link_libraries(hello_encode ilclient openmaxil bcm_host vcos vchiq_arm pthread)
add_dependencies(hello_encode ilclient)

set(hello_fft_src
    hello_fft/mailbox.c hello_fft/gpu_fft.c hello_fft/gpu_fft_base.c 
    hello_fft/gpu_fft_twiddles.c hello_fft/gpu_fft_shaders.c)

add_executable(hello_fft ${hello_fft_src} hello_fft/hello_fft.c)
target_link_libraries(hello_fft m dl)

add_executable(hello_fft_2d ${hello_fft_src} hello_fft/hello_fft_2d.c hello_fft/gpu_fft_trans.c)
target_link_libraries(hello_fft_2d m dl)

add_executable(hello_font hello_font/main.c)
target_link_libraries(hello_font vgfont freetype z brcmGLESv2 brcmEGL openmaxil
    bcm_host vcos vchiq_arm pthread brcmEGL bcm_host vcos pthread)
add_dependencies(hello_font vgfont)

add_executable(hello_jpeg hello_jpeg/jpeg.c)
target_link_libraries(hello_jpeg ilclient brcmGLESv2 brcmEGL openmaxil bcm_host vcos vchiq_arm pthread)
add_dependencies(hello_jpeg ilclient)

add_executable(hello_mmal_encode hello_mmal_encode/mmal_encode.c)
target_link_libraries(hello_mmal_encode mmal mmal_core mmal_components mmal_util mmal_vc_client -Wl,--no-as-needed ilclient bcm_host vcos pthread)
add_dependencies(hello_mmal_encode ilclient)

add_executable(hello_teapot hello_teapot/triangle.c hello_teapot/video.c hello_teapot/models.c)
target_link_libraries(hello_teapot ilclient m brcmGLESv2 brcmEGL openmaxil bcm_host vcos pthread)
add_dependencies(hello_mmal_encode ilclient)

add_executable(hello_tiger hello_tiger/main.c hello_tiger/tiger.c)
target_link_libraries(hello_tiger brcmGLESv2 brcmEGL openmaxil bcm_host vcos vchiq_arm pthread)
target_compile_definitions(hello_tiger PRIVATE -D__RASPBERRYPI__)

add_executable(hello_triangle hello_triangle/triangle.c)
target_link_libraries(hello_triangle m brcmGLESv2 brcmEGL bcm_host)

add_executable(hello_triangle2 hello_triangle2/triangle2.c)
target_link_libraries(hello_triangle2 brcmGLESv2 brcmEGL bcm_host)

add_executable(hello_video hello_video/video.c)
target_link_libraries(hello_video ilclient openmaxil bcm_host vcos pthread)
add_dependencies(hello_video ilclient)

add_executable(hello_videocube hello_videocube/triangle.c hello_videocube/video.c)
target_link_libraries(hello_videocube ilclient m brcmGLESv2 brcmEGL openmaxil bcm_host vcos pthread)
add_dependencies(hello_videocube ilclient)

add_executable(hello_world hello_world/world.c)


install(TARGETS 

    hello_audio
    hello_dispmanx
    hello_encode 
    hello_fft
    hello_fft_2d
    hello_font
    hello_jpeg
    hello_mmal_encode 
    hello_teapot
    hello_tiger
    hello_triangle
    hello_triangle2
    hello_video
    hello_videocube
    hello_world

    RUNTIME DESTINATION bin)

install(FILES
    hello_font/Vera.ttf
    hello_triangle/Djenne_128_128.raw
    hello_triangle/Gaudi_128_128.raw
    hello_triangle/Lucca_128_128.raw
    hello_video/test.h264
    
    DESTINATION bin)