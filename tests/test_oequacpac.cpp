#include <oequacpac.h>
#include <iostream>

int main() {
    unsigned int version = OEProton::OEQuacPacGetVersion();
    std::cout << "OEQuacpac OK (version: " << version << ")" << std::endl;
    return 0;
}
