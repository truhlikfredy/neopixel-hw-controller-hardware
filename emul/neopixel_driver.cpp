#include <iostream>

#include "neopixel_driver.h"
#include "neopixel_hal.h"
#include "test_helper.h"


NeoPixelDriver::NeoPixelDriver(uint32_t base, 
                               uint16_t pixels) {
  this->base         = base;
  initHardware();
  setPixelLength(pixels);
}


NeoPixelDriver::NeoPixelDriver(uint32_t base) {
  this->base         = base;
  initHardware();
}


void NeoPixelDriver::initHardware() {
  writeRegisterCtrl(NeoPixelCtrl::INIT);
  
  // block the driver until the hardware deasserts the init flag.
  // if something is wrong with the hw this will make the firmware to freeze
  while (testRegisterCtrl(NeoPixelCtrl::INIT));
}


void NeoPixelDriver::cleanBuffers() {
  cleanBuffer(0);
  cleanBuffer(1);
}


void NeoPixelDriver::cleanBuffer(uint8_t buffer) {
  uint8_t currentBuffer = readRegister(NeoPixelReg::BUFFER);
  writeRegister(NeoPixelReg::BUFFER, buffer);

  for (uint32_t i = 0; i < pixels; i++) {
    writePixelByte(i, 0x00);
  }

  writeRegister(NeoPixelReg::BUFFER, currentBuffer);
}


void NeoPixelDriver::setPixelLength(uint16_t pixels) {
  if (testRegisterCtrl(NeoPixelCtrl::MODE32)) {
    writeRegisterMax(pixels <<2);
  } else {
    writeRegisterMax(pixels);
  }
}


uint16_t NeoPixelDriver::getPixelLength() {
  if (testRegisterCtrl(NeoPixelCtrl::MODE32)) {
    return(readRegisterMax() >> 2);
  } else {
    return(readRegisterMax());
  }
}


void NeoPixelDriver::writeRegister(NeoPixelReg::Type addr, uint8_t data) {
  neopixelWriteApbByte((uint16_t)(addr) << 2 | NEOPIXEL_CTRL_BIT, data);
}


void NeoPixelDriver::writeRegisterMasked(NeoPixelReg::Type addr,
                                         uint8_t mask,
                                         uint8_t value) {
  writeRegister(addr,(readRegister(addr) & ~mask) | (value & mask));
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


void NeoPixelDriver::writeRegisterCtrlMasked(uint8_t mask, uint8_t value) {
  writeRegisterMasked(NeoPixelReg::CTRL, mask, value);
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


void NeoPixelDriver::waitForSafeBuffer() {
  // if the double buffering will be disabled but underlying application was
  // using it as a way to synch/slow-down the application, then still this
  // function will just do that, but without switching a buffer
  if (testRegisterCtrl(NeoPixelCtrl::RUN)) {
    // if the stream is running, then wait for the reset phase to switch buffer
    while (!readRegister(NeoPixelReg::STATE));
  }
}


void NeoPixelDriver::updateLeds() {
  writeRegisterCtrl(NeoPixelCtrl::RUN | readRegisterCtrl());
}


void NeoPixelDriver::syncUpdateLeds() {
  neopixelSyncUpdate();
}


/******************** SELF TEST IMPLEMENTATION **********************/
#ifdef NEOPIXEL_SELFTEST

void NeoPixelDriver::selfTestPopulatePixelBuffer() {
  // write color values into the buffer
  for (uint32_t i = 0; i < SELFTEST_MAX_COLORS; i++) {
    writePixelByte(i, neopixel_selftest_colors[i]);
  }

  // read it back and verify if they match
  for (uint32_t i = 0; i < SELFTEST_MAX_COLORS; i++) {
    if (readPixelByte(i) != neopixel_selftest_colors[i]) {
      std::cout << "Pixel data @" << i << " doesn't match actual "
                << readPixelByte(i) << " != expected "
                << neopixel_selftest_colors[i] << std::endl;

      testFailed();
    }
  }
}


void NeoPixelDriver::selfTestMaxRegister() {
  writeRegisterMax(0x1ace);
  testAssertEquals<uint16_t>("Large value in MAX control register", 0x1ace,
                             readRegisterMax());

  writeRegisterMax(0xffff);
  testAssertEquals<uint16_t>("Overflowing value in MAX control register",
                             0x1fff, readRegisterMax());

  writeRegisterMax(7);
  testAssertEquals<uint16_t>("Small value in MAX control register", 7,
                             readRegisterMax());
}


void NeoPixelDriver::selfTestSoftLimit32bit() {
  writeRegisterCtrl(NeoPixelCtrl::MODE32 | NeoPixelCtrl::LIMIT);
  updateLeds();

  testTimeoutStart(3000); // 3ms timeout
  while (readRegisterState() == 0) {
    // Wait to end stream and start reset
    testAssertEquals<bool>("Finish before timeout", false,
                           testTimeoutIsExpired(), false);

    testWait();
  }

  testAssertEquals<uint8_t>("After stream phase the reset part started",
                            1, readRegisterState());

  // Wait for the reset to finish (stream phase + reset phase = whole cycle)
  testTimeoutStart(3000);  // 3ms timeout
  while (testRegisterCtrl(NeoPixelCtrl::RUN)) {
    // Wait for the cycle to finish
    testAssertEquals<bool>("Finish before timeout", false,
                           testTimeoutIsExpired(), false);

    testAssertEquals<bool>("At the reset phase the neoData was kept low",
                           false, readNeoData(), false);

    testWait();
  }

  testWait(2);
}


void NeoPixelDriver::selfTestHardLimit8bit() {
  writeRegisterCtrl(NeoPixelCtrl::NONE);
  updateLeds();

  testTimeoutStart(3000);
  while (testRegisterCtrl(NeoPixelCtrl::RUN)) {
    testAssertEquals<bool>("Finished before timeout", false,
                           testTimeoutIsExpired(), false);

    testWait();  // Wait for the next cycle to finish
  }
}


void NeoPixelDriver::selfTestSoftLimit8bitLoop() {
  writeRegisterCtrl(NeoPixelCtrl::LOOP | NeoPixelCtrl::LIMIT);
  syncUpdateLeds();

  // Iterate until simulation is finished or enough time passed.
  testTimeoutStart(3000);
  while (!testIsFinished()) {
    testAssertEquals<bool>("Finished before timeout", false,
                           testTimeoutIsExpired(), false);

    testWait();
  }
}


#endif