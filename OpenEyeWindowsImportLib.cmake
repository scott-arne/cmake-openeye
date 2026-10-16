# OpenEyeWindowsImportLib.cmake
# Generate MSVC import libraries from the export tables of OpenEye's Windows DLLs.
#
# The openeye-toolkits Windows wheel ships the toolkit DLLs flat in
# openeye/libs/ and ships no .lib files at all, so there is nothing for the
# MSVC linker to link against. The DLLs do export the full C++ API
# (__declspec(dllexport)-style mangled exports, not a C shim), and the SDK
# headers already have the consumer side of that: OE_USE_DLL switches every
# OECHEM_API-style macro to __declspec(dllimport). The only missing piece is
# the import library, which can be reconstructed from each DLL's own export
# table.
#
# Public entry point:
#   openeye_generate_import_library(DLL <path> OUTPUT_DIR <dir>
#                                   OUTPUT_VARIABLE <var>)
#
# The two parsing steps are separate functions so they can be exercised
# without a Windows host (see tests/test_windows_import_lib.cmake):
#   openeye_pe_code_ranges(HEADERS_TEXT <text> OUTPUT_VARIABLE <var>)
#   openeye_def_from_exports(EXPORTS_TEXT <text> CODE_RANGES <ranges>
#                            LIBRARY_NAME <name> OUTPUT_VARIABLE <var>)

# Format an integer as an 8-digit uppercase hex string, so that RVAs can be
# ordered with plain string comparison instead of a math() call per export.
function(_openeye_hex8 _value _out)
    math(EXPR _hex "${_value}" OUTPUT_FORMAT HEXADECIMAL)
    string(REGEX REPLACE "^0[xX]" "" _hex "${_hex}")
    string(TOUPPER "${_hex}" _hex)
    string(LENGTH "${_hex}" _len)
    if(_len LESS 8)
        math(EXPR _pad "8 - ${_len}")
        string(REPEAT "0" ${_pad} _zeros)
        set(_hex "${_zeros}${_hex}")
    endif()
    set(${_out} "${_hex}" PARENT_SCOPE)
endfunction()

# Split text into a CMake list of lines without letting embedded semicolons
# split a line in two.
function(_openeye_text_to_lines _text _out)
    string(REPLACE ";" "\\;" _escaped "${_text}")
    string(REGEX REPLACE "\r?\n" ";" _lines "${_escaped}")
    set(${_out} "${_lines}" PARENT_SCOPE)
endfunction()

#[============================================================================[
  openeye_pe_code_ranges(HEADERS_TEXT <text> OUTPUT_VARIABLE <var>)

  Parse `dumpbin /HEADERS` output and return the RVA ranges covered by
  sections that hold executable code (IMAGE_SCN_CNT_CODE, 0x20). Each range
  is "START:END" with both bounds as 8-digit uppercase hex, END exclusive.

  An export whose RVA falls outside every code range is exported data, and
  must be marked DATA in the module-definition file. Without that mark the
  import library would hand the consumer the address of a jump thunk instead
  of the address of the variable.
#]============================================================================]
function(openeye_pe_code_ranges)
    cmake_parse_arguments(ARG "" "HEADERS_TEXT;OUTPUT_VARIABLE" "" ${ARGN})
    if(NOT ARG_OUTPUT_VARIABLE)
        message(FATAL_ERROR "openeye_pe_code_ranges: OUTPUT_VARIABLE is required")
    endif()

    _openeye_text_to_lines("${ARG_HEADERS_TEXT}" _lines)

    set(_ranges "")
    set(_vaddr "")
    set(_vsize "")
    foreach(_line IN LISTS _lines)
        if(_line MATCHES "^SECTION HEADER #")
            set(_vaddr "")
            set(_vsize "")
        elseif(_line MATCHES "^[ \t]*([0-9A-Fa-f]+) virtual size")
            set(_vsize "${CMAKE_MATCH_1}")
        elseif(_line MATCHES "^[ \t]*([0-9A-Fa-f]+) virtual address")
            set(_vaddr "${CMAKE_MATCH_1}")
        elseif(_line MATCHES "^[ \t]*([0-9A-Fa-f]+) flags")
            math(EXPR _is_code "0x${CMAKE_MATCH_1} & 0x20")
            if(_is_code AND _vaddr AND _vsize)
                math(EXPR _start "0x${_vaddr}")
                math(EXPR _end "0x${_vaddr} + 0x${_vsize}")
                _openeye_hex8("${_start}" _start_hex)
                _openeye_hex8("${_end}" _end_hex)
                list(APPEND _ranges "${_start_hex}:${_end_hex}")
            endif()
            set(_vaddr "")
            set(_vsize "")
        endif()
    endforeach()

    set(${ARG_OUTPUT_VARIABLE} "${_ranges}" PARENT_SCOPE)
