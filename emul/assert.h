#ifndef SIMPLE_ASSERTIONS
#define SIMPLE_ASSERTIONS

#include <string>
#include <iostream>
#include <cstdlib>

extern void testFailed();

template <typename T>
void assert_equals(std::string text, T expected, T actual) {
  if (expected != actual) {
    std::cout << "FAILED: " << text << std::endl;
    std::cout << "Expected=" << expected << " Actual=" << actual << std::endl;
    testFailed(); // call your implementation for 'failed tests' case

    // exit with arbirtary number, making it easier to distinguish between 
    // other exit codes
    exit(96); 
  }
  else {
    std::cout << "PASS: " << text << std::endl;
  }
}

#endif