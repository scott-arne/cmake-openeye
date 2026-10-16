# Verify the Windows import-library generator's two parsing steps.
#
# The generator itself needs dumpbin and lib, so it can only run on a Windows
# host. The part that decides what ends up in the module-definition file is
# pure text processing, and that is the part that can be wrong in a way the
# linker will not catch: an exported variable emitted without the DATA
# keyword yields an import library that hands consumers the address of a jump
# thunk instead of the address of the variable. So the parsing is driven here
# from canned dumpbin output, on any host.

if(NOT DEFINED CMAKE_MODULE_PATH)
    message(FATAL_ERROR "CMAKE_MODULE_PATH must be provided")
endif()

include(OpenEyeWindowsImportLib)

set(_fail FALSE)

function(expect_equal _label _actual _expected)
    if(NOT "${_actual}" STREQUAL "${_expected}")
        message(SEND_ERROR "FAIL: ${_label}\n  expected: [${_expected}]\n  actual:   [${_actual}]")
        set(_fail TRUE PARENT_SCOPE)
    endif()
endfunction()

# ---------------------------------------------------------------------------
# Section table: one executable section plus initialised-data sections.
# ---------------------------------------------------------------------------
set(_headers "Microsoft (R) COFF/PE Dumper Version 14.38.33133.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file oechem-5.0.0.0.dll

PE signature found

File Type: DLL

FILE HEADER VALUES
            8664 machine (x64)
               4 number of sections
            2022 characteristics
                   Executable
                   DLL

OPTIONAL HEADER VALUES
             20B magic # (PE32+)
            1000 section alignment
             200 file alignment
            8160 DLL characteristics

SECTION HEADER #1
   .text name
  5C2E7A virtual size
    1000 virtual address (0000000180001000 to 00000001805C3E79)
  5C3000 size of raw data
60000020 flags
         Code
         Execute Read

SECTION HEADER #2
  .rdata name
  1A4B32 virtual size
  5C4000 virtual address (00000001805C4000 to 0000000180768B31)
  1A4C00 size of raw data
40000040 flags
         Initialized Data
         Read Only

SECTION HEADER #3
   .data name
   1B000 virtual size
  769000 virtual address (0000000180769000 to 0000000180783FFF)
    6000 size of raw data
C0000040 flags
         Initialized Data
         Read Write
")

openeye_pe_code_ranges(HEADERS_TEXT "${_headers}" OUTPUT_VARIABLE _ranges)
expect_equal("code ranges cover .text only" "${_ranges}" "00001000:005C3E7A")

# A second executable section must also be picked up, and a section whose
# flags lack IMAGE_SCN_CNT_CODE must not be.
set(_two_code_headers "SECTION HEADER #1
   .text name
    1000 virtual size
    1000 virtual address (0000000180001000 to 0000000180001FFF)
60000020 flags
         Code

SECTION HEADER #2
  .rdata name
    1000 virtual size
    2000 virtual address (0000000180002000 to 0000000180002FFF)
40000040 flags
         Initialized Data

SECTION HEADER #3
  .text1 name
     800 virtual size
    3000 virtual address (0000000180003000 to 00000001800037FF)
60000020 flags
         Code
")
openeye_pe_code_ranges(HEADERS_TEXT "${_two_code_headers}" OUTPUT_VARIABLE _two_ranges)
expect_equal("both executable sections are code ranges"
    "${_two_ranges}" "00001000:00002000;00003000:00003800")

# ---------------------------------------------------------------------------
# Export table: functions, exported data, a vftable, a forwarder, a NONAME.
# ---------------------------------------------------------------------------
set(_exports "Microsoft (R) COFF/PE Dumper Version 14.38.33133.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file oechem-5.0.0.0.dll

File Type: DLL

  Section contains the following exports for oechem-5.0.0.0.dll

    00000000 characteristics
    FFFFFFFF time date stamp
        0.00 version
           1 ordinal base
           6 number of functions
           6 number of names

    ordinal hint RVA      name

          1    0 0005B4C0 ?OEAddExplicitHydrogens@OEChem@@YA_NAEAVOEMolBase@1@@Z
          2    1 005C4120 ??_7OEMol@OEChem@@6B@
          3    2 0005C100 ?OEWriteMolecule@OEChem@@YA_NAEAVoemolostream@1@@Z
          4    3          ?OEThrowErrorHandler@OESystem@@YAXXZ (forwarded to oesystem-5.0.0.0.?OEThrowErrorHandler@OESystem@@YAXXZ)
          5    4 0076A010 ?OEDefaultErrorLevel@OESystem@@3HA
          6    5 0005D000 [NONAME]

  Summary

        1000 .00cfg
       1B000 .data
")

openeye_def_from_exports(
    EXPORTS_TEXT "${_exports}"
    CODE_RANGES ${_ranges}
    LIBRARY_NAME "oechem-5.0.0.0.dll"
    OUTPUT_VARIABLE _def
)

# Only the LIBRARY statement and the export list are asserted; the leading
# comment lines are free text.
string(REGEX REPLACE "^(;[^\n]*\n)+" "" _def_body "${_def}")
expect_equal("def body" "${_def_body}" "LIBRARY \"oechem-5.0.0.0.dll\"
EXPORTS
    ?OEAddExplicitHydrogens@OEChem@@YA_NAEAVOEMolBase@1@@Z
    ??_7OEMol@OEChem@@6B@ DATA
    ?OEWriteMolecule@OEChem@@YA_NAEAVoemolostream@1@@Z
    ?OEThrowErrorHandler@OESystem@@YAXXZ
    ?OEDefaultErrorLevel@OESystem@@3HA DATA
")

# No ordinals anywhere: binding by ordinal would break on any DLL rebuild,
# because OpenEye numbers exports alphabetically by name.
# An ordinal binding is " @<n>" after the name; a mangled name's own "@"
# never follows whitespace.
if(_def MATCHES "[ \t]@[0-9]+")
    message(SEND_ERROR "FAIL: generated def binds exports by ordinal")
    set(_fail TRUE)
endif()

# ---------------------------------------------------------------------------
# With no code ranges at all, every export must be conservatively DATA
# rather than silently classified as a function.
# ---------------------------------------------------------------------------
openeye_def_from_exports(
    EXPORTS_TEXT "${_exports}"
    LIBRARY_NAME "oechem-5.0.0.0.dll"
    OUTPUT_VARIABLE _def_no_ranges
)
string(REGEX MATCHALL "DATA" _data_marks "${_def_no_ranges}")
list(LENGTH _data_marks _n_data)
expect_equal("every RVA export is DATA when no code range is known" "${_n_data}" "4")

if(_fail)
    message(FATAL_ERROR "FAIL: Windows import-library parsing assertions failed")
endif()

message(STATUS "PASS: Windows import-library parsing satisfied")
