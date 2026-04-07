#include <oegrid.h>
#include <iostream>

int main() {
    unsigned int version = OESystem::OEGridGetVersion();
    const char *release = OESystem::OEGridGetRelease();
    std::cout << "OEGrid OK (version: " << version << ", release: " << release << ")" << std::endl;
    return 0;
}
