# Regress OpenEye_SDK_VERSION fallback branches in FindOpenEye.cmake.
#
# Covers two fallback paths that the primary test_sdk_major test (which uses
# the real preset SDK) cannot exercise:
#
#   1. Bare-year install path. The install-path regex must accept a path
#      component like ".../toolkits/2025/..." (no ".minor.patch" suffix) and
#      populate OpenEye_SDK_VERSION with just the year. A stricter regex would
#      regress to the warning branch.
#
#   2. Warning-branch default. When no path and no openeye.h release line
#      yields a version, OpenEye_SDK_VERSION must default to a bare year so
#      VERSION_GREATER_EQUAL "2025.2" evaluates FALSE and the older dep graph
#      is selected.

if(NOT DRIVER_DIR)
    message(FATAL_ERROR "DRIVER_DIR must be provided")
endif()

set(_driver "${DRIVER_DIR}")

# ---------------------------------------------------------------------------
# Case 1: bare-year install path (no .minor.patch).
# ---------------------------------------------------------------------------
set(_sdk_bare "${_driver}/bare-year/toolkits/2025")
file(REMOVE_RECURSE "${_sdk_bare}")
file(MAKE_DIRECTORY "${_sdk_bare}/include/openeye" "${_sdk_bare}/lib")
# Do NOT write an openeye.h release line — force the path-regex fallback.
file(WRITE "${_sdk_bare}/include/openeye/openeye.h" "/* no release line */\n")
foreach(_lib IN ITEMS oechem oesystem oeplatform oemath)
    file(WRITE "${_sdk_bare}/lib/lib${_lib}.a" "")
endforeach()

set(OPENEYE_ROOT "${_sdk_bare}")
unset(OPENEYE_INCLUDE_DIR CACHE)
unset(OPENEYE_LIB_DIR CACHE)
unset(OpenEye_SDK_VERSION)
unset(OpenEye_SDK_MAJOR)
include(FindOpenEye)

if(NOT OpenEye_SDK_MAJOR STREQUAL "2025")
    message(FATAL_ERROR "FAIL: bare-year path did not set OpenEye_SDK_MAJOR=2025; got '${OpenEye_SDK_MAJOR}'")
endif()
if(NOT OpenEye_SDK_VERSION STREQUAL "2025")
    message(FATAL_ERROR "FAIL: bare-year path did not set OpenEye_SDK_VERSION=2025; got '${OpenEye_SDK_VERSION}'")
endif()
# Behavioral gate: bare-year must take the older dep-graph branch.
if(OpenEye_SDK_VERSION VERSION_GREATER_EQUAL "2025.2")
    message(FATAL_ERROR "FAIL: bare-year path still evaluated VERSION_GREATER_EQUAL 2025.2")
endif()

# ---------------------------------------------------------------------------
# Case 2: no detectable version anywhere (forces the WARNING-branch default).
# ---------------------------------------------------------------------------
set(_sdk_undetectable "${_driver}/undetectable/opt/openeye")
file(REMOVE_RECURSE "${_sdk_undetectable}")
file(MAKE_DIRECTORY "${_sdk_undetectable}/include/openeye" "${_sdk_undetectable}/lib")
file(WRITE "${_sdk_undetectable}/include/openeye/openeye.h" "/* no release line */\n")
foreach(_lib IN ITEMS oechem oesystem oeplatform oemath)
    file(WRITE "${_sdk_undetectable}/lib/lib${_lib}.a" "")
endforeach()

set(OPENEYE_ROOT "${_sdk_undetectable}")
unset(OPENEYE_INCLUDE_DIR CACHE)
unset(OPENEYE_LIB_DIR CACHE)
unset(OpenEye_SDK_VERSION)
unset(OpenEye_SDK_MAJOR)
include(FindOpenEye)

if(NOT OpenEye_SDK_MAJOR STREQUAL "2025")
    message(FATAL_ERROR "FAIL: warning-branch default did not set OpenEye_SDK_MAJOR=2025; got '${OpenEye_SDK_MAJOR}'")
endif()
if(NOT OpenEye_SDK_VERSION STREQUAL "2025")
    message(FATAL_ERROR "FAIL: warning-branch default did not set OpenEye_SDK_VERSION=2025 (was '${OpenEye_SDK_VERSION}'); "
        "a '.minor' default would silently opt into VERSION_GREATER_EQUAL 2025.2")
endif()
if(OpenEye_SDK_VERSION VERSION_GREATER_EQUAL "2025.2")
    message(FATAL_ERROR "FAIL: warning-branch default VERSION_GREATER_EQUAL 2025.2 evaluates TRUE; fallback should be conservative")
endif()

message(STATUS "PASS: SDK version fallbacks satisfied")
