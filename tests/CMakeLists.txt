cmake_minimum_required(VERSION 3.16)
project(cmake-openeye-tests VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Point CMake at the project root so find_package(OpenEye) uses our modules
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")

# Find the OpenEye toolkits (OPENEYE_ROOT must be set via preset or -D flag)
find_package(OpenEye REQUIRED)

enable_testing()

# ---------------------------------------------------------------------------
# CMake variable assertion tests
# ---------------------------------------------------------------------------
add_test(
    NAME cmake_openeye_found
    COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_FOUND=${OpenEye_FOUND}"
)
set_tests_properties(cmake_openeye_found PROPERTIES
    PASS_REGULAR_EXPRESSION "OpenEye_FOUND=1|OpenEye_FOUND=TRUE"
)

add_test(
    NAME cmake_library_type_set
    COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_LIBRARY_TYPE=${OpenEye_LIBRARY_TYPE}"
)
set_tests_properties(cmake_library_type_set PROPERTIES
    PASS_REGULAR_EXPRESSION "OpenEye_LIBRARY_TYPE=(STATIC|SHARED)"
)

add_test(
    NAME cmake_version_set
    COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_VERSION=${OpenEye_VERSION}"
)

# ---------------------------------------------------------------------------
# Required library targets: OEPlatform, OESystem, OEMath, OEChem
# Each test compiles a small C++ program that calls a function from the
# library, proving the imported target's location, includes, and transitive
# link dependencies are all correct.
# ---------------------------------------------------------------------------
add_executable(test_oeplatform test_oeplatform.cpp)
target_link_libraries(test_oeplatform PRIVATE OpenEye::OEPlatform)
add_test(NAME link_oeplatform COMMAND test_oeplatform)

add_executable(test_oesystem test_oesystem.cpp)
target_link_libraries(test_oesystem PRIVATE OpenEye::OESystem)
add_test(NAME link_oesystem COMMAND test_oesystem)

add_executable(test_oemath test_oemath.cpp)
target_link_libraries(test_oemath PRIVATE OpenEye::OEMath)
add_test(NAME link_oemath COMMAND test_oemath)

add_executable(test_oechem test_oechem.cpp)
target_link_libraries(test_oechem PRIVATE OpenEye::OEChem)
add_test(NAME link_oechem COMMAND test_oechem)

# ---------------------------------------------------------------------------
# Optional library targets: conditionally built when the library is found
# ---------------------------------------------------------------------------
if(OpenEye_Bio_FOUND)
    add_executable(test_oebio test_oebio.cpp)
    target_link_libraries(test_oebio PRIVATE OpenEye::OEBio)
    add_test(NAME link_oebio COMMAND test_oebio)

    add_test(
        NAME cmake_bio_found
        COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_Bio_FOUND=${OpenEye_Bio_FOUND}"
    )
    set_tests_properties(cmake_bio_found PROPERTIES
        PASS_REGULAR_EXPRESSION "OpenEye_Bio_FOUND=1|OpenEye_Bio_FOUND=TRUE"
    )
endif()

if(OpenEye_GraphSim_FOUND)
    add_executable(test_oegraphsim test_oegraphsim.cpp)
    target_link_libraries(test_oegraphsim PRIVATE OpenEye::OEGraphSim)
    add_test(NAME link_oegraphsim COMMAND test_oegraphsim)

    add_test(
        NAME cmake_graphsim_found
        COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_GraphSim_FOUND=${OpenEye_GraphSim_FOUND}"
    )
    set_tests_properties(cmake_graphsim_found PROPERTIES
        PASS_REGULAR_EXPRESSION "OpenEye_GraphSim_FOUND=1|OpenEye_GraphSim_FOUND=TRUE"
    )
endif()

if(OpenEye_MedChem_FOUND)
    add_executable(test_oemedchem test_oemedchem.cpp)
    target_link_libraries(test_oemedchem PRIVATE OpenEye::OEMedChem)
    add_test(NAME link_oemedchem COMMAND test_oemedchem)

    add_test(
        NAME cmake_medchem_found
        COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_MedChem_FOUND=${OpenEye_MedChem_FOUND}"
    )
    set_tests_properties(cmake_medchem_found PROPERTIES
        PASS_REGULAR_EXPRESSION "OpenEye_MedChem_FOUND=1|OpenEye_MedChem_FOUND=TRUE"
    )
endif()

if(OpenEye_Grid_FOUND)
    add_executable(test_oegrid test_oegrid.cpp)
    target_link_libraries(test_oegrid PRIVATE OpenEye::OEGrid)
    add_test(NAME link_oegrid COMMAND test_oegrid)

    add_test(
        NAME cmake_grid_found
        COMMAND ${CMAKE_COMMAND} -E echo "OpenEye_Grid_FOUND=${OpenEye_Grid_FOUND}"
    )
    set_tests_properties(cmake_grid_found PROPERTIES
        PASS_REGULAR_EXPRESSION "OpenEye_Grid_FOUND=1|OpenEye_Grid_FOUND=TRUE"
    )
endif()

if(TARGET OpenEye::OEFizzChem)
    add_test(
        NAME cmake_fizzchem_target_exists
        COMMAND ${CMAKE_COMMAND} -E echo "OpenEye::OEFizzChem target exists"
    )
endif()

# ---------------------------------------------------------------------------
# Combined link-order test: links ALL discovered OpenEye libraries in a
# single executable. This catches link-order issues with static libraries
# where symbol resolution depends on the order libraries appear on the
# command line.
#
# CMake's INTERFACE_LINK_LIBRARIES on the imported targets define the
# dependency graph. We list high-level libraries first and let CMake
# resolve the transitive closure in correct topological order.
# ---------------------------------------------------------------------------
set(_ALL_LIBS_SOURCES test_all_libraries.cpp)
set(_ALL_LIBS_LINK OpenEye::OEChem)

if(OpenEye_Bio_FOUND)
    list(APPEND _ALL_LIBS_LINK OpenEye::OEBio)
endif()
if(OpenEye_GraphSim_FOUND)
    list(APPEND _ALL_LIBS_LINK OpenEye::OEGraphSim)
endif()
if(OpenEye_MedChem_FOUND)
    list(APPEND _ALL_LIBS_LINK OpenEye::OEMedChem)
endif()
if(OpenEye_Grid_FOUND)
    list(APPEND _ALL_LIBS_LINK OpenEye::OEGrid)
endif()
if(TARGET OpenEye::OEFizzChem)
    list(APPEND _ALL_LIBS_LINK OpenEye::OEFizzChem)
endif()

add_executable(test_all_libraries ${_ALL_LIBS_SOURCES})
target_link_libraries(test_all_libraries PRIVATE ${_ALL_LIBS_LINK})

# Pass compile definitions so the test source knows which optional libs are available
if(OpenEye_Bio_FOUND)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEBIO)
endif()
if(OpenEye_GraphSim_FOUND)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEGRAPHSIM)
endif()
if(OpenEye_MedChem_FOUND)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEMEDCHEM)
endif()
if(OpenEye_Grid_FOUND)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEGRID)
endif()