endfunction()

#[============================================================================[
  openeye_def_from_exports(EXPORTS_TEXT <text> CODE_RANGES <ranges>
                           LIBRARY_NAME <name> OUTPUT_VARIABLE <var>)

  Turn `dumpbin /EXPORTS` output into module-definition file content.

  Exports are listed by name and never by ordinal: binding by ordinal would
  make the generated import library wrong for any DLL build whose ordinals
  shift, and OpenEye assigns ordinals alphabetically, so adding one symbol
  renumbers most of them.
#]============================================================================]
function(openeye_def_from_exports)
    cmake_parse_arguments(ARG "" "EXPORTS_TEXT;LIBRARY_NAME;OUTPUT_VARIABLE" "CODE_RANGES" ${ARGN})
    if(NOT ARG_OUTPUT_VARIABLE)
        message(FATAL_ERROR "openeye_def_from_exports: OUTPUT_VARIABLE is required")
    endif()
    if(NOT ARG_LIBRARY_NAME)
        message(FATAL_ERROR "openeye_def_from_exports: LIBRARY_NAME is required")
    endif()

    # Pre-split the ranges once; the classification below runs per export and
    # the largest OpenEye DLL has over eight thousand of them.
    set(_starts "")
    set(_ends "")
    foreach(_range IN LISTS ARG_CODE_RANGES)
        if(_range MATCHES "^([0-9A-Fa-f]+):([0-9A-Fa-f]+)$")
            list(APPEND _starts "${CMAKE_MATCH_1}")
            list(APPEND _ends "${CMAKE_MATCH_2}")
        else()
            message(FATAL_ERROR "openeye_def_from_exports: malformed code range '${_range}'")
        endif()
    endforeach()
    list(LENGTH _starts _nranges)

    _openeye_text_to_lines("${ARG_EXPORTS_TEXT}" _lines)

    set(_body "")
    foreach(_line IN LISTS _lines)
        # A forwarded export occupies the RVA column with nothing, so match it
        # before the ordinary form; otherwise a forwarder whose name happens to
        # be all hex digits would be read as an RVA.
        if(_line MATCHES "^[ \t]+[0-9]+[ \t]+[0-9A-Fa-f]+[ \t]+([^ \t]+)[ \t]+\\(forwarded to")
            set(_name "${CMAKE_MATCH_1}")
            if(NOT _name MATCHES "^\\[")
                string(APPEND _body "    ${_name}\n")
            endif()
        elseif(_line MATCHES "^[ \t]+[0-9]+[ \t]+[0-9A-Fa-f]+[ \t]+([0-9A-Fa-f]+)[ \t]+([^ \t]+)")
            set(_rva "${CMAKE_MATCH_1}")
            set(_name "${CMAKE_MATCH_2}")

            # Exports with no name cannot be referenced from a .def without
            # pinning an ordinal, which is exactly what this generator avoids.
            if(_name MATCHES "^\\[")
                continue()
            endif()

            string(TOUPPER "${_rva}" _rva)
            string(LENGTH "${_rva}" _rva_len)
            if(_rva_len LESS 8)
                math(EXPR _pad "8 - ${_rva_len}")
                string(REPEAT "0" ${_pad} _zeros)
                set(_rva "${_zeros}${_rva}")
            endif()

            set(_is_code FALSE)
            if(_nranges GREATER 0)
                math(EXPR _last "${_nranges} - 1")
                foreach(_i RANGE ${_last})
                    list(GET _starts ${_i} _start)
                    list(GET _ends ${_i} _end)
                    if(NOT _rva STRLESS _start AND _rva STRLESS _end)
                        set(_is_code TRUE)
                        break()
                    endif()
                endforeach()
            endif()

            if(_is_code)
                string(APPEND _body "    ${_name}\n")
            else()
                string(APPEND _body "    ${_name} DATA\n")
            endif()
        endif()
    endforeach()

    set(${ARG_OUTPUT_VARIABLE}
        "; Generated by cmake-openeye from the export table of ${ARG_LIBRARY_NAME}.\n; Do not edit; regenerated whenever the DLL is newer than the import library.\nLIBRARY \"${ARG_LIBRARY_NAME}\"\nEXPORTS\n${_body}"
        PARENT_SCOPE)
endfunction()

#[============================================================================[
  openeye_generate_import_library(DLL <path> OUTPUT_DIR <dir>
                                  OUTPUT_VARIABLE <var>)

  Write <OUTPUT_DIR>/<dll stem>.lib from the DLL's export table and return its
  path. Regenerated only when the DLL is newer than an existing import
  library, so a reconfigure costs nothing.
