#include <oespicoli.h>
#include <iostream>

int main() {
    unsigned int version = OESpicoli::OESpicoliGetVersion();
    std::cout << "OESpicoli OK (version: " << version << ")" << std::endl;
    return 0;
}
