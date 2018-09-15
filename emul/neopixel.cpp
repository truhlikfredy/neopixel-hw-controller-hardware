#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <string>

#include "neopixel.h"
#include "neopixel_driver.h"
#include "neopixel_hal.h"
#include "neopixel_simulation.h"
#include "test_helper.h"

Vanton_neopixel_apb_top* uut;
VerilatedVcdC* tfp;
vluint64_t sim_time;
NeoPixelDriver* driver;

// 3 simulation steps are quired to for 100ns in simulation to pass.
// Each simulation step is 25units, so 75units means 100ns, therefore 750=1us.
// stop the simulation if it didn't ended after 3ms (3000us)
#define SIMULATION_NOT_STUCK (sim_time < (3000 * (75 * 10)))

double sc_time_stamp() {
  return sim_time * 50;
}

void simulationDone() {
  // Done simulating
  uut->final();

  std::cout << "Simulation finished with " << sim_time << " timestamp."
            << std::endl;

#if VM_COVERAGE
  VerilatedCov::writeLcov("lcov.info");
#endif

  tfp->close();
  delete tfp;
  delete uut;
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

void testHeader(std::string text) {
  std::cout << "---------------------------------------------" << std::endl;
  std::cout << text << std::endl;
}

void test1() {
  testHeader("Test 1 - populate buffer with values");
  uut->anton_neopixel_apb_top__DOT__test_unit = 1;

  driver->selfTest1populatePixelBuffer();
}

void test2() {
  testHeader("Test 2 - write and read back MAX register");
  uut->anton_neopixel_apb_top__DOT__test_unit = 2;

  driver->selfTest2maxRegister();
}

void test3() {
  testHeader(
      "Test 3 - run 32bit - soft limit mode with 7bytes max -> 8 bytes size "
      "(which is 2 pixels in 32bit mode)");
  uut->anton_neopixel_apb_top__DOT__test_unit = 3;

  driver->selfTest3softLimit32bit();
}

void test4() {
  testHeader(
      "Test 4 - After one run is finished switch to 8bit with hard limit mode");
  uut->anton_neopixel_apb_top__DOT__test_unit = 4;

  driver->selfTest4hardLimit8bit();
}

void test5() {
  testHeader(
      "Test 5 - Keep 8bit mode, but enable looping and software limit, and "
      "start it with a synch input");
  uut->anton_neopixel_apb_top__DOT__test_unit = 5;

  driver->selfTest5softLimit8bitLoop();
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
  uut->clk7mhz = 0;
  uut->syncStart = 0;
  uut->anton_neopixel_apb_top__DOT__test_unit = 0;

  driver = new NeoPixelDriver(0, 60);
  
  testStart();
  test1();
  test2();
  test3();
  test4();
  test5();

  // Proper end of the simulation, if the simulation was shutdown sooner, due
  // to test failure, then one indicators is that the coverage and/or
  // total simulated time dropped significantly.
  simulationDone();

  return 0;
}
