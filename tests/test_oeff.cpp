#include <oeff.h>
#include <iostream>

int main() {
    unsigned int version = OEFF::OEFFGetVersion();
    std::cout << "OEFF OK (version: " << version << ")" << std::endl;
    return 0;
}
