#TODO place holder

set(FLUTTER_TARGET_NAME "Wayland")
ExternalProject_Add(wayland_flutter
    GIT_REPOSITORY https://github.com/chinmaygarde/flutter_wayland.git
    GIT_TAG master
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND autoninja -C out
    INSTALL_COMMAND ""
)
add_dependencies(wayland_flutter engine)
