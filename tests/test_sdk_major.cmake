# Script-mode test for OpenEye_SDK_MAJOR detection
# Usage: cmake -DCMAKE_MODULE_PATH=... -DOPENEYE_ROOT=... -DOPENEYE_LIB_DIR=... -P test_sdk_major.cmake
#
# Exercises FindOpenEye.cmake's SDK-major detection end-to-end. A bug in the
# Find module's regex or fallback chain will fail this test.

include(FindOpenEye)

if(NOT DEFINED OpenEye_SDK_MAJOR)
    message(FATAL_ERROR "FAIL: OpenEye_SDK_MAJOR is not set after include(FindOpenEye)")
endif()

if(NOT OpenEye_SDK_MAJOR MATCHES "^(2024|2025|2026|2027)$")
    message(FATAL_ERROR "FAIL: OpenEye_SDK_MAJOR=${OpenEye_SDK_MAJOR} is not a plausible year")
endif()

message(STATUS "PASS: OpenEye_SDK_MAJOR=${OpenEye_SDK_MAJOR}")
