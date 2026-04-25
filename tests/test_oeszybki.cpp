#include <oeszybki.h>
#include <iostream>

int main() {
    unsigned int version = OESz::OESzybkiGetVersion();
    std::cout << "OESzybki OK (version: " << version << ")" << std::endl;
    return 0;
}
