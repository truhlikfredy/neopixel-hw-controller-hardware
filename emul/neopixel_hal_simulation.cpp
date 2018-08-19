#include "neopixel_hal.h"
#include "neopixel_simulation.h"


void accessApbByte(unsigned char isWrite, unsigned int addr, unsigned char *data) {
  uut->apbPenable = 1;
  uut->apbPwrite  = isWrite;
  uut->apbPselx   = 1;
  uut->apbPclk    = 0;
  uut->apbPaddr   = addr;
  if (isWrite) {
    uut->apbPwData = *data;
  }
  uut->eval();
  tfp->dump(sim_time += 25);

  uut->apbPclk = 1;
  uut->clk7mhz = uut->clk7mhz ? 0 : 1;
  uut->eval();
  tfp->dump(sim_time += 25);

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
  return(ret);
}
