cmake_minimum_required(VERSION 3.15)

project(flutter-glfw VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11" )

add_executable(flutter_glfw FlutterEmbedderGLFW.cc)

############################################################
# GLFW
############################################################
find_path(GLFW_INCLUDE_PATH "glfw3.h"
    /usr/local/Cellar/glfw/3.3/include/GLFW/
    /usr/local/include/include/GLFW/
    /usr/include/GLFW)
include_directories(${GLFW_INCLUDE_PATH})
find_library(GLFW_LIB glfw /usr/local/Cellar/glfw/3.3/lib)
target_link_libraries(flutter_glfw ${GLFW_LIB})

############################################################
# Flutter Engine
############################################################
# This is assuming you've built a local version of the Flutter Engine.  If you
# downloaded yours is from the internet you'll have to change this.
include_directories(${CMAKE_SOURCE_DIR}/../../shell/platform/embedder)
find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../../../out/host_debug_unopt)
target_link_libraries(flutter_glfw ${FLUTTER_LIB} -ldl)

install(TARGETS flutter_glfw RUNTIME DESTINATION bin)

set(CMAKE_SKIP_RPATH TRUE)

set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_VENDOR "JoWi Electronics")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Joel Winarske")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/../../LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_NAME}-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${CPACK_DEBIAN_PACKAGE_ARCHITECTURE})

include(CPack)

# To use this:
# make package
# sudo dpkg -i flutter-glfw-1.0.0-Linux-armhf.deb
