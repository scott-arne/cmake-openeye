#include <oezap.h>
#include <iostream>

int main() {
    unsigned int version = OEPB::OEZapGetVersion();
    std::cout << "OEZap OK (version: " << version << ")" << std::endl;
    return 0;
}
