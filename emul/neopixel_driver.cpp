#include "neopixel_driver.h"
#include "neopixel_hal.h"

NeoPixelDriver::NeoPixelDriver(uint32_t base, uint32_t pixels) {
  this->base   = base;
  this->pixels = pixels;
}

void NeoPixelDriver::writeRegister(uint16_t addr, uint8_t data) {
  neopixelWriteApbByte(addr | 1 << 15, data);
}

uint8_t NeoPixelDriver::readRegister(uint16_t addr) {
  return (neopixelReadApbByte(addr | 1 << 15));
}

// TODO: use enum for the offsets
void NeoPixelDriver::writeRegisterMax(uint16_t value) {
  writeRegister(0, value & 0xFF);
  writeRegister(4, (value >> 8) & 0xFF);
}

void NeoPixelDriver::writeRegisterCtrl(uint8_t value) {
  writeRegister(8, value);
}

uint8_t NeoPixelDriver::readRegisterCtrl() {
  return (readRegister(8));
}

void NeoPixelDriver::setPixelLength(uint16_t pixels) {
}

uint8_t NeoPixelDriver::testRegisterCtrl(uint8_t mask) {
  return (readRegister(8) & mask);
}

void NeoPixelDriver::syncStart() {
  neopixelSyncStart();
}
