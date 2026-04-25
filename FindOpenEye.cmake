# FindOpenEye.cmake
# Find OpenEye Toolkits installation
#
# This module finds the OpenEye C++ toolkits and creates imported targets.
#
# User can set these environment variables or CMake variables:
#   OPENEYE_ROOT or OE_DIR - Root directory of OpenEye installation (for headers)
#   OPENEYE_LIB_DIR        - Override library directory (e.g., from openeye-toolkits Python package)
#
# Options:
#   OPENEYE_USE_SHARED - Prefer shared libraries over static (default: OFF)
#                        Set to ON for wheels that depend on openeye-toolkits
#
# The following imported targets are created:
#   OpenEye::OEChem     - OEChem library (main chemistry library)
#   OpenEye::OESystem   - OESystem library
#   OpenEye::OEPlatform - OEPlatform library
#   OpenEye::OEMath     - OEMath library
#   OpenEye::OEGraphSim - OEGraphSim library (if available)
#   OpenEye::OEMedChem  - OEMedChem library (if available)
#   OpenEye::OEBio      - OEBio library (if available)
#   OpenEye::OEGrid     - OEGrid library (if available)
#   OpenEye::OEFizzChem - OEFizzChem library (if available)
#   OpenEye::zstd       - Bundled zstd library (if available)
#
# The following variables are set:
#   OpenEye_FOUND              - TRUE if OpenEye was found
#   OpenEye_VERSION            - Version string (e.g., "4.3.0.1")
#   OpenEye_LIBRARY_TYPE       - SHARED or STATIC
#   OpenEye_GraphSim_FOUND     - TRUE if OEGraphSim was found
#   OpenEye_MedChem_FOUND      - TRUE if OEMedChem was found
#   OpenEye_Bio_FOUND          - TRUE if OEBio was found
#   OpenEye_Grid_FOUND         - TRUE if OEGrid was found
#   OpenEye_Opt_FOUND          - TRUE if OEOpt was found
#   OpenEye_MolPotential_FOUND - TRUE if OEMolPotential was found
#   OpenEye_Hermite_FOUND      - TRUE if OEHermite was found
#   OpenEye_Shape_FOUND        - TRUE if OEShape was found

option(OPENEYE_USE_SHARED "Prefer shared OpenEye libraries for dynamic linking" OFF)
set(OPENEYE_LIB_DIR "" CACHE PATH "Override OpenEye library directory (e.g., from openeye-toolkits Python package)")

# Warn when using shared mode without a library directory override
if(OPENEYE_USE_SHARED AND NOT OPENEYE_LIB_DIR)
    message(WARNING "OPENEYE_USE_SHARED is ON but OPENEYE_LIB_DIR is not set. "
        "Shared library discovery may fail without an explicit library directory. "
        "Consider using FindOpenEyePython.cmake to auto-detect the library directory.")
endif()

# Look for the include directory
find_path(OPENEYE_INCLUDE_DIR
    NAMES openeye.h
    PATHS
        ${OPENEYE_ROOT}/include
        $ENV{OPENEYE_ROOT}/include
        $ENV{OE_DIR}/include
        /opt/openeye/include
        /usr/local/openeye/include
    PATH_SUFFIXES openeye
)

# Get the library directory - use override if provided, otherwise derive from include path
if(OPENEYE_LIB_DIR)
    message(STATUS "OpenEye: Using library directory override: ${OPENEYE_LIB_DIR}")
    set(_OPENEYE_LIB_SEARCH_PATHS ${OPENEYE_LIB_DIR})
elseif(OPENEYE_INCLUDE_DIR)
    get_filename_component(_DEFAULT_LIB_DIR "${OPENEYE_INCLUDE_DIR}/../lib" ABSOLUTE)
    set(_OPENEYE_LIB_SEARCH_PATHS ${_DEFAULT_LIB_DIR})
endif()

# Set library search order based on preference (save/restore to not affect other finds)
set(_SAVED_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
if(OPENEYE_USE_SHARED)
    # For shared linking, look for .dylib/.so first
    if(APPLE)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .dylib .a)
    else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES .so .a)
    endif()
    message(STATUS "OpenEye: Preferring shared libraries for dynamic linking")
