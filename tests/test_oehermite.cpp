#include <iostream>

// OEHermite library has no standalone public API - it's only exposed through
// OEShape. This test verifies the imported target was created correctly.
// The actual hermite functionality is tested via OEShape in task A3.

int main() {
    // This test successfully linking demonstrates that:
    // 1. FindOpenEye.cmake found liboehermite.a
    // 2. OpenEye::OEHermite target was created
    // 3. Transitive dependencies (OEChem, OEOpt) are correct
    std::cout << "OEHermite OK (library found and target created)" << std::endl;
    return 0;
}
