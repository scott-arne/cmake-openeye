#include <oebio.h>
#include <iostream>

int main() {
    unsigned int version = OEBio::OEBioGetVersion();
    const char *release = OEBio::OEBioGetRelease();
    std::cout << "OEBio OK (version: " << version << ", release: " << release << ")" << std::endl;

    OEBio::OEDesignUnit du;
    std::cout << "OEDesignUnit instantiated OK" << std::endl;
    return 0;
}
