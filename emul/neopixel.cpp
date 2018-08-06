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

void accessApbByte(unsigned char isWrite, unsigned int addr, unsigned char* data) {
  uut->apbPenable = 1;
  uut->apbPwrite  = isWrite;
  uut->apbPselx   = 1;
  uut->apbPclk    = 0;
  uut->apbPaddr   = addr;
  if (isWrite) {
    uut->apbPwData  = *data;
  }
  uut->eval();
  tfp->dump(sim_time += 25);

  uut->apbPclk    = 1;
  uut->clk7mhz    = uut->clk7mhz ? 0 : 1;
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

void writeApbByte(unsigned int addr, unsigned char data) {
  accessApbByte(1, addr, &data);
}

unsigned char readApbByte(unsigned int addr) {
  unsigned char ret;
  accessApbByte(0, addr, &ret);
  return(ret);
}

void writeRegister(unsigned int addr, unsigned char data) {
  writeApbByte(addr | 1<<15, data);
}

unsigned char readRegister(unsigned int addr) {
  return(readApbByte(addr | 1 << 15));
}

void writeRegisterMax(unsigned int value) {
  writeRegister(0, value & 0xFF);
  writeRegister(4, (value >> 8) & 0xFF);
}

void writeRegisterCtrl(unsigned char value) {
  writeRegister(8, value);
}

unsigned char readRegisterCtrl() {
  return(readRegister(8));
}

unsigned char testRegisterCtrl(unsigned char mask) {
  return(readRegister(8) & mask);
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

  writeApbByte(0,  0xff);
  writeApbByte(4,  0x02);
  writeApbByte(8,  0x18);
  writeApbByte(12, 0xDE); // this shouldn't get displayed in 32bit mode
  writeApbByte(16, 0xCE);
  writeApbByte(20, 0xAD);
  writeApbByte(16, 0x98);
  writeApbByte(20, 0x01); // this shouldn't get displayed in 32bit mode
  writeApbByte(24, 0x00);

  writeRegisterMax(0xface);
  writeRegisterMax(7);
  writeRegisterCtrl(CTRL_RUN | CTRL_32 | CTRL_LIMIT);

  // test 1 run 32bit - soft limit mode with 7bytes max -> 8 bytes size (which is 2 pixels in 32bit mode)
  while (testRegisterCtrl(CTRL_RUN)) cycleClocks(); // Wait for the cycle to finish

  cycleClocks();
  cycleClocks();

  // After one run is finished switch to 8bit with hard limit mode
  writeRegisterCtrl(CTRL_RUN);
  while (testRegisterCtrl(CTRL_RUN)) cycleClocks(); // Wait for the next cycle to finish

  // Keep 8bit mode, but enable looping and software limit
  writeRegisterCtrl(CTRL_RUN | CTRL_LOOP | CTRL_LIMIT);

  // Iterate until simulation is finished
  while (!Verilated::gotFinish()) cycleClocks();

  // Done simulating
  uut->final();               

  tfp->close();
  delete tfp;
  delete uut;

  return 0;
}
