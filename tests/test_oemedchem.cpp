#include <oemedchem.h>
#include <iostream>

int main() {
    unsigned int version = OEMedChem::OEMedChemGetVersion();
    const char *release = OEMedChem::OEMedChemGetRelease();
    std::cout << "OEMedChem OK (version: " << version << ", release: " << release << ")" << std::endl;
    return 0;
}
