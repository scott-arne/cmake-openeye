#include <oeopt.h>
#include <iostream>

int main() {
    unsigned int version = OEOpt::OEOptGetVersion();
    const char *release = OEOpt::OEOptGetRelease();
    std::cout << "OEOpt OK (version: " << version << ", release: " << release << ")" << std::endl;
    return 0;
}
