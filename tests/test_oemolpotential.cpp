#include <oemolpotential.h>
#include <iostream>

int main() {
    unsigned int version = OEMolPotential::OEMolPotentialGetVersion();
    const char *release = OEMolPotential::OEMolPotentialGetRelease();
    std::cout << "OEMolPotential OK (version: " << version << ", release: " << release << ")" << std::endl;
    return 0;
}
