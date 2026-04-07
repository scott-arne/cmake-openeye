#include <oeplatform.h>
#include <iostream>
#include <string>

int main() {
    std::string release = OEPlatform::OEToolkitsGetRelease();
    std::cout << "OEPlatform OK (toolkits release: " << release << ")" << std::endl;
    return 0;
}
