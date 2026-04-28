# Verify OPENEYE_RUNTIME_LIB_DIR participates in POSIX shared discovery.
#
# This uses a fake SDK with static archives and a separate fake runtime
# directory with versioned shared libraries. OPENEYE_USE_SHARED=ON must select
# the runtime shared libraries instead of silently falling back to SDK static
# archives when OPENEYE_LIB_DIR is unset.

if(WIN32)
    message(STATUS "SKIP: OPENEYE_RUNTIME_LIB_DIR shared discovery is POSIX-only")
    return()
endif()

if(NOT DRIVER_DIR)
    message(FATAL_ERROR "DRIVER_DIR must be provided")
endif()

set(_driver_dir "${DRIVER_DIR}")
set(_sdk_dir "${_driver_dir}/fake-sdk")
set(_runtime_dir "${_driver_dir}/runtime-libs")

file(REMOVE_RECURSE "${_driver_dir}")
file(MAKE_DIRECTORY "${_sdk_dir}/include/openeye" "${_sdk_dir}/lib" "${_runtime_dir}")

file(WRITE "${_sdk_dir}/include/openeye/openeye.h" "#define OEToolkitsRelease \"2025.2.1\"\n")

if(APPLE)
    set(_shared_suffix ".dylib")
else()
    set(_shared_suffix ".so")
endif()

foreach(_lib IN ITEMS oechem oesystem oeplatform oemath)
    file(WRITE "${_sdk_dir}/lib/lib${_lib}.a" "")
    file(WRITE "${_runtime_dir}/lib${_lib}-1.2.3.4${_shared_suffix}" "")
endforeach()

set(OPENEYE_ROOT "${_sdk_dir}")
set(OPENEYE_RUNTIME_LIB_DIR "${_runtime_dir}" CACHE PATH "" FORCE)
set(OPENEYE_USE_SHARED ON CACHE BOOL "" FORCE)

include(FindOpenEye)

if(NOT OpenEye_FOUND)
    message(FATAL_ERROR "FAIL: OpenEye not found")
endif()

if(NOT OpenEye_LIBRARY_TYPE STREQUAL "SHARED")
    message(FATAL_ERROR "FAIL: expected SHARED, got OpenEye_LIBRARY_TYPE=${OpenEye_LIBRARY_TYPE}")
endif()

if(NOT OECHEM_LIBRARY MATCHES "^${_runtime_dir}/")
    message(FATAL_ERROR "FAIL: expected OECHEM_LIBRARY from runtime dir, got ${OECHEM_LIBRARY}")
endif()

message(STATUS "PASS: OPENEYE_RUNTIME_LIB_DIR selects POSIX shared libraries")
