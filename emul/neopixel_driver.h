#ifndef ANTON_NEOPIXEL_DRIVER
#define ANTON_NEOPIXEL_DRIVER

#include <stdint.h>

// comment out to remove the selftest features
#define NEOPIXEL_SELFTEST

#define NEOPIXEL_CTRL_BIT ((uint16_t)(1 << 15))
#define NEOPIXEL_CTRL_BIT_MASK (~(uint16_t)(1 << 15))

// Because this driver is used in emulation as well the enum class feature
// of C++11 can't be used because of verilator limitations. Wrapping enum
// into struct so it will not polute the namespace.
struct NeoPixelCtrl {
  typedef enum { 
    NONE   = 0,
    INIT   = 1, 
    LIMIT  = 2, 
    RUN    = 4, 
    LOOP   = 8, 
    MODE32 = 16
  } Type;
};

struct NeoPixelReg {
  typedef enum {
    MAX_LOW  = 0,
    MAX_HIGH = 1,
    CTRL     = 2,
    STATE    = 3,
    BUFFER   = 4
  } Type;
};

#ifdef NEOPIXEL_SELFTEST
#define SELFTEST_MAX_COLORS 9

const uint8_t neopixel_selftest_colors[SELFTEST_MAX_COLORS] = {
    0xff, 0x02, 0x18,
    0xDE,  // this shouldn't get displayed in 32bit mode
    0xCE, 0xAD, 0x98,
    0x01,  // this shouldn't get displayed in 32bit mode
    0x00};
#endif

class NeoPixelDriver {
 private:
  uint32_t base;
  uint16_t pixels;

  void writeRegister(NeoPixelReg::Type, uint8_t value);

  void writeRegisterMasked(NeoPixelReg::Type addr,
                           uint8_t mask,
                           uint8_t value);

  uint8_t readRegister(NeoPixelReg::Type addr);

 public:
  NeoPixelDriver(uint32_t base, uint16_t pixels);
  NeoPixelDriver(uint32_t base);

  void initHardware();
  void cleanBuffers();
  void cleanBuffer(uint8_t buffer);

  void     setPixelLength(uint16_t pixels);
  uint16_t getPixelLength();
  // void setPixel(uint32_t color);
  // void setPixel(uint8_t red, uint8_t green, uint8_t blue);
  // void setPixelRaw(uint32_t color);

  // TODO: Peripheral reset (with wait)

  // TODO: Pixel words
  void    writePixelByte(uint16_t pixel, uint8_t value);
  uint8_t readPixelByte(uint16_t pixel);

  void     writeRegisterMax(uint16_t value);
  uint16_t readRegisterMax();

  void    writeRegisterCtrl(uint8_t value);
  void    writeRegisterCtrlMasked(uint8_t mask, uint8_t value);
  uint8_t readRegisterCtrl();
  uint8_t testRegisterCtrl(uint8_t mask);

  uint8_t readRegisterState();

  void waitForSafeBuffer();

  void updateLeds();
  void syncUpdateLeds();

  // self test methods
#ifdef NEOPIXEL_SELFTEST
  void selfTestPopulatePixelBuffer();
  void selfTestMaxRegister();
  void selfTestSwitchBuffer();
  void selfTestSoftLimit32bit();
  void selfTestHardLimit8bit();
  void selfTestSoftLimit8bitLoop();
#endif
};

#endif