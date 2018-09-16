#include <iostream>

#include "neopixel_driver.h"
#include "neopixel_hal.h"
#include "test_helper.h"

NeoPixelDriver::NeoPixelDriver(uint32_t base, uint32_t pixels) {
  this->base = base;
  this->pixels = pixels;
}

void NeoPixelDriver::setPixelLength(uint16_t pixels) {}

void NeoPixelDriver::writeRegister(NeoPixelReg::Type addr, uint8_t data) {
  neopixelWriteApbByte((uint16_t)(addr) << 2 | NEOPIXEL_CTRL_BIT, data);
}

uint8_t NeoPixelDriver::readRegister(NeoPixelReg::Type addr) {
  return (neopixelReadApbByte((uint16_t)(addr) << 2 | NEOPIXEL_CTRL_BIT));
}

void NeoPixelDriver::writePixelByte(uint16_t pixel, uint8_t value) {
  neopixelWriteApbByte(pixel << 2 & NEOPIXEL_CTRL_BIT_MASK, value);
}

uint8_t NeoPixelDriver::readPixelByte(uint16_t addr) {
  return (neopixelReadApbByte(addr << 2 & NEOPIXEL_CTRL_BIT_MASK));
}

void NeoPixelDriver::writeRegisterMax(uint16_t value) {
  writeRegister(NeoPixelReg::MAX_LOW, value & 0xFF);
  writeRegister(NeoPixelReg::MAX_HIGH, (value >> 8) & 0xFF);
}

uint16_t NeoPixelDriver::readRegisterMax() {
  return ((uint16_t)(readRegister(NeoPixelReg::MAX_LOW)) |
          (uint16_t)(readRegister(NeoPixelReg::MAX_HIGH)) << 8);
}

void NeoPixelDriver::writeRegisterCtrl(uint8_t value) {
  writeRegister(NeoPixelReg::CTRL, value);
}

uint8_t NeoPixelDriver::readRegisterCtrl() {
  return (readRegister(NeoPixelReg::CTRL));
}

uint8_t NeoPixelDriver::testRegisterCtrl(uint8_t mask) {
  return (readRegister(NeoPixelReg::CTRL) & mask);
}

uint8_t NeoPixelDriver::readRegisterState() {
  return (readRegister(NeoPixelReg::STATE));
}

void NeoPixelDriver::updateLeds() {
  this->writeRegisterCtrl(NeoPixelCtrl::RUN | this->readRegisterCtrl());
}

void NeoPixelDriver::syncUpdateLeds() {
  neopixelSyncUpdate();
}

/******************** SELF TEST IMPLEMENTATION **********************/
#ifdef NEOPIXEL_SELFTEST

void NeoPixelDriver::selfTest1populatePixelBuffer() {
  // write color values into the buffer
  for (uint32_t i = 0; i < SELFTEST_MAX_COLORS; i++) {
    this->writePixelByte(i, neopixel_selftest_colors[i]);
  }

  // read it back and verify if they match
  for (uint32_t i = 0; i < SELFTEST_MAX_COLORS; i++) {
    if (this->readPixelByte(i) != neopixel_selftest_colors[i]) {
      std::cout << "Pixel data @" << i << " doesn't match actual "
                << this->readPixelByte(i) << " != expected "
                << neopixel_selftest_colors[i] << std::endl;

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
  this->writeRegisterCtrl(NeoPixelCtrl::MODE32 | NeoPixelCtrl::LIMIT);
  this->updateLeds();

  testTimeoutStart(3000); // 3ms timeout
  while (this->readRegisterState() == 0) {
    // Wait to end stream and start reset
    testAssertEquals<bool>("Finished before timeout", false,
                           testTimeoutIsExpired(), false);

    testWait();
  }

  testAssertEquals<uint8_t>("After stream phase the reset part started",
                            1, this->readRegisterState());

  // Wait for the reset to finish (stream phase + reset phase = whole cycle)
  testTimeoutStart(3000);  // 3ms timeout
  while (this->testRegisterCtrl(NeoPixelCtrl::RUN)) {
    // Wait for the cycle to finish
    testAssertEquals<bool>("Finished before timeout", false,
                           testTimeoutIsExpired(), false);

    testAssertEquals<bool>("At the reset phase the neoData was kept low",
                           false, readNeoData(), false);

    testWait();
  }

  testWait(2);
}

void NeoPixelDriver::selfTest4hardLimit8bit() {
  this->writeRegisterCtrl(NeoPixelCtrl::NONE);
  this->updateLeds();

  testTimeoutStart(3000);
  while (this->testRegisterCtrl(NeoPixelCtrl::RUN)) {
    testAssertEquals<bool>("Finished before timeout", false,
                           testTimeoutIsExpired(), false);

    testWait();  // Wait for the next cycle to finish
  }
}

void NeoPixelDriver::selfTest5softLimit8bitLoop() {
  this->writeRegisterCtrl(NeoPixelCtrl::LOOP | NeoPixelCtrl::LIMIT);
  this->syncUpdateLeds();

  // Iterate until simulation is finished or enough time passed.
  testTimeoutStart(3000);
  while (!testIsFinished()) {
    testAssertEquals<bool>("Finished before timeout", false,
                           testTimeoutIsExpired(), false);

    testWait();
  }
}

#endif