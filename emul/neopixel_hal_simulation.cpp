#include "neopixel_hal.h"
#include "neopixel_simulation.h"

void evalStep() {
  if (sim_time > SIMULATION_HARD_LIMIT) {
    simulationHardLimitReached();
  }
  
  uut->apbPclk = uut->apbPclk ? 0 : 1;
  if (uut->apbPclk) {
    // on positive apbPclk cycle the 7mhz clock
    uut->clk6_4mhz = uut->clk6_4mhz ? 0 : 1;
  }

  uut->eval();
  tfp->dump(sim_time += 25);
}

void accessApbByte(unsigned char isWrite,
                   unsigned int addr,
                   unsigned char* data) {
  uut->apbPenable  = 1;
  uut->apbPwrite   = isWrite;
  uut->apbPselx    = 1;
  uut->apbPaddr    = addr;
  if (isWrite) {
    uut->apbPwData = *data;
  }

  // eval 2 Pclk clocks and one 7MHz clock
  // ensuring they will start at PClk 0 as the eval step inverses previous step
  uut->apbPclk = 1;
  evalStep();
  evalStep();

  if (!isWrite) {
    *data = uut->apbPrData;
  }

  // on next eval they will be low if they will not be raised in the meantime
  uut->apbPenable = 0;
  uut->apbPwrite  = 0;
  uut->apbPselx   = 0;
}

void neopixelWriteApbByte(unsigned int addr, unsigned char data) {
  accessApbByte(1, addr, &data);
}

unsigned char neopixelReadApbByte(unsigned int addr) {
  unsigned char ret;
  accessApbByte(0, addr, &ret);
  return (ret);
}

void neopixelSyncUpdate() {
  uut->syncStart = 1;
  uut->apbPclk = 1;
  // wait whole pos and down edge step
  evalStep();
  evalStep();
  uut->syncStart = 0;
}
