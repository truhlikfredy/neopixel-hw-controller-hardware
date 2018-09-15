#include <iostream>

#include "neopixel_driver.h"
#include "neopixel_hal.h"
#include "test_helper.h"


NeoPixelDriver::NeoPixelDriver(uint32_t base, uint32_t pixels) {
  this->base = base;
  this->pixels = pixels;
}

void NeoPixelDriver::setPixelLength(uint16_t pixels) {}

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
  return ((uint16_t)(readRegister(0)) | (uint16_t)(readRegister(1)) << 8);
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

/******************** SELF TEST IMPLEMENTATION **********************/

void NeoPixelDriver::selfTest1populatePixelBuffer() {
  // write color values into the buffer
  for (uint32_t i = 0; i < SELFTEST_MAX_COLORS; i++) {
    this->writePixelByte(i, colors[i]);
  }

  // read it back and verify if they match
  for (uint32_t i = 0; i < SELFTEST_MAX_COLORS; i++) {
    if (this->readPixelByte(i) != colors[i]) {
      std::cout << "Pixel data @" << i << " doesn't match actual "
                << this->readPixelByte(i) << " != expected " << colors[i]
                << std::endl;

      testFailed();
    }
  }
}

void NeoPixelDriver::selfTest2maxRegister() {
  this->writeRegisterMax(0x1ace);
  testAssertEquals<uint16_t>("Large value in MAX control register", 0x1ace,
                             this->readRegisterMax());

  this->writeRegisterMax(0xffff);
  testAssertEquals<uint16_t>("Overflowing value in MAX control register",
                             0x1fff, this->readRegisterMax());

  this->writeRegisterMax(7);
  testAssertEquals<uint16_t>("Small value in MAX control register", 7,
                             this->readRegisterMax());
}

void NeoPixelDriver::selfTest3softLimit32bit() {
  this->writeRegisterCtrl(NeoPixelCtrl::RUN | NeoPixelCtrl::MODE32 | NeoPixelCtrl::LIMIT);

  testTimeoutStart(3000); // 3ms timeout
  while (this->readRegisterState() == 0) {
    // Wait to end stream and start reset
    if (testTimeoutIsExpired()) 
      testFailed();

    testWait();
  }

  if (this->readRegisterState() != 1) {
    std::cout << "ERROR: After stream phase the reset part should started."
              << std::endl;

    std::cout << "ERROR: Possibly the loop timeouted and never left from the "
                 "stream phase."
              << std::endl;
              
    testFailed();
  }

  // Wait for the reset to finish (stream phase + reset phase = whole cycle)
  testTimeoutStart(3000);  // 3ms timeout
  while (this->testRegisterCtrl(NeoPixelCtrl::RUN)) {
    // Wait for the cycle to finish
    if (testTimeoutIsExpired()) 
      testFailed();

    if (readNeoData() != 0) {
      // inside the reset part the output should be held low
      std::cout << "ERROR: At the reset phase the neoData was not kept low"
                << std::endl;
      testFailed();
    }

    testWait();
  }

  testWait(2);
}

void NeoPixelDriver::selfTest4hardLimit8bit() {
  this->writeRegisterCtrl(NeoPixelCtrl::RUN);

  testTimeoutStart(3000);
  while (this->testRegisterCtrl(NeoPixelCtrl::RUN)) {
    if (testTimeoutIsExpired())
      testFailed();

    testWait();  // Wait for the next cycle to finish
  }
}

void NeoPixelDriver::selfTest5softLimit8bitLoop() {
  this->writeRegisterCtrl(NeoPixelCtrl::LOOP | NeoPixelCtrl::LIMIT);
  this->syncStart();

  // Iterate until simulation is finished or enough time passed.
  testTimeoutStart(3000);
  while (!testIsFinished()) {
    if (testTimeoutIsExpired())
      testFailed();

    testWait();
  }
}