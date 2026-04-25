#include <oesitehopper.h>
#include <iostream>

int main() {
    unsigned int version = OESiteHopper::OESiteHopperGetVersion();
    std::cout << "OESiteHopper OK (version: " << version << ")" << std::endl;
    return 0;
}
