
#include <cstdlib>
#include <iostream>

#include <stdint.h>

#include "test_helper.h"

template <typename T>
void testAssertEquals(std::string text, T expected, T actual) {
  if (expected != actual) {
    std::cout << "FAILED: " << text << std::endl;
    std::cout << "Expected=" << expected << " Actual=" << actual << std::endl;
    testFailed();  // call your implementation for 'failed tests' case

    // exit with arbirtary number, making it easier to distinguish between
    // other exit codes
    exit(96);
  } else {
    std::cout << "PASS: " << text << std::endl;
  }
}

// expected usages of the template are pre-compiled so they will not be
// undefined
template void testAssertEquals<uint16_t>(std::string text,
                                         uint16_t expected,
                                         uint16_t actual);

template void testAssertEquals<uint32_t>(std::string text,
                                         uint32_t expected,
                                         uint32_t actual);
