#include <stdint.h>

// simulation board support package implementation for the test_helper

#include "test_helper.h"
#include "neopixel_simulation.h"

vluint64_t testTimeoutTime;

void testStart() {
  // in simulation we don't have to do much now, in hardware you want to
  // start reading timer so you know when simulation should be finished
}

bool testIsFinished() {
  return Verilated::gotFinish();
}

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

// TODO align simulation time with real time if you can
// 3 simulation steps are required to for 100ns in simulation to pass.
// which would be 6.4ns in real life.
// Each simulation step is 25units of the counter, so 75 units of the
// counter means 100ns in time, therefore 1172 counter units = 1us.
void testTimeoutStart(uint32_t microSeconds) {
  testTimeoutTime = sim_time + ((vluint64_t)(microSeconds) * 1172);
}

bool testTimeoutIsExpired() {
  return(sim_time > testTimeoutTime);
}

bool readNeoData() {
  return uut->neoData;
}
