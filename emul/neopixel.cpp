#include <verilated.h>
#include <iostream>
#include <string>
#include <cstdlib>
#include <cstdio>

#include "neopixel_simulation.h"
#include "neopixel_driver.h"
#include "neopixel_hal.h"

#define CTRL_INIT  1
#define CTRL_LIMIT 2
#define CTRL_RUN   4
#define CTRL_LOOP  8
#define CTRL_32    16

#define STATE_RESET 1
#define STATE_OFF   2

Vanton_neopixel_apb_top *uut;
VerilatedVcdC *tfp;
vluint64_t sim_time;

double sc_time_stamp () {
  return sim_time*50;
}


void cycleClocks() {
  uut->apbPclk = 0;
  uut->eval();
  tfp->dump(sim_time += 25);

  uut->apbPclk = 1;
  uut->clk7mhz = uut->clk7mhz ? 0 : 1;
  uut->eval();
  tfp->dump(sim_time += 25);
}


int main(int argc, char** argv) {
  sim_time = 0;

  Verilated::commandArgs(argc, argv);
  uut = new Vanton_neopixel_apb_top;

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  // tfp->spTrace()->set_time_unit("1ns");
  // tfp->spTrace()->set_time_resolution("1ps");
  uut->trace(tfp, 99);

  std::string vcdname = argv[0];
  vcdname += ".vcd";
  std::cout << vcdname << std::endl;
  tfp->open(vcdname.c_str());
  uut->clk7mhz   = 0;
  uut->anton_neopixel_apb_top__DOT__test_unit = 0;

  NeoPixelDriver *driver = new NeoPixelDriver(0, 60);

  neopixelWriteApbByte(0,  0xff);
  neopixelWriteApbByte(4,  0x02);
  neopixelWriteApbByte(8,  0x18);
  neopixelWriteApbByte(12, 0xDE); // this shouldn't get displayed in 32bit mode
  neopixelWriteApbByte(16, 0xCE);
  neopixelWriteApbByte(20, 0xAD);
  neopixelWriteApbByte(24, 0x98);
  neopixelWriteApbByte(28, 0x01); // this shouldn't get displayed in 32bit mode
  neopixelWriteApbByte(32, 0x00);

  driver->writeRegisterMax(0xface);
  driver->writeRegisterMax(7);

  uut->anton_neopixel_apb_top__DOT__test_unit = 1;
  driver->writeRegisterCtrl(CTRL_RUN | CTRL_32 | CTRL_LIMIT);

  // test 1 run 32bit - soft limit mode with 7bytes max -> 8 bytes size (which is 2 pixels in 32bit mode)
  while (driver->testRegisterCtrl(CTRL_RUN))
    cycleClocks(); // Wait for the cycle to finish

  cycleClocks();
  cycleClocks();

  // After one run is finished switch to 8bit with hard limit mode
  uut->anton_neopixel_apb_top__DOT__test_unit = 2;
  driver->writeRegisterCtrl(CTRL_RUN);
  while (driver->testRegisterCtrl(CTRL_RUN))
    cycleClocks(); // Wait for the next cycle to finish

  // Keep 8bit mode, but enable looping and software limit
  uut->anton_neopixel_apb_top__DOT__test_unit = 3;
  driver->writeRegisterCtrl(CTRL_RUN | CTRL_LOOP | CTRL_LIMIT);

  // Iterate until simulation is finished or enough time passed.
  // 3 simulation steps are quired to for 100ns in simulation to pass.
  // Each simulation step is 25units, so 75units means 100ns, therefore 750=1us.
  // stop the simulation if it didn't ended after 3ms (3000us)
  while (!Verilated::gotFinish() && sim_time<(3000 * (75 *10))) {
    cycleClocks();
  }

  // Done simulating
  uut->final();

  #if VM_COVERAGE
    VerilatedCov::write("lcov.info");
  #endif

  tfp->close();
  delete tfp;
  delete uut;

  return 0;
}
