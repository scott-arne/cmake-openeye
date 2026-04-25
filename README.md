# cmake-openeye

Shared CMake modules for C++ projects that depend on the [OpenEye](https://www.eyesopen.com/) scientific toolkits. These modules handle library discovery, imported target creation, and SWIG-based Python binding generation.

## Requirements

- CMake 3.16 or later
- SWIG 4.0 or later (for Python bindings only)
- Python 3.10 or later (for Python bindings only)
- zlib (system)

## Installation

Add this repository as a Git submodule or copy the `.cmake` files into your project, then append the directory to `CMAKE_MODULE_PATH`:

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/external/cmake-openeye")
```

## Modules

### FindOpenEye

Locates an OpenEye C++ toolkit installation and creates modern CMake imported targets with correct dependency chains.

#### Variables

Set one of the following to point to your OpenEye installation:

| Variable | Description |
|---|---|
| `OPENEYE_ROOT` / `OE_DIR` | Root directory of the OpenEye installation (environment variable or CMake variable) |
| `OPENEYE_LIB_DIR` | Explicit path to the library directory, useful when libraries live outside the standard install tree (e.g., from the `openeye-toolkits` Python package) |

#### Options

| Option | Default | Description |
|---|---|---|
| `OPENEYE_USE_SHARED` | `OFF` | Prefer shared libraries (`.dylib`/`.so`) over static (`.a`). Set to `ON` when building wheels that depend on `openeye-toolkits`. |

#### Imported Targets

Linking against a target automatically pulls in its transitive dependencies.

| Target | Required | Dependencies |
|---|---|---|
| `OpenEye::OEChem` | Yes | `OpenEye::OESystem`, `OpenEye::OEMath` |
| `OpenEye::OESystem` | Yes | `OpenEye::OEPlatform` |
| `OpenEye::OEPlatform` | Yes | `OpenEye::zstd` (if available), `ZLIB::ZLIB` |
| `OpenEye::OEMath` | Yes | `OpenEye::OESystem` |
| `OpenEye::OEGraphSim` | No | `OpenEye::OEChem` |
| `OpenEye::OEMedChem` | No | `OpenEye::OEChem` |
| `OpenEye::OEFizzChem` | No | `OpenEye::OEChem` |
| `OpenEye::OEGrid` | No | `OpenEye::OESystem`, `OpenEye::OEFizzChem` (if available) |
| `OpenEye::OEBio` | No | `OpenEye::OEChem`, `OpenEye::OEGrid` (if available) |
| `OpenEye::zstd` | No | -- |
| `OpenEye::OEOpt` | No | `OpenEye::OESystem` |
| `OpenEye::OEMolPotential` | No | `OpenEye::OEChem`, `OpenEye::OEOpt` |
| `OpenEye::OEHermite` | No | `OpenEye::OEChem`, `OpenEye::OEOpt` |
| `OpenEye::OEShape` | No | `OpenEye::OEChem`, `OpenEye::OEBio`, `OpenEye::OEGrid`, `OpenEye::OEOpt`, `OpenEye::OEMolPotential`, `OpenEye::OEHermite` |
| `OpenEye::OEZap` | No | `OpenEye::OEChem`, `OpenEye::OEGrid` |
| `OpenEye::OESpicoli` | No | `OpenEye::OEChem`, `OpenEye::OEZap`, `OpenEye::OEBio` |
| `OpenEye::OESiteHopper` | No | `OpenEye::OEChem`, `OpenEye::OEShape`, `OpenEye::OESpicoli` |
| `OpenEye::OEMMFF` | No | `OpenEye::OEChem`, `OpenEye::OEMolPotential` |
| `OpenEye::OEFF` | No | `OpenEye::OEChem` |
| `OpenEye::OESzybki` | No | `OpenEye::OEChem`, `OpenEye::OEMMFF`, `OpenEye::OEFF`, `OpenEye::OEBio` |
| `OpenEye::OEQuacpac` | No | `OpenEye::OEChem`, `OpenEye::OESzybki` |
| `OpenEye::OEOmega2` | No | `OpenEye::OEChem`, `OpenEye::OEMMFF` |
| `OpenEye::OESheffield` | No | `OpenEye::OEChem`, `OpenEye::OEMolPotential`, `OpenEye::OEFizzChem`, `OpenEye::OEGrid`, `OpenEye::OEZap` |
| `OpenEye::OESpruce` | No | `OpenEye::OEChem`, `OpenEye::OEBio`, `OpenEye::OESiteHopper` (+ `OEQuacpac`, `OEMMFF`, `OEOmega2`, `OESheffield` on SDK 2025+) |
| `OpenEye::OEDepict` | No | `OpenEye::OEChem` |
| `OpenEye::OEIUPAC` | No | `OpenEye::OEChem` |

#### Result Variables

| Variable | Description |
|---|---|
| `OpenEye_FOUND` | `TRUE` if the required libraries were found |
| `OpenEye_VERSION` | Library version string (e.g., `4.3.0.1`) |
| `OpenEye_LIBRARY_TYPE` | `SHARED` or `STATIC` |
| `OpenEye_Bio_FOUND` | `TRUE` if OEBio was found |
| `OpenEye_GraphSim_FOUND` | `TRUE` if OEGraphSim was found |
| `OpenEye_MedChem_FOUND` | `TRUE` if OEMedChem was found |
| `OpenEye_Grid_FOUND` | `TRUE` if OEGrid was found |
| `OpenEye_SDK_MAJOR` | Detected marketing year (e.g., `2025`); drives OESpruce dep-graph selection |

#### Basic Usage

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/external/cmake-openeye")

find_package(OpenEye REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE OpenEye::OEChem)
```

### FindOpenEyePython

Auto-discovers OpenEye shared libraries from an installed `openeye-toolkits` Python package. It queries the Python environment at configure time and sets `OPENEYE_LIB_DIR` and `OPENEYE_USE_SHARED` so that `FindOpenEye` can locate the shared libraries without manual path configuration.

`Python3_EXECUTABLE` must be available before calling this module. Call `find_package(Python3 COMPONENTS Interpreter)` first.

#### Result Variables

| Variable | Description |
|---|---|
| `OpenEyePython_FOUND` | `TRUE` if `openeye-toolkits` was found |
| `OpenEyePython_LIB_DIR` | Absolute path to the shared library directory |
| `OpenEyePython_VERSION` | Marketing version (e.g., `2025.2.1`) |
| `OpenEyePython_PLATFORM` | Platform subdirectory name (e.g., `osx-arm64-14-clang-15.0`) |

#### Usage

```cmake
find_package(Python3 COMPONENTS Interpreter REQUIRED)
find_package(OpenEyePython REQUIRED)
find_package(OpenEye REQUIRED)  # OPENEYE_LIB_DIR is now set automatically
```

### OpenEyeSWIG

Provides the `openeye_add_swig_module()` function, which encapsulates the full SWIG Python extension build pipeline: SWIG/Python discovery, stable ABI support, platform-specific linking, RPATH configuration, post-build copies for editable installs, install rules, and `_build_info.py` generation.

#### Function Signature

```cmake
openeye_add_swig_module(
    NAME <name>
    SWIG_FILE <file>
    LINK_LIBS <libs...>
    PYTHON_OUTPUT_DIR <dir>
    [STABLE_ABI <bool>]
    [SWIG_FLAGS <flags...>]
    [COMPILE_DEFS <defs...>]
    [EXTRA_INSTALL_TARGETS <targets...>]
    [EXPECTED_LIB_VARS <vars...>]
    [INIT_PY <path>]
)
```

#### Parameters

| Parameter | Required | Description |
|---|---|---|
| `NAME` | Yes | Module name. The SWIG target is named `<name>_python` and the output module is `_<name>`. |
| `SWIG_FILE` | Yes | Path to the `.i` SWIG interface file. |
| `LINK_LIBS` | Yes | Libraries to link. The first entry is treated as the primary project library and is copied alongside the extension. |
| `PYTHON_OUTPUT_DIR` | Yes | Directory where the built module and wrapper are copied after each build (for editable installs). |
| `STABLE_ABI` | No | When `ON`, compiles with `Py_LIMITED_API` targeting Python 3.10+. Default: `OFF`. |
| `SWIG_FLAGS` | No | Additional flags passed to the SWIG compiler. |
| `COMPILE_DEFS` | No | Additional preprocessor definitions for the extension module. |
| `EXTRA_INSTALL_TARGETS` | No | Additional CMake targets to install alongside the extension. |
| `EXPECTED_LIB_VARS` | No | CMake variables holding paths to OpenEye shared libraries. Used to populate `_build_info.py` for runtime compatibility checks. |
| `INIT_PY` | No | Path to a `__init__.py` file to install into the package directory. |

#### Usage

```cmake
include(OpenEyeSWIG)

find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
find_package(OpenEyePython REQUIRED)
find_package(OpenEye REQUIRED)

openeye_add_swig_module(
    NAME mylib
    SWIG_FILE ${CMAKE_SOURCE_DIR}/swig/mylib.i
    LINK_LIBS mylib_static OpenEye::OEChem
    PYTHON_OUTPUT_DIR ${CMAKE_SOURCE_DIR}/python/mylib
    STABLE_ABI ON
    SWIG_FLAGS -python -py3
    EXPECTED_LIB_VARS OECHEM_LIBRARY OESYSTEM_LIBRARY OEPLATFORM_LIBRARY OEMATH_LIBRARY
    INIT_PY ${CMAKE_SOURCE_DIR}/python/mylib/__init__.py
)
```

## Testing

The `tests/` directory contains a CTest suite that verifies library discovery, imported target creation, and link-order correctness for all OpenEye libraries. Each library gets its own small C++ test app, plus a combined test that links every discovered library into a single executable to catch static-library link-order issues.

### Running the Tests

```bash
cd tests
cmake --preset default
cmake --build build
ctest --test-dir build --output-on-failure
```

The default preset points `OPENEYE_ROOT` at a local toolkit installation. Override it for your environment:

```bash
cmake -B build -DOPENEYE_ROOT=/path/to/openeye/toolkits
```

You can also create a `tests/CMakeUserPresets.json` (gitignored) with your own paths.

## Platform Support

These modules support macOS and Linux. Platform-specific behavior includes:

- **macOS**: Shared library discovery uses `.dylib` extensions. RPATH is set via `@loader_path`. The SWIG extension uses `-undefined dynamic_lookup` for Python symbol resolution and is re-signed with `codesign` after RPATH patching.
- **Linux**: Shared library discovery uses `.so` extensions. RPATH is set via `$ORIGIN`. RPATH patching uses `patchelf` when available.

## License

See the repository for license details.
