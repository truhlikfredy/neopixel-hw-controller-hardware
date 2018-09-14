#ifndef ANTON_NEOPIXEL_DRIVER
#define ANTON_NEOPIXEL_DRIVER

#include <stdint.h>

#define NEOPIXEL_CTRL_BIT       ((uint16_t)(1 << 15))
#define NEOPIXEL_CTRL_BIT_MASK (~(uint16_t)(1 << 15))

#define SELFTEST_MAX_COLORS 9

    
class NeoPixelDriver {
  private:
    uint32_t base;
    uint32_t pixels;

    const uint8_t colors[SELFTEST_MAX_COLORS] = {
      0xff,
      0x02,
      0x18,
      0xDE, // this shouldn't get displayed in 32bit mode
      0xCE,
      0xAD,
      0x98,
      0x01, // this shouldn't get displayed in 32bit mode
      0x00};

    void    writeRegister(uint16_t pixel, uint8_t value);
    uint8_t readRegister( uint16_t pixel);

  public:
    NeoPixelDriver(uint32_t base, uint32_t pixels);

    void setPixelLength(uint16_t pixels);
    // void setPixel(uint32_t color);
    // void setPixel(uint8_t red, uint8_t green, uint8_t blue);
    // void setPixelRaw(uint32_t color);
    
    // TODO: Peripheral reset

    // TODO: Pixel words
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
    void selfTest1populatePixelBuffer();
    void selfTest2maxRegister();
};

#endif