
if(LLVM_CONFIG_PATH)
    message(STATUS "llvm-config ............ ${LLVM_CONFIG_PATH}")
    set(CONFIG_COMMAND ${LLVM_CONFIG_PATH}
        "--cflags"
        "--cxxflags"
        "--ldflags")
    execute_process(
        COMMAND ${CONFIG_COMMAND}
        RESULT_VARIABLE HAD_ERROR
        OUTPUT_VARIABLE CONFIG_OUTPUT
    )
    if(NOT HAD_ERROR)
        string(REGEX REPLACE
        "[ \t]*[\r\n]+[ \t]*" ";"
        CONFIG_OUTPUT ${CONFIG_OUTPUT})
    else()
        string(REPLACE ";" " " CONFIG_COMMAND_STR "${CONFIG_COMMAND}")
        message(STATUS "${CONFIG_COMMAND_STR}")
        message(FATAL_ERROR "llvm-config failed with status ${HAD_ERROR}")
    endif()

    list(GET CONFIG_OUTPUT 0 __CFLAGS)
    list(GET CONFIG_OUTPUT 1 __CXXFLAGS)
    list(GET CONFIG_OUTPUT 2 __LDFLAGS)

    set(LLVM_CFLAGS ${__CFLAGS} CACHE PATH "llvm c flags")
    set(LLVM_CXXFLAGS ${__CXXFLAGS} CACHE PATH "llvm cxx flags")
    set(LLVM_LDFLAGS ${__LDFLAGS} CACHE PATH "llvm linker flags")
else()
    message(WARNING "UNSUPPORTED CONFIGURATION DETECTED: "
                    "llvm-config not found and LLVM_CONFIG_PATH not defined.\n"
                    "Reconfigure with -DLLVM_CONFIG_PATH=path/to/llvm-config.")
    return()
endif()
