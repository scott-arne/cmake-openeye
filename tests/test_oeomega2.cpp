#include <oeomega2.h>
#include <iostream>

int main() {
    unsigned int version = OEConfGen::OEOmegaGetVersion();
    std::cout << "OEOmega2 OK (version: " << version << ")" << std::endl;
    return 0;
}
