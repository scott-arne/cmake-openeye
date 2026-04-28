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

#ifdef HAS_OEOPT
#include <oeopt.h>
#endif

#ifdef HAS_OEMOLPOTENTIAL
#include <oemolpotential.h>
#endif

#ifdef HAS_OESHAPE
#include <oeshape.h>
#endif

#ifdef HAS_OEZAP
#include <oezap.h>
#endif

#ifdef HAS_OESPICOLI
#include <oespicoli.h>
#endif

#ifdef HAS_OESITEHOPPER
#include <oesitehopper.h>
#endif

#ifdef HAS_OEMMFF
#include <oemmff.h>
#endif

#ifdef HAS_OEFF
#include <oeff.h>
#endif

#ifdef HAS_OESZYBKI
#include <oeszybki.h>
#endif

#ifdef HAS_OEQUACPAC
#include <oequacpac.h>
#endif

#ifdef HAS_OEOMEGA2
#include <oeomega2.h>
#endif

#ifdef HAS_OESHEFFIELD
#include <oesheffield.h>
#endif

#ifdef HAS_OESPRUCE
#include <oespruce.h>
#endif

#ifdef HAS_OEDEPICT
#include <oedepict.h>
#endif

#ifdef HAS_OEIUPAC
#include <oeiupac.h>
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

#ifdef HAS_OEOPT
    std::cout << "OEOpt " << OEOpt::OEOptGetVersion() << std::endl;
#endif

#ifdef HAS_OEMOLPOTENTIAL
    std::cout << "OEMolPotential " << OEMolPotential::OEMolPotentialGetVersion() << std::endl;
#endif

#ifdef HAS_OESHAPE
    std::cout << "OEShape " << OEShape::OEShapeGetVersion() << std::endl;
#endif

#ifdef HAS_OEZAP
    std::cout << "OEZap " << OEPB::OEZapGetVersion() << std::endl;
#endif

#ifdef HAS_OESPICOLI
    std::cout << "OESpicoli " << OESpicoli::OESpicoliGetVersion() << std::endl;
#endif

#ifdef HAS_OESITEHOPPER
    std::cout << "OESiteHopper " << OESiteHopper::OESiteHopperGetVersion() << std::endl;
#endif

#ifdef HAS_OEMMFF
    OEMolMMFF::OEMMFF94sParams mmff_params;
    std::cout << "OEMMFF params OK" << std::endl;
#endif

#ifdef HAS_OEFF
    std::cout << "OEFF " << OEFF::OEFFGetVersion() << std::endl;
#endif

#ifdef HAS_OESZYBKI
    std::cout << "OESzybki " << OESz::OESzybkiGetVersion() << std::endl;
#endif

#ifdef HAS_OEQUACPAC
    std::cout << "OEQuacpac " << OEProton::OEQuacPacGetVersion() << std::endl;
#endif

#ifdef HAS_OEOMEGA2
    std::cout << "OEOmega2 " << OEConfGen::OEOmegaGetVersion() << std::endl;
#endif

#ifdef HAS_OESHEFFIELD
    OESheff::OESheffieldOptions sheffield_options;
    std::cout << "OESheffield options OK" << std::endl;
#endif

#ifdef HAS_OESPRUCE
    std::cout << "OESpruce " << OESpruce::OESpruceGetVersion() << std::endl;
#endif

#ifdef HAS_OEDEPICT
    std::cout << "OEDepict " << OEDepict::OEDepictGetVersion() << std::endl;
#endif

#ifdef HAS_OEIUPAC
    std::cout << "OEIUPAC " << OEIUPAC::OEIUPACGetVersion() << std::endl;
#endif

    std::cout << "All libraries linked successfully" << std::endl;
    return 0;
}