add_test(NAME link_all_libraries COMMAND test_all_libraries)

# ---------------------------------------------------------------------------
# v1.1.0: Geometry and optimization targets
# ---------------------------------------------------------------------------
if(TARGET OpenEye::OEOpt)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OEOpt)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEOPT)
    add_executable(test_oeopt test_oeopt.cpp)
    target_link_libraries(test_oeopt PRIVATE OpenEye::OEOpt)
    add_test(NAME link_oeopt COMMAND test_oeopt)
endif()

if(TARGET OpenEye::OEMolPotential)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OEMolPotential)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEMOLPOTENTIAL)
    add_executable(test_oemolpotential test_oemolpotential.cpp)
    target_link_libraries(test_oemolpotential PRIVATE OpenEye::OEMolPotential)
    add_test(NAME link_oemolpotential COMMAND test_oemolpotential)
endif()

if(TARGET OpenEye::OEHermite)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OEHermite)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEHERMITE)
    add_executable(test_oehermite test_oehermite.cpp)
    target_link_libraries(test_oehermite PRIVATE OpenEye::OEHermite)
    add_test(NAME link_oehermite COMMAND test_oehermite)
endif()

if(TARGET OpenEye::OEShape)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OEShape)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OESHAPE)
    add_executable(test_oeshape test_oeshape.cpp)
    target_link_libraries(test_oeshape PRIVATE OpenEye::OEShape)
    add_test(NAME link_oeshape COMMAND test_oeshape)
