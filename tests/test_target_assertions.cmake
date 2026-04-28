cmake_minimum_required(VERSION 3.16)

# Script-mode driver for CMake target assertions.
#
# Usage: cmake -DOPENEYE_ROOT=... [-DOPENEYE_LIB_DIR=...] [-DOPENEYE_RUNTIME_LIB_DIR=...] -P test_target_assertions.cmake
#
# Why this is a driver rather than a direct script: FindOpenEye.cmake only
# creates IMPORTED targets when NOT in script mode (see the CMAKE_SCRIPT_MODE_FILE
# guard around the add_library(... IMPORTED) block). add_library is also
# intentionally non-scriptable in CMake. So this file cannot itself assert on
# imported targets; instead it generates a tiny project in a temp directory
# whose CMakeLists.txt calls find_package(OpenEye) and runs the target
# assertions, then drives a real project-mode configure via execute_process.
# The driver converts the sub-configure result into a single PASS/FATAL line.

if(NOT OPENEYE_ROOT)
    message(FATAL_ERROR "OPENEYE_ROOT must be provided, e.g. -DOPENEYE_ROOT=/path/to/toolkits")
endif()

# DRIVER_DIR must be passed via -D (the test registration in tests/CMakeLists.txt
# points this at the test build tree so the scratch project stays out of the
# source tree).
if(NOT DRIVER_DIR)
    message(FATAL_ERROR "DRIVER_DIR must be provided, e.g. -DDRIVER_DIR=/path/to/scratch")
endif()
set(_driver_dir "${DRIVER_DIR}")
file(MAKE_DIRECTORY "${_driver_dir}")
set(_driver_build "${_driver_dir}/build")
file(REMOVE_RECURSE "${_driver_build}")

