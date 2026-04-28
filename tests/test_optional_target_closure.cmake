# Verify optional imported targets do not publish dangling OpenEye:: deps.
#
# This creates a partial fake SDK that contains the required foundation
# libraries plus one high-level optional library whose dependencies are absent.
# FindOpenEye should omit that optional target rather than creating an imported
# target with INTERFACE_LINK_LIBRARIES entries naming non-existent OpenEye::
# targets.

if(NOT DRIVER_DIR)
    message(FATAL_ERROR "DRIVER_DIR must be provided")
endif()

set(_driver_dir "${DRIVER_DIR}")
set(_sdk_dir "${_driver_dir}/fake-sdk")
set(_project_dir "${_driver_dir}/project")
set(_build_dir "${_driver_dir}/build")

file(REMOVE_RECURSE "${_driver_dir}")
file(MAKE_DIRECTORY "${_sdk_dir}/include/openeye" "${_sdk_dir}/lib" "${_project_dir}")

file(WRITE "${_sdk_dir}/include/openeye/openeye.h" "#define OEToolkitsRelease \"2025.2.1\"\n")

foreach(_lib IN ITEMS oechem oesystem oeplatform oemath oesitehopper)
    file(WRITE "${_sdk_dir}/lib/lib${_lib}.a" "")
endforeach()

file(WRITE "${_project_dir}/CMakeLists.txt" [[
cmake_minimum_required(VERSION 3.16)
project(optional_target_closure LANGUAGES C)

list(PREPEND CMAKE_MODULE_PATH "${TEST_ROOT}")
find_package(OpenEye REQUIRED)

# Imported targets (from find_package(OpenEye)) live in the directory's
# IMPORTED_TARGETS property, not in any GLOBAL property.
get_property(_targets DIRECTORY PROPERTY IMPORTED_TARGETS)
set(_found_any_openeye FALSE)
foreach(_target IN LISTS _targets)
    if(NOT _target MATCHES "^OpenEye::")
        continue()
    endif()
    set(_found_any_openeye TRUE)
    get_target_property(_links "${_target}" INTERFACE_LINK_LIBRARIES)
    if(NOT _links)
        continue()
    endif()
    foreach(_link IN LISTS _links)
        if(_link MATCHES "^OpenEye::" AND NOT TARGET "${_link}")
            message(FATAL_ERROR "FAIL: ${_target} references missing target ${_link}")
        endif()
    endforeach()
endforeach()

# Guard against the loop silently iterating an empty list (the prior bug).
if(NOT _found_any_openeye)
    message(FATAL_ERROR "FAIL: no OpenEye:: imported targets were discovered via DIRECTORY PROPERTY IMPORTED_TARGETS; the closure check did not actually run")
endif()

if(TARGET OpenEye::OESiteHopper)
    message(FATAL_ERROR "FAIL: OpenEye::OESiteHopper should not exist without OpenEye::OEShape and OpenEye::OESpicoli")
endif()

message(STATUS "PASS: optional OpenEye targets have closed dependencies")
]])

execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${_project_dir}"
        -B "${_build_dir}"
        "-DTEST_ROOT=${CMAKE_CURRENT_LIST_DIR}/.."
        "-DOPENEYE_ROOT=${_sdk_dir}"
    RESULT_VARIABLE _rc
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE _err
)

message(STATUS "----- sub-configure output -----")
if(_out)
    message(STATUS "${_out}")
endif()
if(_err)
    message(STATUS "${_err}")
endif()
message(STATUS "----- end sub-configure output -----")

if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "Optional target closure sub-configure failed (exit ${_rc})")
endif()

if(NOT _out MATCHES "PASS: optional OpenEye targets have closed dependencies")
    message(FATAL_ERROR "Sub-configure succeeded but PASS marker not found")
endif()

message(STATUS "PASS: optional target closure satisfied")
