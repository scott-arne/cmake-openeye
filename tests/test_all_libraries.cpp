#include <oechem.h>
#include <iostream>

#ifdef HAS_OEBIO
#include <oebio.h>
#endif

#ifdef HAS_OEGRAPHSIM
#include <oegraphsim.h>
#endif

#ifdef HAS_OEMEDCHEM
#include <oemedchem.h>
#endif

#ifdef HAS_OEGRID
#include <oegrid.h>
#endif

/// Combined link-order test.
///
/// Links against every discovered OpenEye library in a single translation
/// unit. If the imported targets declare their INTERFACE_LINK_LIBRARIES
/// incorrectly, or if CMake emits the libraries in the wrong order on
/// the linker command line, this test will fail with undefined symbols.
int main() {
    // Required: OEChem (transitively pulls OESystem, OEMath, OEPlatform, zstd, zlib)
    OEChem::OEGraphMol mol;
    unsigned int chem_ver = OEChem::OEChemGetVersion();
    std::cout << "OEChem " << chem_ver << std::endl;

#ifdef HAS_OEBIO
    OEBio::OEDesignUnit du;
    std::cout << "OEBio " << OEBio::OEBioGetVersion() << std::endl;
#endif

#ifdef HAS_OEGRAPHSIM
    std::cout << "OEGraphSim " << OEGraphSim::OEGraphSimGetVersion() << std::endl;
#endif

#ifdef HAS_OEMEDCHEM
    std::cout << "OEMedChem " << OEMedChem::OEMedChemGetVersion() << std::endl;
#endif

#ifdef HAS_OEGRID
    std::cout << "OEGrid " << OESystem::OEGridGetVersion() << std::endl;
#endif

    std::cout << "All libraries linked successfully" << std::endl;
    return 0;
}
