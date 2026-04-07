# test_find_openeye_python.cmake
# Script-mode test for FindOpenEyePython.cmake
#
# Attempts to find Python3 and then invoke FindOpenEyePython. If the
# openeye-toolkits Python package is not installed, the test reports
# SKIP rather than failing.

find_package(Python3 COMPONENTS Interpreter QUIET)

if(NOT Python3_FOUND)
    message(STATUS "SKIP: Python3 interpreter not found")
    return()
endif()

message(STATUS "Found Python3: ${Python3_EXECUTABLE}")

# Check if openeye-toolkits is installed before trying FindOpenEyePython
execute_process(
    COMMAND ${Python3_EXECUTABLE} -c "import openeye"
    RESULT_VARIABLE _OE_IMPORT_RESULT
    ERROR_QUIET
    OUTPUT_QUIET
)

if(NOT _OE_IMPORT_RESULT EQUAL 0)
    message(STATUS "SKIP: openeye-toolkits Python package not installed")
    return()
endif()

# Now run FindOpenEyePython
include(FindOpenEyePython)

if(NOT OpenEyePython_FOUND)
    message(FATAL_ERROR "FAIL: FindOpenEyePython did not set OpenEyePython_FOUND")
endif()

if(NOT OpenEyePython_LIB_DIR)
    message(FATAL_ERROR "FAIL: OpenEyePython_LIB_DIR is not set")
endif()

if(NOT IS_DIRECTORY "${OpenEyePython_LIB_DIR}")
    message(FATAL_ERROR "FAIL: OpenEyePython_LIB_DIR is not a valid directory: ${OpenEyePython_LIB_DIR}")
endif()

if(NOT OPENEYE_LIB_DIR)
    message(FATAL_ERROR "FAIL: OPENEYE_LIB_DIR not propagated for FindOpenEye.cmake consumption")
endif()

message(STATUS "OpenEyePython_LIB_DIR = ${OpenEyePython_LIB_DIR}")
message(STATUS "OpenEyePython_VERSION = ${OpenEyePython_VERSION}")
message(STATUS "OpenEyePython_PLATFORM = ${OpenEyePython_PLATFORM}")
message(STATUS "OPENEYE_LIB_DIR = ${OPENEYE_LIB_DIR}")
message(STATUS "PASS: FindOpenEyePython works correctly")
