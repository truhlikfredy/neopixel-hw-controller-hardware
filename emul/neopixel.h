#ifndef NEOPIXEL_SIMULATION_MAIN
#define NEOPIXEL_SIMULATION_MAIN

#include <verilated.h>

extern vluint64_t sim_time;

#define CTRL_INIT 1
#define CTRL_LIMIT 2
#define CTRL_RUN 4
#define CTRL_LOOP 8
#define CTRL_32 16

#define STATE_RESET 1
#define STATE_OFF 2

void simulationDone();

void cycleClocks();

#endif