#include <oegraphsim.h>
#include <iostream>

int main() {
    unsigned int version = OEGraphSim::OEGraphSimGetVersion();
    const char *release = OEGraphSim::OEGraphSimGetRelease();
    std::cout << "OEGraphSim OK (version: " << version << ", release: " << release << ")" << std::endl;
    return 0;
}
