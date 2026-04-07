#include <oechem.h>
#include <iostream>

int main() {
    unsigned int version = OEChem::OEChemGetVersion();
    const char *release = OEChem::OEChemGetRelease();
    std::cout << "OEChem OK (version: " << version << ", release: " << release << ")" << std::endl;

    OEChem::OEGraphMol mol;
    std::cout << "OEGraphMol instantiated OK" << std::endl;
    return 0;
}
