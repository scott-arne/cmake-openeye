cmake_minimum_required(VERSION 3.26)
project(abi3_fixture LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Bring in the openeye_add_swig_module helper under test. The fixture lives two
# levels above (tests/abi3_fixture -> repo root).
get_filename_component(_CMAKE_OPENEYE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
list(PREPEND CMAKE_MODULE_PATH "${_CMAKE_OPENEYE_DIR}")
include(${_CMAKE_OPENEYE_DIR}/OpenEyeSWIG.cmake)

# find_package() inside openeye_add_swig_module scopes its result vars to the
# function. Find the interpreter here so the import-table ctest can reference
# Python3_EXECUTABLE at parent scope.
find_package(Python3 COMPONENTS Interpreter REQUIRED)

# A trivial static library stands in for the consumer project lib. The helper
# installs/copies it alongside the SWIG extension; nothing about the abi3 link
# contract depends on its contents.
add_library(abi3_fixture_core STATIC abi3_fixture.cpp)
target_include_directories(abi3_fixture_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(abi3_fixture_core PROPERTIES POSITION_INDEPENDENT_CODE ON)

set(_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/py_out)
file(MAKE_DIRECTORY ${_OUTPUT_DIR})

openeye_add_swig_module(
    NAME abi3_fixture
    SWIG_FILE ${CMAKE_CURRENT_SOURCE_DIR}/abi3_fixture.i
    LINK_LIBS abi3_fixture_core
    PYTHON_OUTPUT_DIR ${_OUTPUT_DIR}
    STABLE_ABI ON
    SWIG_FLAGS "-I${CMAKE_CURRENT_SOURCE_DIR}"
)

enable_testing()

if(WIN32)
    add_test(
        NAME abi3_import_table
        COMMAND ${Python3_EXECUTABLE}
            ${CMAKE_CURRENT_SOURCE_DIR}/check_abi3_imports.py
            $<TARGET_FILE:abi3_fixture_python>
    )
    set_tests_properties(abi3_import_table PROPERTIES
        PASS_REGULAR_EXPRESSION "PASS: extension imports python3.dll only"
    )
endif()
