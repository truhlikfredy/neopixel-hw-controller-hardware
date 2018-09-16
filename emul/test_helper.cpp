
#include <cstdlib>
#include <iostream>
#include <stdint.h>

#include "test_helper.h"

template <typename T>
void testAssertEquals(std::string text,
                      T expected,
                      T actual,
                      bool displayPass) {
  if (expected != actual) {
    std::cout << "FAILED: " << text << std::endl;
    std::cout << "Expected=" << expected << " Actual=" << actual << std::endl;
    testFailed();  // call your implementation for 'failed tests' case

    // exit with arbirtary number, making it easier to distinguish between
    // other exit codes
    exit(96);
  } else {
    if (displayPass) {
      std::cout << "PASS: " << text << std::endl;
    }
  }
}

template <typename T>
void testAssertEquals(std::string text,
                      T expected,
                      T actual) {
  testAssertEquals(text, expected, actual, true);
}
// expected usages of the template are pre-compiled so they will not be
// undefined
template void testAssertEquals<bool>(std::string text,
                                     bool expected,
                                     bool actual,
                                     bool displayPass);

template void testAssertEquals<bool>(std::string text,
                                     bool expected,
                                     bool actual);

template void testAssertEquals<uint8_t>(std::string text,
                                        uint8_t expected,
                                        uint8_t actual,
                                        bool displayPass);

template void testAssertEquals<uint8_t>(std::string text,
                                        uint8_t expected,
                                        uint8_t actual);

template void testAssertEquals<uint16_t>(std::string text,
                                         uint16_t expected,
                                         uint16_t actual,
                                         bool displayPass);

template void testAssertEquals<uint16_t>(std::string text,
                                         uint16_t expected,
                                         uint16_t actual);

template void testAssertEquals<uint32_t>(std::string text,
                                         uint32_t expected,
                                         uint32_t actual,
                                         bool displayPass);

template void testAssertEquals<uint32_t>(std::string text,
                                         uint32_t expected,
                                         uint32_t actual);