endif()

# Helper macro to find OpenEye library, handling versioned names (e.g., liboechem-4.3.0.1.dylib)
macro(find_openeye_library VAR_NAME LIB_NAME)
    # First try to find versioned shared library in the override directory (openeye-toolkits Python package)
    if(OPENEYE_LIB_DIR AND OPENEYE_USE_SHARED)
        if(APPLE)
            file(GLOB _VERSIONED_LIB "${OPENEYE_LIB_DIR}/lib${LIB_NAME}-*.dylib")
        else()
            file(GLOB _VERSIONED_LIB "${OPENEYE_LIB_DIR}/lib${LIB_NAME}-*.so")
        endif()
        if(_VERSIONED_LIB)
            # Get the first match (should only be one)
            list(GET _VERSIONED_LIB 0 ${VAR_NAME})
            message(STATUS "OpenEye: Found versioned ${LIB_NAME}: ${${VAR_NAME}}")
        endif()
    endif()

    # Fall back to standard find_library if versioned library not found
    if(NOT ${VAR_NAME})
        find_library(${VAR_NAME}
            NAMES ${LIB_NAME}
            PATHS
                ${_OPENEYE_LIB_SEARCH_PATHS}
                ${OPENEYE_ROOT}/lib
                $ENV{OPENEYE_ROOT}/lib
                $ENV{OE_DIR}/lib
                /opt/openeye/lib
                /usr/local/openeye/lib
            NO_DEFAULT_PATH
        )
    endif()
endmacro()

# Find required libraries
find_openeye_library(OECHEM_LIBRARY oechem)
find_openeye_library(OESYSTEM_LIBRARY oesystem)
find_openeye_library(OEPLATFORM_LIBRARY oeplatform)
find_openeye_library(OEMATH_LIBRARY oemath)

# Find optional libraries
find_openeye_library(OEGRAPHSIM_LIBRARY oegraphsim)
find_openeye_library(OEMEDCHEM_LIBRARY oemedchem)
find_openeye_library(OEBIO_LIBRARY oebio)
find_openeye_library(OEGRID_LIBRARY oegrid)
find_openeye_library(OEFIZZCHEM_LIBRARY oefizzchem)

# v1.1.0: additional library discovery for geometry/optimization
find_openeye_library(OEOPT_LIBRARY oeopt)
find_openeye_library(OEMOLPOTENTIAL_LIBRARY oemolpotential)
find_openeye_library(OEHERMITE_LIBRARY oehermite)
find_openeye_library(OESHAPE_LIBRARY oeshape)

# Find bundled zstd library (OpenEye bundles this) - uses different naming
if(OPENEYE_LIB_DIR AND OPENEYE_USE_SHARED)
    file(GLOB _ZSTD_LIB "${OPENEYE_LIB_DIR}/libzstd*.dylib" "${OPENEYE_LIB_DIR}/libzstd*.so")
    if(_ZSTD_LIB)
        list(GET _ZSTD_LIB 0 OEZSTD_LIBRARY)
        message(STATUS "OpenEye: Found zstd: ${OEZSTD_LIBRARY}")
    endif()
endif()
if(NOT OEZSTD_LIBRARY)
    find_library(OEZSTD_LIBRARY
        NAMES zstd_static zstd
        PATHS
            ${_OPENEYE_LIB_SEARCH_PATHS}
            ${OPENEYE_ROOT}/lib
            $ENV{OPENEYE_ROOT}/lib
            $ENV{OE_DIR}/lib
            /opt/openeye/lib
            /usr/local/openeye/lib
        NO_DEFAULT_PATH
    )
endif()

# Restore CMAKE_FIND_LIBRARY_SUFFIXES before finding system libraries
set(CMAKE_FIND_LIBRARY_SUFFIXES ${_SAVED_CMAKE_FIND_LIBRARY_SUFFIXES})

