#include <stdint.h>

// simulation board support package implementation for the test_helper

#include "test_helper.h"
#include "neopixel.h"
#include "neopixel_simulation.h"

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

void testWait() {
  cycleClocks();
}

// 3 simulation steps are quired to for 100ns in simulation to pass.
// Each simulation step is 25units of the counter, so 75 units of the
// counter means 100ns in time, therefore 750 counter units = 1us.
void testTimeoutStart(uint32_t microSeconds) {
  testTimeoutTime = sim_time + ((vluint64_t)(microSeconds) * 750);
}

bool testTimeoutIsExpired() {
  return(sim_time > testTimeoutTime);
}

bool readNeoData() {
  return uut->neoData;
}
