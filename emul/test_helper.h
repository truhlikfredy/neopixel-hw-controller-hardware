#ifndef TEST_HELPER
#define TEST_HELPER

#include <string>

extern void testFailed();
extern void testTimeoutStart(uint32_t timeout);
extern bool testTimeoutIsExpired();

template <typename T>
void testAssertEquals(std::string text, T expected, T actual);

#endif