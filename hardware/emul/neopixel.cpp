#include <verilated.h>
#include <iostream>
#include <string>
#include <cstdlib>
#include <cstdio>

#include "verilated_vcd_c.h"

#include "Vanton_neopixel_apb.h"

Vanton_neopixel_apb *uut;
vluint64_t sim_time = 0;

double sc_time_stamp () {
  return sim_time*50;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  uut = new Vanton_neopixel_apb;

  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  // tfp->spTrace()->set_time_unit("1ns");
  // tfp->spTrace()->set_time_resolution("1ps");
  uut->trace(tfp, 99);

  std::string vcdname = argv[0];
  vcdname += ".vcd";
  std::cout << vcdname << std::endl;
  tfp->open(vcdname.c_str());
  uut->clk10mhz = 0;

  while (!Verilated::gotFinish()) {
    uut->clk10mhz = uut->clk10mhz ? 0 : 1;
    uut->eval();
    tfp->dump (sim_time);

    sim_time+=50;   // 50ns per half of the 10MHz clock (2 sim ticks = 1 time tick0
  }

  uut->final();               // Done simulating

  tfp->close();
  delete tfp;
  delete uut;

  return 0;
}
