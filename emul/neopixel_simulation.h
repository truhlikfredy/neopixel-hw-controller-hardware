#ifndef ANTON_SIMULATION_UUT
#define ANTON_SIMULATION_UUT

#include "verilated_vcd_c.h"
#include "Vanton_neopixel_apb_top.h"

extern Vanton_neopixel_apb_top *uut;
extern VerilatedVcdC *tfp;
extern vluint64_t sim_time;

#endif