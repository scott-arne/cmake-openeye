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
    add_executable(test_oeopt test_oeopt.cpp)
    target_link_libraries(test_oeopt PRIVATE OpenEye::OEOpt)
    add_test(NAME link_oeopt COMMAND test_oeopt)
endif()

if(TARGET OpenEye::OEMolPotential)
    add_executable(test_oemolpotential test_oemolpotential.cpp)
    target_link_libraries(test_oemolpotential PRIVATE OpenEye::OEMolPotential)
    add_test(NAME link_oemolpotential COMMAND test_oemolpotential)
endif()

if(TARGET OpenEye::OEHermite)
    add_executable(test_oehermite test_oehermite.cpp)
    target_link_libraries(test_oehermite PRIVATE OpenEye::OEHermite)
    add_test(NAME link_oehermite COMMAND test_oehermite)
endif()

if(TARGET OpenEye::OEShape)
    add_executable(test_oeshape test_oeshape.cpp)
    target_link_libraries(test_oeshape PRIVATE OpenEye::OEShape)
    add_test(NAME link_oeshape COMMAND test_oeshape)
endif()

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
        -P ${CMAKE_CURRENT_SOURCE_DIR}/test_find_openeye_python.cmake
)
# The script prints PASS or SKIP; both are acceptable outcomes
set_tests_properties(find_openeye_python PROPERTIES
    PASS_REGULAR_EXPRESSION "(PASS|SKIP)"
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

if(TARGET OpenEye::OEZap)
    add_executable(test_oezap test_oezap.cpp)
    target_link_libraries(test_oezap PRIVATE OpenEye::OEZap)
    add_test(NAME link_oezap COMMAND test_oezap)
endif()

if(TARGET OpenEye::OESpicoli)
    add_executable(test_oespicoli test_oespicoli.cpp)
    target_link_libraries(test_oespicoli PRIVATE OpenEye::OESpicoli)
    add_test(NAME link_oespicoli COMMAND test_oespicoli)
endif()

if(TARGET OpenEye::OESiteHopper)
    add_executable(test_oesitehopper test_oesitehopper.cpp)
    target_link_libraries(test_oesitehopper PRIVATE OpenEye::OESiteHopper)
    add_test(NAME link_oesitehopper COMMAND test_oesitehopper)
endif()

foreach(_lib IN ITEMS OEMMFF OEFF OESzybki OEQuacpac OEOmega2 OESheffield)
    string(TOLOWER ${_lib} _lower)
    if(TARGET OpenEye::${_lib})
        add_executable(test_${_lower} test_${_lower}.cpp)
        target_link_libraries(test_${_lower} PRIVATE OpenEye::${_lib})
        add_test(NAME link_${_lower} COMMAND test_${_lower})
    endif()
endforeach()

if(TARGET OpenEye::OESpruce)
    add_executable(test_oespruce test_oespruce.cpp)
    target_link_libraries(test_oespruce PRIVATE OpenEye::OESpruce)
    add_test(NAME link_oespruce COMMAND test_oespruce)
endif()

foreach(_lib IN ITEMS OEDepict OEIUPAC)
    string(TOLOWER ${_lib} _lower)
    if(TARGET OpenEye::${_lib})
        add_executable(test_${_lower} test_${_lower}.cpp)
        target_link_libraries(test_${_lower} PRIVATE OpenEye::${_lib})
        add_test(NAME link_${_lower} COMMAND test_${_lower})
    endif()
endforeach()