#]============================================================================]
function(openeye_generate_import_library)
    cmake_parse_arguments(ARG "" "DLL;OUTPUT_DIR;OUTPUT_VARIABLE" "" ${ARGN})
    foreach(_required DLL OUTPUT_DIR OUTPUT_VARIABLE)
        if(NOT ARG_${_required})
            message(FATAL_ERROR "openeye_generate_import_library: ${_required} is required")
        endif()
    endforeach()
    if(NOT EXISTS "${ARG_DLL}")
        message(FATAL_ERROR "openeye_generate_import_library: no such DLL: ${ARG_DLL}")
    endif()

    get_filename_component(_dll_name "${ARG_DLL}" NAME)
    get_filename_component(_stem "${ARG_DLL}" NAME_WLE)
    set(_def_path "${ARG_OUTPUT_DIR}/${_stem}.def")
    set(_lib_path "${ARG_OUTPUT_DIR}/${_stem}.lib")

    if(EXISTS "${_lib_path}" AND NOT "${ARG_DLL}" IS_NEWER_THAN "${_lib_path}")
        set(${ARG_OUTPUT_VARIABLE} "${_lib_path}" PARENT_SCOPE)
        return()
    endif()

    find_program(OPENEYE_DUMPBIN_EXECUTABLE NAMES dumpbin dumpbin.exe)
    find_program(OPENEYE_LIB_EXECUTABLE NAMES lib lib.exe)
    if(NOT OPENEYE_DUMPBIN_EXECUTABLE OR NOT OPENEYE_LIB_EXECUTABLE)
        message(FATAL_ERROR
            "OpenEye: shared linking against the openeye-toolkits Windows wheel needs "
            "dumpbin and lib from the MSVC toolchain to build import libraries from the "
            "wheel's DLLs, and they are not on PATH. Run from a Visual Studio developer "
            "prompt, or set OPENEYE_USE_SHARED=OFF to link the static SDK instead.")
    endif()

    execute_process(
        COMMAND "${OPENEYE_DUMPBIN_EXECUTABLE}" /NOLOGO /HEADERS "${ARG_DLL}"
        OUTPUT_VARIABLE _headers_text
        ERROR_VARIABLE _headers_error
        RESULT_VARIABLE _headers_result
    )
    if(NOT _headers_result EQUAL 0)
        message(FATAL_ERROR "OpenEye: dumpbin /HEADERS failed on ${ARG_DLL}: ${_headers_error}")
    endif()

    execute_process(
        COMMAND "${OPENEYE_DUMPBIN_EXECUTABLE}" /NOLOGO /EXPORTS "${ARG_DLL}"
        OUTPUT_VARIABLE _exports_text
        ERROR_VARIABLE _exports_error
        RESULT_VARIABLE _exports_result
    )
    if(NOT _exports_result EQUAL 0)
        message(FATAL_ERROR "OpenEye: dumpbin /EXPORTS failed on ${ARG_DLL}: ${_exports_error}")
    endif()

    openeye_pe_code_ranges(HEADERS_TEXT "${_headers_text}" OUTPUT_VARIABLE _code_ranges)
    openeye_def_from_exports(
        EXPORTS_TEXT "${_exports_text}"
        CODE_RANGES ${_code_ranges}
        LIBRARY_NAME "${_dll_name}"
        OUTPUT_VARIABLE _def_content
    )

    if(NOT _def_content MATCHES "\nEXPORTS\n.")
        message(FATAL_ERROR
            "OpenEye: ${_dll_name} has no named exports, so no import library can be "
            "generated from it. Set OPENEYE_USE_SHARED=OFF to link the static SDK instead.")
    endif()

    file(MAKE_DIRECTORY "${ARG_OUTPUT_DIR}")
    file(WRITE "${_def_path}" "${_def_content}")

    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(_machine X86)
    else()
        set(_machine X64)
    endif()

    execute_process(
        COMMAND "${OPENEYE_LIB_EXECUTABLE}" /NOLOGO "/DEF:${_def_path}"
                "/MACHINE:${_machine}" "/OUT:${_lib_path}"
        OUTPUT_VARIABLE _lib_output
        ERROR_VARIABLE _lib_error
        RESULT_VARIABLE _lib_result
    )
    if(NOT _lib_result EQUAL 0 OR NOT EXISTS "${_lib_path}")
        message(FATAL_ERROR
            "OpenEye: lib /DEF:${_def_path} failed for ${_dll_name}: ${_lib_output}${_lib_error}")
    endif()

    message(STATUS "OpenEye: Generated import library ${_lib_path} from ${_dll_name}")
    set(${ARG_OUTPUT_VARIABLE} "${_lib_path}" PARENT_SCOPE)
endfunction()