endif()

# ---------------------------------------------------------------------------
# CMake target-graph assertion test (script-mode)
# Exhaustively verifies that every expected OpenEye:: imported target exists
# with the correct INTERFACE_LINK_LIBRARIES. A typo in FindOpenEye.cmake's
# dep graph will fail this test without requiring a compiler.
# ---------------------------------------------------------------------------
add_test(
    NAME cmake_target_assertions
    COMMAND ${CMAKE_COMMAND}
        -DOPENEYE_ROOT=${OPENEYE_ROOT}
        -DOPENEYE_LIB_DIR=${OPENEYE_LIB_DIR}
        -DOPENEYE_RUNTIME_LIB_DIR=${OPENEYE_RUNTIME_LIB_DIR}
        -DOPENEYE_USE_SHARED=${OPENEYE_USE_SHARED}
        -DDRIVER_DIR=${CMAKE_CURRENT_BINARY_DIR}/target_assertions_driver
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_target_assertions.cmake
)
set_tests_properties(cmake_target_assertions PROPERTIES
    PASS_REGULAR_EXPRESSION "PASS: all target assertions satisfied"
)

# ---------------------------------------------------------------------------
# FindOpenEyePython script-mode test
# Runs in a subprocess so it does not affect the current build.
# The test is expected to either succeed (if openeye-toolkits is installed)
# or report a helpful skip message.
# ---------------------------------------------------------------------------
add_test(
    NAME find_openeye_python
    COMMAND ${CMAKE_COMMAND}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/..
        -DPython3_EXECUTABLE=${Python3_EXECUTABLE}
        -DOPENEYE_ROOT=${OPENEYE_ROOT}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_find_openeye_python.cmake
)
# The script prints PASS or SKIP; both are acceptable outcomes
set_tests_properties(find_openeye_python PROPERTIES
    PASS_REGULAR_EXPRESSION "(PASS|SKIP)"
)

add_test(
    NAME oe_dir_cmake_variable
    COMMAND ${CMAKE_COMMAND}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/..
        -DOE_DIR=${OPENEYE_ROOT}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_oe_dir_variable.cmake
)
set_tests_properties(oe_dir_cmake_variable PROPERTIES
    PASS_REGULAR_EXPRESSION "PASS: OE_DIR CMake variable is honored"
)

add_test(
    NAME runtime_lib_dir_shared
    COMMAND ${CMAKE_COMMAND}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/..
        -DDRIVER_DIR=${CMAKE_CURRENT_BINARY_DIR}/runtime_lib_dir_shared_driver
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_runtime_lib_dir_shared.cmake
)
set_tests_properties(runtime_lib_dir_shared PROPERTIES
    PASS_REGULAR_EXPRESSION "(PASS|SKIP)"
)

add_test(
    NAME optional_target_closure
    COMMAND ${CMAKE_COMMAND}
        -DDRIVER_DIR=${CMAKE_CURRENT_BINARY_DIR}/optional_target_closure_driver
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_optional_target_closure.cmake
)
set_tests_properties(optional_target_closure PROPERTIES
    PASS_REGULAR_EXPRESSION "PASS: optional target closure satisfied"
)

# ---------------------------------------------------------------------------
# SDK major year detection test (script-mode, like find_openeye_python)
# ---------------------------------------------------------------------------
add_test(
    NAME test_sdk_major
    COMMAND ${CMAKE_COMMAND}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/..
        -DOPENEYE_ROOT=${OPENEYE_ROOT}
        -DOPENEYE_LIB_DIR=${OPENEYE_LIB_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_sdk_major.cmake
)
set_tests_properties(test_sdk_major PROPERTIES
    PASS_REGULAR_EXPRESSION "PASS: OpenEye_SDK_MAJOR=20[0-9][0-9]"
)

# ---------------------------------------------------------------------------
# SDK version fallback-branch coverage (bare-year install path + conservative
# warning-branch default). test_sdk_major runs against the real preset SDK;
# this test exercises the two fallback paths with synthetic fake SDKs.
# ---------------------------------------------------------------------------
add_test(
    NAME sdk_version_fallbacks
    COMMAND ${CMAKE_COMMAND}
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/..
        -DDRIVER_DIR=${CMAKE_CURRENT_BINARY_DIR}/sdk_version_fallbacks_driver
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_sdk_version_fallbacks.cmake
)
set_tests_properties(sdk_version_fallbacks PROPERTIES
    PASS_REGULAR_EXPRESSION "PASS: SDK version fallbacks satisfied"
)

if(TARGET OpenEye::OEZap)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OEZap)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OEZAP)
    add_executable(test_oezap test_oezap.cpp)
    target_link_libraries(test_oezap PRIVATE OpenEye::OEZap)
    add_test(NAME link_oezap COMMAND test_oezap)
