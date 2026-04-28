# Script-mode test for OE_DIR as a CMake variable.
#
# README documents OPENEYE_ROOT / OE_DIR as environment variables or CMake
# variables. This test verifies -DOE_DIR=/path/to/sdk works without relying on
# OPENEYE_ROOT or OE_DIR from the process environment.

if(NOT OE_DIR)
    message(FATAL_ERROR "OE_DIR must be provided")
endif()

set(ENV{OPENEYE_ROOT} "")
set(ENV{OE_DIR} "")

include(FindOpenEye)

if(NOT OpenEye_FOUND)
    message(FATAL_ERROR "FAIL: OpenEye not found from CMake variable OE_DIR=${OE_DIR}")
endif()

message(STATUS "PASS: OE_DIR CMake variable is honored")
