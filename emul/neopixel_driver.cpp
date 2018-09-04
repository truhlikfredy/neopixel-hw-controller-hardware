#include "neopixel_driver.h"
#include "neopixel_hal.h"

NeoPixelDriver::NeoPixelDriver(uint32_t base, uint32_t pixels) {
  this->base   = base;
  this->pixels = pixels;
}

void NeoPixelDriver::setPixelLength(uint16_t pixels) {
}

void NeoPixelDriver::writeRegister(uint16_t addr, uint8_t data) {
  neopixelWriteApbByte(addr << 2 | NEOPIXEL_CTRL_BIT, data);
}

uint8_t NeoPixelDriver::readRegister(uint16_t addr) {
  return (neopixelReadApbByte(addr << 2 | NEOPIXEL_CTRL_BIT));
}

void NeoPixelDriver::writePixelByte(uint16_t pixel, uint8_t value) {
  neopixelWriteApbByte(pixel << 2 & NEOPIXEL_CTRL_BIT_MASK, value);
}

uint8_t NeoPixelDriver::readPixelByte(uint16_t addr) {
  return (neopixelReadApbByte(addr << 2 & NEOPIXEL_CTRL_BIT_MASK));
}

// TODO: use enum for the offsets
void NeoPixelDriver::writeRegisterMax(uint16_t value) {
  writeRegister(0, value & 0xFF);
  writeRegister(1, (value >> 8) & 0xFF);
}

uint16_t NeoPixelDriver::readRegisterMax() {
  return ( (uint16_t)(readRegister(0)) | (uint16_t)(readRegister(1)) << 8 );
}

void NeoPixelDriver::writeRegisterCtrl(uint8_t value) {
  writeRegister(2, value);
}

uint8_t NeoPixelDriver::readRegisterCtrl() {
  return (readRegister(2));
}

uint8_t NeoPixelDriver::testRegisterCtrl(uint8_t mask) {
  return (readRegister(2) & mask);
}

uint8_t NeoPixelDriver::readRegisterState() {
  return (readRegister(3));
}

void NeoPixelDriver::syncStart() {
  neopixelSyncStart();
}
