#include <oespruce.h>
#include <iostream>

int main() {
    unsigned int version = OESpruce::OESpruceGetVersion();
    std::cout << "OESpruce OK (version: " << version << ")" << std::endl;

    OESpruce::OEStructureMetadata meta;
    std::cout << "OEStructureMetadata instantiated OK" << std::endl;
    return 0;
}
