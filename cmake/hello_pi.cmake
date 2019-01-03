cmake_minimum_required(VERSION 3.11)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "MinSizeRel" CACHE STRING "Choose the type of build, options are: Debug, Release, or MinSizeRel." FORCE)
    message(STATUS "CMAKE_BUILD_TYPE not set, defaulting to MinSizeRel.")
endif()

project(hello_pi LANGUAGES C)

message(STATUS "Generator .............. ${CMAKE_GENERATOR}")
message(STATUS "Build Type ............. ${CMAKE_BUILD_TYPE}")


include_directories(
    ${SDKSTAGE}/opt/vc/include
    ${SDKSTAGE}/opt/vc/include/interface/vcos/pthreads
    ${SDKSTAGE}/opt/vc/include/interface/vmcs_host/linux
    ${SDKSTAGE}/opt/vc/src/hello_pi/libs/ilclient
    ${SDKSTAGE}/opt/vc/src/hello_pi/libs/vgfont
    ${SDKSTAGE}/usr/include/freetype2
    )

link_directories(
    ${SDKSTAGE}/opt/vc/lib
    )

add_definitions(
    -DSTANDALONE -D_LINUX -DTARGET_POSIX 
    -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS 
    -fPIC -DPIC -D_REENTRANT 
    -D_LARGEFILE64_SOURCE  -D_FILE_OFFSET_BITS=64 
    -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST 
    -DUSE_VCHIQ_ARM
    -DHAVE_LIBOPENMAX=2
    -DUSE_EXTERNAL_OMX -DOMX -DOMX_SKIP64BIT
    )

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -U_FORTIFY_SOURCE -Wall -g -ftree-vectorize -pipe")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvcos -lvchiq_arm -lpthread")

add_library(ilclient STATIC libs/ilclient/ilclient.c libs/ilclient/ilcore.c)
add_library(vgfont STATIC libs/vgfont/font.c libs/vgfont/graphics.c libs/vgfont/vgft.c)

add_executable(hello_audio hello_audio/audio.c hello_audio/sinewave.c)
target_link_libraries(hello_audio ilclient)

add_dependencies(hello_audio ilclient)

add_executable(hello_dispmanx hello_dispmanx/dispmanx.c)

add_executable(hello_encode hello_encode/encode.c)
target_link_libraries(hello_encode ilclient)
add_dependencies(hello_encode ilclient)

set(shader_src
    hello_fft/hex/shader_256.hex hello_fft/hex/shader_512.hex
    hello_fft/hex/shader_1k.hex hello_fft/hex/shader_2k.hex 
    hello_fft/hex/shader_4k.hex hello_fft/hex/shader_8k.hex
    hello_fft/hex/shader_16k.hex hello_fft/hex/shader_32k.hex
    hello_fft/hex/shader_64k.hex hello_fft/hex/shader_128k.hex
    hello_fft/hex/shader_256k.hex hello_fft/hex/shader_512k.hex
    hello_fft/hex/shader_1024k.hex hello_fft/hex/shader_2048k.hex
    hello_fft/hex/shader_4096k.hex
)
set(hello_fft_src
    hello_fft/mailbox.c hello_fft/gpu_fft.c hello_fft/gpu_fft_base.c 
    hello_fft/gpu_fft_twiddles.c hello_fft/gpu_fft_shaders.c
)
add_executable(hello_fft ${shader_src} ${hello_fft_src} hello_fft/hello_fft.c)
target_link_libraries(hello_fft m dl)

add_executable(hello_fft_2d ${shader_src} hello_fft/hex/shader_trans.hex ${hello_fft_src} hello_fft/hello_fft_2d.c hello_fft/gpu_fft_trans.c)
target_link_libraries(hello_fft_2d m dl)

add_executable(hello_font hello_font/main.c)
target_link_libraries(hello_font vgfont freetype z)
add_dependencies(hello_font vgfont)

add_executable(hello_jpeg hello_jpeg/jpeg.c)
target_link_libraries(hello_jpeg ilclient)
add_dependencies(hello_jpeg ilclient)

add_executable(hello_mmal_encode hello_mmal_encode/mmal_encode.c)
target_link_libraries(hello_mmal_encode mmal mmal_core mmal_components mmal_util mmal_vc_client -Wl,--no-as-needed ilclient)
add_dependencies(hello_mmal_encode ilclient)

add_executable(hello_teapot hello_teapot/triangle.c hello_teapot/video.c hello_teapot/models.c)
target_link_libraries(hello_teapot ilclient m)
add_dependencies(hello_mmal_encode ilclient)

add_executable(hello_tiger hello_tiger/main.c hello_tiger/tiger.c)
target_compile_definitions(hello_tiger PRIVATE -D__RASPBERRYPI__)

add_executable(hello_triangle hello_triangle/triangle.c)
target_link_libraries(hello_triangle m)

add_executable(hello_triangle2 hello_triangle2/triangle2.c)

add_executable(hello_video hello_video/video.c)
target_link_libraries(hello_video ilclient)
add_dependencies(hello_video ilclient)

add_executable(hello_videocube hello_videocube/triangle.c hello_videocube/video.c)
target_link_libraries(hello_videocube ilclient m)
add_dependencies(hello_videocube ilclient)

add_executable(hello_world hello_world/world.c)


install(TARGETS hello_audio hello_dispmanx hello_encode 
    hello_fft hello_fft_2d hello_font hello_jpeg hello_mmal_encode 
    hello_teapot hello_tiger hello_triangle hello_triangle2
    hello_video hello_videocube hello_world
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib/static
    )