#include <oedepict.h>
#include <iostream>

int main() {
    unsigned int version = OEDepict::OEDepictGetVersion();
    std::cout << "OEDepict OK (version: " << version << ")" << std::endl;
    return 0;
}