# Find system zlib. On Windows zlib isn't a system library, so fall back to
# FetchContent so downstream projects don't need to provide it themselves.
# Skip ZLIB in script mode (for tests) since find_package cannot create targets.
if(NOT CMAKE_SCRIPT_MODE_FILE)
    find_package(ZLIB QUIET)
    if(NOT ZLIB_FOUND)
        if(WIN32)
            message(STATUS "OpenEye: ZLIB not found; fetching zlib v1.3.1 for Windows build")
            include(FetchContent)
            set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
            set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
            FetchContent_Declare(
                zlib
                GIT_REPOSITORY https://github.com/madler/zlib.git
                GIT_TAG v1.3.1
                GIT_SHALLOW TRUE
            )
            FetchContent_MakeAvailable(zlib)
            set(ZLIB_INCLUDE_DIR "${zlib_SOURCE_DIR};${zlib_BINARY_DIR}" CACHE PATH "" FORCE)
            set(ZLIB_LIBRARY zlibstatic CACHE STRING "" FORCE)
            set(ZLIB_FOUND TRUE CACHE BOOL "" FORCE)
            if(NOT TARGET ZLIB::ZLIB)
                add_library(ZLIB::ZLIB ALIAS zlibstatic)
            endif()
        else()
            find_package(ZLIB REQUIRED)
        endif()
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenEye
    REQUIRED_VARS
        OPENEYE_INCLUDE_DIR
        OECHEM_LIBRARY
        OESYSTEM_LIBRARY
        OEPLATFORM_LIBRARY
        OEMATH_LIBRARY
)

# Determine library type based on file extension
if(OpenEye_FOUND)
    # Check if library name contains .dylib or .so (handles versioned names like liboechem-4.3.0.1.dylib)
    get_filename_component(OECHEM_NAME "${OECHEM_LIBRARY}" NAME)
    if(OECHEM_NAME MATCHES "\\.dylib$" OR OECHEM_NAME MATCHES "\\.so$" OR OECHEM_NAME MATCHES "\\.so\\.")
        set(OPENEYE_LIBRARY_TYPE SHARED)
        message(STATUS "OpenEye: Using shared libraries (dynamic linking)")
    else()
        set(OPENEYE_LIBRARY_TYPE STATIC)
        message(STATUS "OpenEye: Using static libraries")
    endif()

    # Extract OEChem version from library name (e.g., liboechem-4.3.0.1.dylib)
    # This matches what OEChemGetVersion() returns at runtime
    get_filename_component(OECHEM_NAME "${OECHEM_LIBRARY}" NAME)
    string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" OpenEye_VERSION "${OECHEM_NAME}")
    if(NOT OpenEye_VERSION)
        # Try shorter version format (e.g., 4.3.0)
        string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" OpenEye_VERSION "${OECHEM_NAME}")
    endif()
    if(OpenEye_VERSION)
        message(STATUS "OpenEye: OEChem version ${OpenEye_VERSION}")
    else()
        # Try to extract from path as fallback
        string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" OpenEye_VERSION "${OPENEYE_INCLUDE_DIR}")
        if(OpenEye_VERSION)
            message(STATUS "OpenEye: Toolkit version ${OpenEye_VERSION} (from path)")
        endif()
    endif()
endif()