endif()

if(TARGET OpenEye::OESpicoli)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OESpicoli)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OESPICOLI)
    add_executable(test_oespicoli test_oespicoli.cpp)
    target_link_libraries(test_oespicoli PRIVATE OpenEye::OESpicoli)
    add_test(NAME link_oespicoli COMMAND test_oespicoli)
endif()

if(TARGET OpenEye::OESiteHopper)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OESiteHopper)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OESITEHOPPER)
    add_executable(test_oesitehopper test_oesitehopper.cpp)
    target_link_libraries(test_oesitehopper PRIVATE OpenEye::OESiteHopper)
    add_test(NAME link_oesitehopper COMMAND test_oesitehopper)
endif()

foreach(_lib IN ITEMS OEMMFF OEFF OESzybki OEQuacpac OEOmega2 OESheffield)
    string(TOLOWER ${_lib} _lower)
    if(TARGET OpenEye::${_lib})
        target_link_libraries(test_all_libraries PRIVATE OpenEye::${_lib})
        string(TOUPPER ${_lib} _upper)
        target_compile_definitions(test_all_libraries PRIVATE HAS_${_upper})
        add_executable(test_${_lower} test_${_lower}.cpp)
        target_link_libraries(test_${_lower} PRIVATE OpenEye::${_lib})
        add_test(NAME link_${_lower} COMMAND test_${_lower})
    endif()
endforeach()

if(TARGET OpenEye::OESpruce)
    target_link_libraries(test_all_libraries PRIVATE OpenEye::OESpruce)
    target_compile_definitions(test_all_libraries PRIVATE HAS_OESPRUCE)
    add_executable(test_oespruce test_oespruce.cpp)
    target_link_libraries(test_oespruce PRIVATE OpenEye::OESpruce)
    add_test(NAME link_oespruce COMMAND test_oespruce)
endif()

foreach(_lib IN ITEMS OEDepict OEIUPAC)
    string(TOLOWER ${_lib} _lower)
    if(TARGET OpenEye::${_lib})
        target_link_libraries(test_all_libraries PRIVATE OpenEye::${_lib})
        string(TOUPPER ${_lib} _upper)
        target_compile_definitions(test_all_libraries PRIVATE HAS_${_upper})
        add_executable(test_${_lower} test_${_lower}.cpp)
        target_link_libraries(test_${_lower} PRIVATE OpenEye::${_lib})
        add_test(NAME link_${_lower} COMMAND test_${_lower})
    endif()
endforeach()

# ---------------------------------------------------------------------------
# abi3 fixture: builds a trivial SWIG module through openeye_add_swig_module
# with STABLE_ABI=ON, then on Windows asserts the compiled .pyd links
# python3.dll and not python3XX.dll. Guards the bug documented in
# docs/bugs/2026-04-27-windows-stable-abi-wrong-python-dll.md.
# Requires CMake 3.26+ (SABIModule) and SWIG 4.2+.
# ---------------------------------------------------------------------------
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
    find_package(SWIG 4.2 QUIET)
    if(SWIG_FOUND)
        add_subdirectory(abi3_fixture)
    else()
        message(STATUS "abi3 fixture skipped: SWIG 4.2+ not found "
                       "(older SWIG generates wrappers that reference "
                       "Python APIs outside the stable ABI)")
    endif()
else()
    message(STATUS "abi3 fixture skipped: requires CMake 3.26+")
endif()
