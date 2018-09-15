#ifndef ANTON_NEOPIXEL_DRIVER
#define ANTON_NEOPIXEL_DRIVER

#include <stdint.h>

#define NEOPIXEL_CTRL_BIT ((uint16_t)(1 << 15))
#define NEOPIXEL_CTRL_BIT_MASK (~(uint16_t)(1 << 15))

// Because this driver is used in emulation as well the enum class feature
// of C++11 can't be used because of verilator limitations. Wrapping enum
// into struct so it will not polute the namespace.
struct NeoPixelCtrl {
  typedef enum { 
    INIT   = 1, 
    LIMIT  = 2, 
    RUN    = 4, 
    LOOP   = 8, 
    MODE32 = 16 
  } Type;
};

// TODO hide this behind define
#define SELFTEST_MAX_COLORS 9

const uint8_t colors[SELFTEST_MAX_COLORS] = {
    0xff, 0x02, 0x18,
    0xDE,  // this shouldn't get displayed in 32bit mode
    0xCE, 0xAD, 0x98,
    0x01,  // this shouldn't get displayed in 32bit mode
    0x00};

class NeoPixelDriver {
 private:
  uint32_t base;
  uint32_t pixels;

  void writeRegister(uint16_t pixel, uint8_t value);
  uint8_t readRegister(uint16_t pixel);

 public:
  NeoPixelDriver(uint32_t base, uint32_t pixels);

  void setPixelLength(uint16_t pixels);
  // void setPixel(uint32_t color);
  // void setPixel(uint8_t red, uint8_t green, uint8_t blue);
  // void setPixelRaw(uint32_t color);

  // TODO: Peripheral reset

  // TODO: Pixel words
  // TODO: update/start
  void writePixelByte(uint16_t pixel, uint8_t value);
  uint8_t readPixelByte(uint16_t pixel);

  void writeRegisterMax(uint16_t value);
  uint16_t readRegisterMax();

  void writeRegisterCtrl(uint8_t value);
  uint8_t readRegisterCtrl();
  uint8_t testRegisterCtrl(uint8_t mask);

  uint8_t readRegisterState();

  void syncStart();

  // self test parts
  // TODO hide this behind define
  void selfTest1populatePixelBuffer();
  void selfTest2maxRegister();
  void selfTest3softLimit32bit();
  void selfTest4hardLimit8bit();
  void selfTest5softLimit8bitLoop();
};

#endif