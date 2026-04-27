"""Assert that an abi3 SWIG extension links python3.dll and not python3XX.dll.

Invoked by CTest on Windows with the path to the built .pyd as argv[1].
Uses dumpbin (available under the MSVC dev environment) to inspect the
extension's import table.

See docs/bugs/2026-04-27-windows-stable-abi-wrong-python-dll.md.
"""
from __future__ import annotations

import re
import subprocess
import sys


def main(pyd_path: str) -> int:
    try:
        out = subprocess.check_output(
            ["dumpbin", "/dependents", pyd_path], text=True
        )
    except FileNotFoundError:
        print("FAIL: dumpbin not on PATH (MSVC dev env required)")
        return 1
    except subprocess.CalledProcessError as exc:
        print(f"FAIL: dumpbin exited {exc.returncode}")
        print(exc.output or "")
        return 1

    imports = {m.lower() for m in re.findall(r"\bpython3(?:\d+)?\.dll\b", out, flags=re.I)}
    versioned = sorted(n for n in imports if re.fullmatch(r"python3\d+\.dll", n))

    if versioned:
        print(f"FAIL: abi3 wheel must not link versioned Python DLL; found {versioned}")
        print(out)
        return 1

    if "python3.dll" not in imports:
        print("FAIL: abi3 wheel must link python3.dll")
        print(out)
        return 1

    print("PASS: extension imports python3.dll only")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
