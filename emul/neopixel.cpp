#include <verilated.h>
#include <iostream>
#include <string>
#include <cstdlib>
#include <cstdio>

#include "verilated_vcd_c.h"

#include "Vanton_neopixel_apb.h"

#define CTRL_INIT  1
#define CTRL_LIMIT 2
#define CTRL_RUN   4
#define CTRL_LOOP  8
#define CTRL_32    16

#define STATE_RESET 1
#define STATE_OFF   2

Vanton_neopixel_apb *uut;
vluint64_t sim_time = 0;
VerilatedVcdC *tfp;

double sc_time_stamp () {
  return sim_time*50;
}

void writeApbByte(unsigned int addr, unsigned char data) {
  uut->apbPenable = 1;
  uut->apbPwrite  = 1;
  uut->apbPselx   = 1;
  uut->apbPclk    = 0;
  uut->apbPaddr   = addr;
  uut->apbPwData  = data;
  uut->eval();
  tfp->dump(sim_time += 25);

  uut->apbPclk   = 1;
  uut->clk7mhz   = uut->clk7mhz ? 0 : 1;
  uut->eval();
  tfp->dump(sim_time += 25);

  // on next eval they will be low if they will not be raised in the meantime
  uut->apbPenable = 0;
  uut->apbPwrite  = 0;
  uut->apbPselx   = 0;
}

void writeRegister(unsigned int addr, unsigned char data) {
  writeApbByte(addr | 1<<15, data);
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  uut = new Vanton_neopixel_apb;

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

  writeRegister(0, 0xde);
  writeRegister(4, 0xad);
  writeRegister(0, 0xfa);
  writeRegister(4, 0xce);
  writeRegister(8, CTRL_RUN | CTRL_LOOP);
  // writeRegister(8, CTRL_RUN);

  writeApbByte(0, 0xff);
  writeApbByte(4, 0x02);
  writeApbByte(8, 0x18);

  while (!Verilated::gotFinish())
  {
    uut->apbPclk = 0;
    uut->eval();
    tfp->dump(sim_time += 25);

    uut->apbPclk = 1;
    uut->clk7mhz = uut->clk7mhz ? 0 : 1;
    uut->eval();
    tfp->dump(sim_time += 25);
  }

  uut->final();               // Done simulating

  tfp->close();
  delete tfp;
  delete uut;

  return 0;
}
