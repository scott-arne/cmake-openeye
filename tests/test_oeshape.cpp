#include <oeshape.h>
#include <iostream>

int main() {
    unsigned int version = OEShape::OEShapeGetVersion();
    const char *release = OEShape::OEShapeGetRelease();
    std::cout << "OEShape OK (version: " << version << ", release: " << release << ")" << std::endl;

    OEShape::OEOverlay overlay;
    std::cout << "OEOverlay instantiated OK" << std::endl;
    return 0;
}
