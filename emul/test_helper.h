#ifndef TEST_HELPER
#define TEST_HELPER

#include <string>

extern void testFailed();
extern void testWait(uint32_t time);
extern void testWait();
extern void testTimeoutStart(uint32_t microSeconds);
extern bool testTimeoutIsExpired();

extern bool readNeoData();

template <typename T>
void testAssertEquals(std::string text, T expected, T actual);

#endif