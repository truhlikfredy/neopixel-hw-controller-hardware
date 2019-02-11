#ifndef ANTON_NEOPIXEL_DRIVER
#define ANTON_NEOPIXEL_DRIVER

#include <stdint.h>

// comment out to remove the selftest features
#define NEOPIXEL_SELFTEST

#define NEOPIXEL_MODE_MASK    (~(uint32_t)(3 << 18))

#define NEOPIXEL_MODE_CTRL    ( (uint32_t)(3 << 18))
#define NEOPIXEL_MODE_RAW     ( (uint32_t)(2 << 18))
#define NEOPIXEL_MODE_DELTA   ( (uint32_t)(1 << 18))
#define NEOPIXEL_MODE_VIRTUAL ( (uint32_t)(0 << 18)) // In this implementation the virtual mode is 0, this will make the code portable in case the modes change

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
    MAX_LOW     = 0,
    MAX_HIGH    = 1,
    CTRL        = 2,
    STATE       = 3,
    BUFFER      = 4,
    WIDTH_LOW   = 5,
    WIDTH_HIGH  = 6,
    HEIGHT_LOW  = 7,
    HEIGHT_HIGH = 8
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
  uint16_t virtualPixels;

  void writeRegister(NeoPixelReg::Type, uint8_t value);

  void writeRegisterMasked(NeoPixelReg::Type addr,
                           uint8_t mask,
                           uint8_t value);

  uint8_t readRegister(NeoPixelReg::Type addr);
  

 public:
    NeoPixelDriver(uint32_t base, uint16_t pixels, uint16_t virtualPixels);
    NeoPixelDriver(uint32_t base, uint16_t pixels);
    NeoPixelDriver(uint32_t base);

    void initHardware();
    void cleanBuffer();
    void initDelta();

    void setPixelLength(uint16_t pixels);
    uint16_t getPixelLength();
    // void setPixel(uint32_t color);
    // void setPixel(uint8_t red, uint8_t green, uint8_t blue);
    // void setPixelRaw(uint32_t color);

    // TODO: Peripheral reset (with wait)

    // TODO: Pixel words
    void writeRawPixelByte(uint16_t pixel, uint8_t value);
    uint8_t readRawPixelByte(uint16_t addr);
    void writeVirtualPixelByte(uint16_t pixel, uint8_t value);
    void writeDelta(uint16_t index, uint16_t value);

    void writeRegisterLowHigh(NeoPixelReg::Type regLow,
                              NeoPixelReg::Type regHigh, uint16_t value);

    uint16_t readRegisterLowHigh(NeoPixelReg::Type regLow,
                                 NeoPixelReg::Type regHigh);

    void writeRegisterMax(uint16_t value);
    uint16_t readRegisterMax();

    void writeRegisterCtrl(uint8_t value);
    void writeRegisterCtrlMasked(uint8_t mask, uint8_t value);
    uint8_t readRegisterCtrl();
    uint8_t testRegisterCtrl(uint8_t mask);

    uint8_t readRegisterState();

    void waitForSafeBuffer();

    void updateLeds();
    void syncUpdateLeds();

    // self test methods
#ifdef NEOPIXEL_SELFTEST
  void selfTestPopulatePixelBuffer();
  void selfTestLowHighRegisters();
  void selfTestSwitchBuffer();
  void selfTestSoftLimit32bit();
  void selfTestHardLimit8bit();
  void selfTestSoftLimit8bitLoop();
#endif
};

#endif