# The body of the generated CMakeLists. Escaped so ${...} is resolved at
# sub-configure time, not here. Populated from the authoritative dep lists in
# FindOpenEye.cmake as of v1.1.0.
set(_asserts_cmakelists [[
cmake_minimum_required(VERSION 3.16)
# LANGUAGES C (not NONE) so FindZLIB and FindThreads in FindOpenEye.cmake can
# run their compile probes -- on some platforms (e.g. rockylinux:9 aarch64)
# FindZLIB's ZLIB_LIBRARY probe fails without a working C compiler, which
# takes down find_package(ZLIB REQUIRED).
project(target_assertions LANGUAGES C)

list(PREPEND CMAKE_MODULE_PATH "${TEST_ROOT}")
find_package(OpenEye REQUIRED)

set(_fail FALSE)

function(assert_target_exists tgt)
    if(NOT TARGET ${tgt})
        message(SEND_ERROR "FAIL: expected target ${tgt} does not exist")
        set(_fail TRUE PARENT_SCOPE)
    endif()
endfunction()

function(assert_interface_link_libraries tgt expected)
    if(NOT TARGET ${tgt})
        message(SEND_ERROR "FAIL: target ${tgt} does not exist (cannot check INTERFACE_LINK_LIBRARIES)")
        set(_fail TRUE PARENT_SCOPE)
        return()
    endif()
    get_target_property(_actual ${tgt} INTERFACE_LINK_LIBRARIES)
    if(NOT "${_actual}" STREQUAL "${expected}")
        message(SEND_ERROR
            "FAIL: ${tgt} INTERFACE_LINK_LIBRARIES mismatch\n"
            "  expected: ${expected}\n"
            "  actual:   ${_actual}")
        set(_fail TRUE PARENT_SCOPE)
    endif()
endfunction()

# --- Foundation targets (always present) -----------------------------------
assert_target_exists(OpenEye::OEPlatform)
# OEPlatform's INTERFACE_LINK_LIBRARIES depends on whether zstd was found
# (FindOpenEye.cmake lines 310-318). When both zstd and ZLIB targets exist the
# expected value is "OpenEye::zstd;ZLIB::ZLIB"; otherwise "ZLIB::ZLIB" only.
# We assert the exact value matching the current discovery state rather than
# trying to match substrings -- mismatches against the graph-as-configured are
# what we want to catch. On Windows, ws2_32 and netapi32 are appended.
if(TARGET OpenEye::zstd)
    set(_platform_expected "OpenEye::zstd;ZLIB::ZLIB")
    # OpenEye::zstd pulls in Threads::Threads on systems where find_package(Threads)
    # found one, covering pre-glibc-2.34 RHEL 8 / Ubuntu 20.04 linkers.
    if(TARGET Threads::Threads)
        assert_interface_link_libraries(OpenEye::zstd "Threads::Threads")
    endif()
else()
    set(_platform_expected "ZLIB::ZLIB")
endif()
if(WIN32)
    list(APPEND _platform_expected "ws2_32" "netapi32")
endif()
assert_interface_link_libraries(OpenEye::OEPlatform "${_platform_expected}")

assert_target_exists(OpenEye::OESystem)
assert_interface_link_libraries(OpenEye::OESystem "OpenEye::OEPlatform")

assert_target_exists(OpenEye::OEMath)
assert_interface_link_libraries(OpenEye::OEMath "OpenEye::OESystem")

assert_target_exists(OpenEye::OEChem)
assert_interface_link_libraries(OpenEye::OEChem "OpenEye::OESystem;OpenEye::OEMath")

# --- Optional pre-v1.1.0 targets ------------------------------------------
if(TARGET OpenEye::OEGraphSim)
    assert_interface_link_libraries(OpenEye::OEGraphSim "OpenEye::OEChem")
endif()
if(TARGET OpenEye::OEMedChem)
    assert_interface_link_libraries(OpenEye::OEMedChem "OpenEye::OEChem")
endif()
if(TARGET OpenEye::OEFizzChem)
    assert_interface_link_libraries(OpenEye::OEFizzChem "OpenEye::OEChem")
endif()
if(TARGET OpenEye::OEGrid)
    if(TARGET OpenEye::OEFizzChem)
        assert_interface_link_libraries(OpenEye::OEGrid "OpenEye::OESystem;OpenEye::OEFizzChem")
    else()
        assert_interface_link_libraries(OpenEye::OEGrid "OpenEye::OESystem")
    endif()
endif()
if(TARGET OpenEye::OEBio)
    if(TARGET OpenEye::OEGrid)
        assert_interface_link_libraries(OpenEye::OEBio "OpenEye::OEChem;OpenEye::OEGrid")
    else()
        assert_interface_link_libraries(OpenEye::OEBio "OpenEye::OEChem")
    endif()
endif()

# --- v1.1.0 (A2): geometry / optimization ----------------------------------
if(TARGET OpenEye::OEOpt)
    assert_interface_link_libraries(OpenEye::OEOpt "OpenEye::OESystem")
endif()
if(TARGET OpenEye::OEMolPotential)
    assert_interface_link_libraries(OpenEye::OEMolPotential "OpenEye::OEChem;OpenEye::OEOpt")
endif()
if(TARGET OpenEye::OEHermite)
    assert_interface_link_libraries(OpenEye::OEHermite "OpenEye::OEChem;OpenEye::OEOpt")
endif()

# --- v1.1.0 (A3): shape ---------------------------------------------------
if(TARGET OpenEye::OEShape)
    assert_interface_link_libraries(OpenEye::OEShape
        "OpenEye::OEChem;OpenEye::OEBio;OpenEye::OEGrid;OpenEye::OEOpt;OpenEye::OEMolPotential;OpenEye::OEHermite")
endif()

# --- v1.1.0 (A4): electrostatics / surfaces / site hopping -----------------
if(TARGET OpenEye::OEZap)
    assert_interface_link_libraries(OpenEye::OEZap "OpenEye::OEChem;OpenEye::OEGrid")
endif()
if(TARGET OpenEye::OESpicoli)
    assert_interface_link_libraries(OpenEye::OESpicoli "OpenEye::OEChem;OpenEye::OEZap;OpenEye::OEBio")
endif()
if(TARGET OpenEye::OESiteHopper)
    assert_interface_link_libraries(OpenEye::OESiteHopper
        "OpenEye::OEChem;OpenEye::OEShape;OpenEye::OESpicoli;${CMAKE_DL_LIBS}")
endif()

# --- v1.1.0 (A5): force fields / conformer / protonation ------------------
if(TARGET OpenEye::OEMMFF)
    assert_interface_link_libraries(OpenEye::OEMMFF "OpenEye::OEChem;OpenEye::OEMolPotential")
endif()
if(TARGET OpenEye::OEFF)
    assert_interface_link_libraries(OpenEye::OEFF "OpenEye::OEChem")
endif()
if(TARGET OpenEye::OESzybki)
    assert_interface_link_libraries(OpenEye::OESzybki
        "OpenEye::OEChem;OpenEye::OEMMFF;OpenEye::OEFF;OpenEye::OEBio")
endif()
if(TARGET OpenEye::OEQuacpac)
    assert_interface_link_libraries(OpenEye::OEQuacpac "OpenEye::OEChem;OpenEye::OESzybki")
endif()
if(TARGET OpenEye::OEOmega2)
    assert_interface_link_libraries(OpenEye::OEOmega2 "OpenEye::OEChem;OpenEye::OEMMFF")
endif()
if(TARGET OpenEye::OESheffield)
    assert_interface_link_libraries(OpenEye::OESheffield
        "OpenEye::OEChem;OpenEye::OEMolPotential;OpenEye::OEFizzChem;OpenEye::OEGrid;OpenEye::OEZap")
endif()

# --- v1.1.0 (A6): Spruce (SDK-major-dependent) ----------------------------
if(TARGET OpenEye::OESpruce)
    if(OpenEye_SDK_VERSION VERSION_GREATER_EQUAL 2025.2)
        assert_interface_link_libraries(OpenEye::OESpruce
            "OpenEye::OEChem;OpenEye::OEBio;OpenEye::OESiteHopper;OpenEye::OEQuacpac;OpenEye::OEMMFF;OpenEye::OEOmega2;OpenEye::OESheffield")
    else()
        assert_interface_link_libraries(OpenEye::OESpruce
            "OpenEye::OEChem;OpenEye::OEBio;OpenEye::OESiteHopper")
    endif()
endif()

# --- v1.1.0 (A7): depiction / nomenclature --------------------------------
if(TARGET OpenEye::OEDepict)
    assert_interface_link_libraries(OpenEye::OEDepict "OpenEye::OEChem")
endif()
if(TARGET OpenEye::OEIUPAC)
    assert_interface_link_libraries(OpenEye::OEIUPAC "OpenEye::OEChem")
endif()

if(_fail)
    message(FATAL_ERROR "One or more target assertions failed")
else()
    message(STATUS "PASS: all target assertions satisfied (SDK ${OpenEye_SDK_VERSION})")
endif()
]])