if(OpenEye_FOUND AND NOT TARGET OpenEye::OEChem AND NOT CMAKE_SCRIPT_MODE_FILE)
    # Create imported target for zstd if found
    if(OEZSTD_LIBRARY AND NOT TARGET OpenEye::zstd)
        add_library(OpenEye::zstd UNKNOWN IMPORTED)
        set_target_properties(OpenEye::zstd PROPERTIES
            IMPORTED_LOCATION "${OEZSTD_LIBRARY}"
        )
    endif()

    # OEPlatform depends on zlib and zstd
    add_library(OpenEye::OEPlatform UNKNOWN IMPORTED)
    set_target_properties(OpenEye::OEPlatform PROPERTIES
        IMPORTED_LOCATION "${OEPLATFORM_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
    )
    if(OEZSTD_LIBRARY)
        set_property(TARGET OpenEye::OEPlatform APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES "OpenEye::zstd;ZLIB::ZLIB"
        )
    else()
        set_property(TARGET OpenEye::OEPlatform APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES "ZLIB::ZLIB"
        )
    endif()

    # OEPlatform's Windows hostinfo uses Winsock and Netbios.
    if(WIN32)
        set_property(TARGET OpenEye::OEPlatform APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES "ws2_32;netapi32"
        )
    endif()

    add_library(OpenEye::OESystem UNKNOWN IMPORTED)
    set_target_properties(OpenEye::OESystem PROPERTIES
        IMPORTED_LOCATION "${OESYSTEM_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "OpenEye::OEPlatform"
    )

    # OEMath depends on OESystem (oemath/matrix.h includes oesystem.h)
    add_library(OpenEye::OEMath UNKNOWN IMPORTED)
    set_target_properties(OpenEye::OEMath PROPERTIES
        IMPORTED_LOCATION "${OEMATH_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "OpenEye::OESystem"
    )

    # OEChem depends on OESystem and OEMath
    add_library(OpenEye::OEChem UNKNOWN IMPORTED)
    set_target_properties(OpenEye::OEChem PROPERTIES
        IMPORTED_LOCATION "${OECHEM_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "OpenEye::OESystem;OpenEye::OEMath"
    )

    # Optional: OEGraphSim depends on OEChem
    if(OEGRAPHSIM_LIBRARY)
        add_library(OpenEye::OEGraphSim UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEGraphSim PROPERTIES
            IMPORTED_LOCATION "${OEGRAPHSIM_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OEChem"
        )
        set(OpenEye_GraphSim_FOUND TRUE)
    endif()

    # Optional: OEMedChem depends on OEChem
    if(OEMEDCHEM_LIBRARY)
        add_library(OpenEye::OEMedChem UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEMedChem PROPERTIES
            IMPORTED_LOCATION "${OEMEDCHEM_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OEChem"
        )
        set(OpenEye_MedChem_FOUND TRUE)
    endif()

    # Optional: OEFizzChem depends on OEChem
    if(OEFIZZCHEM_LIBRARY)
        add_library(OpenEye::OEFizzChem UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEFizzChem PROPERTIES
            IMPORTED_LOCATION "${OEFIZZCHEM_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OEChem"
        )
    endif()

    # Optional: OEGrid depends on OESystem and OEFizzChem (if found)
    if(OEGRID_LIBRARY)
        add_library(OpenEye::OEGrid UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEGrid PROPERTIES
            IMPORTED_LOCATION "${OEGRID_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
        )
        if(OEFIZZCHEM_LIBRARY)
            set_property(TARGET OpenEye::OEGrid PROPERTY
                INTERFACE_LINK_LIBRARIES "OpenEye::OESystem;OpenEye::OEFizzChem"
            )
        else()
            set_property(TARGET OpenEye::OEGrid PROPERTY
                INTERFACE_LINK_LIBRARIES "OpenEye::OESystem"
            )
        endif()
        set(OpenEye_Grid_FOUND TRUE)
    endif()

    # Optional: OEBio depends on OEChem and OEGrid (uses OESkewGrid, OEScalarGrid, OEXtal)
    if(OEBIO_LIBRARY)
        add_library(OpenEye::OEBio UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEBio PROPERTIES
            IMPORTED_LOCATION "${OEBIO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
        )
        if(OEGRID_LIBRARY)
            set_property(TARGET OpenEye::OEBio PROPERTY
                INTERFACE_LINK_LIBRARIES "OpenEye::OEChem;OpenEye::OEGrid"
            )
        else()
            set_property(TARGET OpenEye::OEBio PROPERTY
                INTERFACE_LINK_LIBRARIES "OpenEye::OEChem"
            )
        endif()
        set(OpenEye_Bio_FOUND TRUE)
    endif()

    # v1.1.0: Geometry and optimization targets
    if(OEOPT_LIBRARY)
        add_library(OpenEye::OEOpt UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEOpt PROPERTIES
            IMPORTED_LOCATION "${OEOPT_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OESystem"
        )
        set(OpenEye_Opt_FOUND TRUE)
    endif()

    if(OEMOLPOTENTIAL_LIBRARY)
        add_library(OpenEye::OEMolPotential UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEMolPotential PROPERTIES
            IMPORTED_LOCATION "${OEMOLPOTENTIAL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OEChem;OpenEye::OEOpt"
        )
        set(OpenEye_MolPotential_FOUND TRUE)
    endif()

    if(OEHERMITE_LIBRARY)
        add_library(OpenEye::OEHermite UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEHermite PROPERTIES
            IMPORTED_LOCATION "${OEHERMITE_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OEChem;OpenEye::OEOpt"
        )
        set(OpenEye_Hermite_FOUND TRUE)
    endif()

    # OEShape's umbrella header includes oebio.h (via sitehopperdatabase_base.h),
    # which instantiates OEFieldType<OEBio::OEDesignUnit>. Users of OEShape must
    # therefore link OEBio for the vtable symbol, so OEBio is a hard dep here.
    if(OESHAPE_LIBRARY AND OEBIO_LIBRARY)
        add_library(OpenEye::OEShape UNKNOWN IMPORTED)
        set_target_properties(OpenEye::OEShape PROPERTIES
            IMPORTED_LOCATION "${OESHAPE_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEYE_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "OpenEye::OEChem;OpenEye::OEBio;OpenEye::OEGrid;OpenEye::OEOpt;OpenEye::OEMolPotential;OpenEye::OEHermite"
        )
        set(OpenEye_Shape_FOUND TRUE)
    endif()

    # Export the library type for use in other CMake files
    set(OpenEye_LIBRARY_TYPE ${OPENEYE_LIBRARY_TYPE} CACHE STRING "OpenEye library type (SHARED or STATIC)")
