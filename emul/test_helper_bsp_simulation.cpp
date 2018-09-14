#include <stdint.h>

// simulation board support package implementation for the test_helper

#include "test_helper.h"
#include "neopixel.h"

extern void simulationDone();
extern void cycleClocks();

vluint64_t testTimeoutTime;

void testFailed() { 
  simulationDone(); 
}

void testWait(uint32_t time) {
  for (uint32_t i=0; i<time; i++) {
    cycleClocks();
  }
}

void testTimeoutStart(uint32_t timeout) {
  testTimeoutTime = sim_time + timeout;
}

bool testTimeoutIsExpired() {
  return(sim_time > testTimeoutTime);
}
