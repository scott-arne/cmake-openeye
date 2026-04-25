#include <oeiupac.h>
#include <iostream>

int main() {
    unsigned int version = OEIUPAC::OEIUPACGetVersion();
    std::cout << "OEIUPAC OK (version: " << version << ")" << std::endl;
    return 0;
}