endif()

# Detect the OpenEye SDK major year (e.g., 2024, 2025). The dep graph changes
# across SDK majors (notably OESpruce in 2025.2+), so downstream logic may
# condition on OpenEye_SDK_MAJOR.
set(OpenEye_SDK_MAJOR "")
if(OPENEYE_INCLUDE_DIR AND EXISTS "${OPENEYE_INCLUDE_DIR}/openeye.h")
    file(STRINGS "${OPENEYE_INCLUDE_DIR}/openeye.h" _OE_RELEASE_LINE
        REGEX "OEToolkitsRelease[ \t]+\"[0-9]+\\.[0-9]+")
    if(_OE_RELEASE_LINE)
        string(REGEX MATCH "\"([0-9]+)\\." _MATCH "${_OE_RELEASE_LINE}")
        set(OpenEye_SDK_MAJOR "${CMAKE_MATCH_1}")
    endif()
endif()
# Fallback: extract year from install path (e.g., .../toolkits/2025.2.1/...)
if(NOT OpenEye_SDK_MAJOR AND OPENEYE_INCLUDE_DIR)
    string(REGEX MATCH "/(20[0-9][0-9])\\.[0-9]+" _MATCH "${OPENEYE_INCLUDE_DIR}")
    if(CMAKE_MATCH_1)
        set(OpenEye_SDK_MAJOR "${CMAKE_MATCH_1}")
    endif()
endif()
if(NOT OpenEye_SDK_MAJOR)
    set(OpenEye_SDK_MAJOR "2025")
    message(WARNING "OpenEye: Could not detect SDK major year, defaulting to ${OpenEye_SDK_MAJOR}")
else()
    message(STATUS "OpenEye: Detected SDK major year ${OpenEye_SDK_MAJOR}")
endif()

mark_as_advanced(
    OPENEYE_INCLUDE_DIR
    OECHEM_LIBRARY
    OESYSTEM_LIBRARY
    OEPLATFORM_LIBRARY
    OEGRAPHSIM_LIBRARY
    OEMEDCHEM_LIBRARY
    OEBIO_LIBRARY
    OEGRID_LIBRARY
    OEFIZZCHEM_LIBRARY
    OEMATH_LIBRARY
    OEZSTD_LIBRARY
    OEOPT_LIBRARY
    OEMOLPOTENTIAL_LIBRARY
    OEHERMITE_LIBRARY
    OESHAPE_LIBRARY
)