file(WRITE "${_driver_dir}/CMakeLists.txt" "${_asserts_cmakelists}")

# Propagate OPENEYE_LIB_DIR if the caller set one (wheel / shared-lib builds).
set(_extra_defs "")
if(OPENEYE_LIB_DIR)
    list(APPEND _extra_defs "-DOPENEYE_LIB_DIR=${OPENEYE_LIB_DIR}")
endif()
if(OPENEYE_RUNTIME_LIB_DIR)
    list(APPEND _extra_defs "-DOPENEYE_RUNTIME_LIB_DIR=${OPENEYE_RUNTIME_LIB_DIR}")
endif()
if(OPENEYE_USE_SHARED)
    list(APPEND _extra_defs "-DOPENEYE_USE_SHARED=${OPENEYE_USE_SHARED}")
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND}
        -S "${_driver_dir}"
        -B "${_driver_build}"
        "-DTEST_ROOT=${CMAKE_CURRENT_LIST_DIR}/.."
        "-DOPENEYE_ROOT=${OPENEYE_ROOT}"
        ${_extra_defs}
    RESULT_VARIABLE _rc
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE  _err
)

# Mirror the sub-configure output so ctest --output-on-failure shows the
# actual FAIL: lines from assert_interface_link_libraries, not just our wrapper.
message(STATUS "----- sub-configure output -----")
if(_out)
    message(STATUS "${_out}")
endif()
if(_err)
    message(STATUS "${_err}")
endif()
message(STATUS "----- end sub-configure output -----")

if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "Target assertion sub-configure failed (exit ${_rc})")
endif()

if(NOT _out MATCHES "PASS: all target assertions satisfied")
    message(FATAL_ERROR "Sub-configure succeeded but PASS marker not found in output")
endif()

# Re-emit the PASS line on the driver's own stdout so the ctest
# PASS_REGULAR_EXPRESSION matches against this outer process's output.
string(REGEX MATCH "PASS: all target assertions satisfied[^\n]*" _pass_line "${_out}")
message(STATUS "${_pass_line}")
