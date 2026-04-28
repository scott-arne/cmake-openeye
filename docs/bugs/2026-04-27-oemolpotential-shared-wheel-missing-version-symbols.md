# Bug Report — OEMolPotential shared wheel .dylib is missing GetVersion/GetRelease entry points

**Date filed:** 2026-04-27
**Status:** Open. Classified as upstream OpenEye shared-library/header contract issue, not a `cmake-openeye` target-propagation bug. No CMake-side workaround is applied.
**Reporter:** cmake-openeye review session (in-session validation)
**Affects:** `openeye-toolkits` wheel 2025.2.2, shared `liboemolpotential-2.9.1.2.dylib`
**Affected downstream repos:** any consumer that links `OpenEye::OEMolPotential` in shared mode (OPENEYE_USE_SHARED=ON)
**Severity:** Medium — shared-mode full builds that include OEMolPotential fail at link time; static mode and shared mode without OEMolPotential are unaffected.

---

## Summary

The shared `liboemolpotential-2.9.1.2.dylib` shipped in the `openeye-toolkits` Python wheel does not export `OEMolPotentialGetVersion` or `OEMolPotentialGetRelease`, while the static archive `libOEMolPotential.a` in the OpenEye SDK does export them. OpenEye's C++ headers declare both functions unconditionally, so any translation unit that calls them (e.g. `cmake-openeye/tests/test_oemolpotential.cpp` and the aggregate `test_all_libraries.cpp`) links cleanly against the static archive but fails with undefined-symbol errors against the shared wheel `.dylib`.

This is an OpenEye ABI/header contract issue: headers declare symbols that only one of the two shipped library forms exports. `cmake-openeye` correctly resolves `OpenEye::OEMolPotential` to whichever form the consumer chose; there is nothing CMake can do to synthesize the missing exports.

---

## Environment

- Host: macOS (Apple Silicon or Intel — symbol gap is not host-specific on the wheel `.dylib`).
- Python: `/Users/johnss51/Applications/miniforge3/envs/main/bin/python`.
- `openeye-toolkits` wheel version: 2025.2.2.
- OpenEye SDK: `2025.2.1` (path used by `tests/CMakePresets.json` `default` preset).
- `cmake-openeye` HEAD: c60c588aee3391deb3ece79ab89cd9aed3841fa5.

---

## Reproduction

### Symbol inspection

Shared wheel `.dylib` (missing):

```
$ nm -gU /Users/johnss51/Applications/miniforge3/envs/main/lib/python3.13/site-packages/openeye/libs/python3-osx-universal-clang++/liboemolpotential-2.9.1.2.dylib | grep -E 'OEMolPotentialGetVersion|OEMolPotentialGetRelease'
ABSENT in shared
```

Static SDK archive (present):

```
$ nm -gU /Users/johnss51/Support/openeye/lib/openeye/toolkits/2025.2.1/macOS-14.8-clang++16-universal/lib/liboemolpotential.a | grep -E 'OEMolPotentialGetVersion|OEMolPotentialGetRelease'
000000000000003c T __ZN14OEMolPotential24OEMolPotentialGetReleaseEv
0000000000000000 T __ZN14OEMolPotential24OEMolPotentialGetVersionEv
```

### Failing shared-mode link

Configure in shared mode against the wheel and build the OEMolPotential test:

```
$ cmake -S cmake-openeye/tests \
        -DOPENEYE_ROOT=/Users/johnss51/Support/openeye/lib/openeye/toolkits/2025.2.1/macOS-14.8-clang++16-universal \
        -DOPENEYE_USE_SHARED=ON \
        -DOPENEYE_RUNTIME_LIB_DIR=/Users/johnss51/Applications/miniforge3/envs/main/lib/python3.13/site-packages/openeye/libs/python3-osx-universal-clang++
$ cmake --build . --target test_oemolpotential
```

Observed linker error (tail of `/tmp/oemolpotential-shared-link.log`):

```
[ 50%] Building CXX object CMakeFiles/test_oemolpotential.dir/test_oemolpotential.cpp.o
[100%] Linking CXX executable test_oemolpotential
Undefined symbols for architecture arm64:
  "OEMolPotential::OEMolPotentialGetRelease()", referenced from:
      _main in test_oemolpotential.cpp.o
  "OEMolPotential::OEMolPotentialGetVersion()", referenced from:
      _main in test_oemolpotential.cpp.o
ld: symbol(s) not found for architecture arm64
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [test_oemolpotential] Error 1
make[2]: *** [CMakeFiles/test_oemolpotential.dir/all] Error 2
make[1]: *** [CMakeFiles/test_oemolpotential.dir/rule] Error 2
make: *** [test_oemolpotential] Error 2
```

The same configure in static mode (default preset, `OPENEYE_USE_SHARED=OFF`) links successfully.

---

## Root Cause

`OpenEye::OEMolPotential` headers declare `OEMolPotentialGetVersion()` and `OEMolPotentialGetRelease()` as part of the public API. The static archive exports these symbols; the shared `.dylib` in the `openeye-toolkits` wheel does not. Consumers who choose shared linkage therefore hit unresolved symbols at link time for any call site that uses the version/release entry points.

This is visible only when `OPENEYE_USE_SHARED=ON` *and* OEMolPotential is actually linked *and* a translation unit references the version/release symbols. `cmake-openeye`'s aggregate `tests/test_all_libraries.cpp` exercises the third condition.

---

## Classification

**Not a `cmake-openeye` bug.** The module's responsibility is to resolve `OpenEye::OEMolPotential` to whichever library the consumer selected and propagate its transitive dependencies; it correctly does so. The missing exports live inside the shipped shared binary. The only way `cmake-openeye` could "fix" this would be to silently drop or rewrite call sites that use the missing symbols, which would mask an upstream defect and break any consumer that legitimately needs those symbols once upstream ships a fixed wheel.

---

## Rejected CMake-Side Workarounds

1. **Silently strip OEMolPotential from `test_all_libraries.cpp` in shared mode.** Rejected: hides the defect and gives false confidence that shared mode is fully exercised.
2. **Add a CMake check that errors out when shared mode + OEMolPotential is requested.** Rejected as part of this spec. The failure already surfaces at link time with the correct symbol names; a CMake-side error would have to duplicate upstream version knowledge and would rot the moment OpenEye ships a fixed wheel.
3. **Weak-link the missing symbols or provide local stubs.** Rejected: changes runtime semantics and would produce silently-wrong version strings in downstream wheels.

---

## Recommended Next Action

File with OpenEye: request that the shared `liboemolpotential-2.9.1.2.dylib` export `OEMolPotentialGetVersion` and `OEMolPotentialGetRelease`, matching the static archive and the header declarations. Downstream consumers may, as a temporary mitigation, avoid calling those two entry points from translation units that link the shared wheel.

---

## Open Questions

- Which `openeye-toolkits` wheel version first introduced the export gap?
- Do the Linux (`manylinux`) and Windows wheel variants exhibit the same gap, or is this macOS-only?
- Are any other OpenEye toolkits affected (e.g. OEOmega, OESzybki) or is OEMolPotential uniquely inconsistent?
- What is the supported way to query OEMolPotential version at runtime from a shared-mode wheel build?
