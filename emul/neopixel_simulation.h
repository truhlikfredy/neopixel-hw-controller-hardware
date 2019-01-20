#ifndef NEOPIXEL_SIMULATION_MAIN
#define NEOPIXEL_SIMULATION_MAIN

#include <verilated.h>
#include "Vanton_neopixel_apb_top.h"
#include "verilated_vcd_c.h"

// when to kill the simulator to prevent running in infinite loops
#define SIMULATION_HARD_LIMIT (45000*1172)


extern Vanton_neopixel_apb_top* uut;
extern VerilatedVcdC* tfp;
extern vluint64_t sim_time;

void simulationDone();

void cycleClocks();

void simulationHardLimitReached();

#endif