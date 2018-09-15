#ifndef ANTON_NEOPIXEL_HAL
#define ANTON_NEOPIXEL_HAL

#include <stdint.h>

extern void neopixelWriteApbByte(uint32_t addr, uint8_t data);
extern uint8_t neopixelReadApbByte(uint32_t addr);
extern void neopixelSyncUpdate();

#endif