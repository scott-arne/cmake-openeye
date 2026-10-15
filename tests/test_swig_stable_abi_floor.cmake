# Verify openeye_add_swig_module() refuses SWIG older than 4.4.1 for
# stable-ABI builds and still accepts it for version-specific builds.
#
# SWIG 4.4.0 picks Python 3.13-only C API calls from the header version
# instead of Py_LIMITED_API, so its stable-ABI wrapper does not compile against
# Python 3.13+ headers. A fake swig executable reports whichever version a case
# needs. The check runs before anything compiles, so the driver project needs
# no compiler and no OpenEye SDK; later configure errors in the passing cases
# are expected and ignored.

if(WIN32)
    message(STATUS "SKIP: the fake swig executable is a POSIX shell script")
    return()
endif()

if(NOT DRIVER_DIR)
    message(FATAL_ERROR "DRIVER_DIR must be provided")
endif()
if(NOT CMAKE_OPENEYE_DIR)
    message(FATAL_ERROR "CMAKE_OPENEYE_DIR must be provided")
endif()

file(REMOVE_RECURSE "${DRIVER_DIR}")
file(MAKE_DIRECTORY "${DRIVER_DIR}/swiglib" "${DRIVER_DIR}/project")
file(WRITE "${DRIVER_DIR}/swiglib/swig.swg" "")

file(WRITE "${DRIVER_DIR}/project/CMakeLists.txt"
"cmake_minimum_required(VERSION 3.26)
project(swig_floor_driver LANGUAGES NONE)
include(\"${CMAKE_OPENEYE_DIR}/OpenEyeSWIG.cmake\")
openeye_add_swig_module(
    NAME floor
    SWIG_FILE floor.i
    LINK_LIBS floor_core
    PYTHON_OUTPUT_DIR \"\${CMAKE_CURRENT_BINARY_DIR}/py\"
    STABLE_ABI \${FLOOR_STABLE_ABI}
)
")

# Configures the driver against a fake swig reporting <version> and returns
# the combined output with whitespace collapsed, because CMake wraps long
# message() text across lines.
function(_configure_case name version stable_abi out_var)
    set(_bin "${DRIVER_DIR}/swig-${name}")
    file(MAKE_DIRECTORY "${_bin}")
    file(WRITE "${_bin}/swig"
"#!/bin/sh
case \"$1\" in
    -version) printf '\\nSWIG Version ${version}\\n' ;;
    -swiglib) echo '${DRIVER_DIR}/swiglib' ;;
    *) exit 1 ;;
esac
")
    file(CHMOD "${_bin}/swig" PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE)

    set(_generator_args "")
    if(DRIVER_GENERATOR)
        set(_generator_args -G "${DRIVER_GENERATOR}")
    endif()
    execute_process(
        COMMAND "${CMAKE_COMMAND}" ${_generator_args}
            -S "${DRIVER_DIR}/project"
            -B "${DRIVER_DIR}/build-${name}"
            "-DSWIG_EXECUTABLE=${_bin}/swig"
            "-DFLOOR_STABLE_ABI=${stable_abi}"
        OUTPUT_VARIABLE _out
        ERROR_VARIABLE _err
    )
    string(REGEX REPLACE "[ \t\r\n]+" " " _all "${_out} ${_err}")
    set(${out_var} "${_all}" PARENT_SCOPE)
endfunction()

set(_floor_text "requires SWIG 4.4.1 or newer")

_configure_case(stable_440 4.4.0 ON _out)
if(NOT _out MATCHES "${_floor_text}")
    message(FATAL_ERROR "FAIL: STABLE_ABI=ON accepted SWIG 4.4.0. Output: ${_out}")
endif()
if(NOT _out MATCHES "Found SWIG 4\\.4\\.0 at")
    message(FATAL_ERROR "FAIL: the floor message does not name the rejected version. Output: ${_out}")
endif()

# Accepted versions must reach the status line printed after the SWIG lookup,
# which proves the configure got past the floor rather than failing elsewhere.
_configure_case(stable_441 4.4.1 ON _out)
if(_out MATCHES "${_floor_text}" OR NOT _out MATCHES "OpenEyeSWIG: using SWIG 4\\.4\\.1")
    message(FATAL_ERROR "FAIL: STABLE_ABI=ON did not accept SWIG 4.4.1. Output: ${_out}")
endif()

_configure_case(versioned_440 4.4.0 OFF _out)
if(_out MATCHES "${_floor_text}" OR NOT _out MATCHES "OpenEyeSWIG: using SWIG 4\\.4\\.0")
    message(FATAL_ERROR "FAIL: STABLE_ABI=OFF did not accept SWIG 4.4.0. Output: ${_out}")
endif()

message(STATUS "PASS: SWIG stable-ABI floor enforced")
