
`ifndef _anton_common_vh_
`define _anton_common_vh_

// number of bytes counting from zero, so the size is BUFFER_END+1, maximum 8192
// pixels, which should have 4Hz refresh reason why it's not buffer size is 
// because the verilator is akward and for size which are power of 2 was 
// expecting 1 bit bigger VARREF even when the number was subtracted
`define BUFFER_END_DEFAULT 31


// how long the reset delay will be happening, minimum is 50us so 50/(1/7) = 350
// ticks. But giving bit margin 55us => 385 ticks
`define RESET_DELAY_DEFAULT 2100

// https://stackoverflow.com/questions/5269634/address-width-from-ram-depth
`define CLOG2(x) \
  (x <= 2) ? 1 : \
  (x <= 4) ? 2 : \
  (x <= 8) ? 3 : \
  (x <= 16) ? 4 : \
  (x <= 32) ? 5 : \
  (x <= 64) ? 6 : \
  (x <= 128) ? 7 : \
  (x <= 256) ? 8 : \
  (x <= 512) ? 9 : \
  (x <= 1024) ? 10 : \
  (x <= 2048) ? 11 : \
  (x <= 4096) ? 12 : \
  (x <= 8192) ? 13 : \
  -1


`define IS_POWER_OF2(x) ( \
  x == 2    || x == 4    || x == 8   || x == 16  || x == 32   || \
  x == 64   || x == 128  || x == 256 || x == 512 || x == 1024 || \
  x == 2048 || x == 4096 || x == 8192 \
  ) ? 1 : 0


// If I will make SystemVerilog variant then use proper enums for this
`define ENUM_STATE_TRANSMIT 1'b0  
`define ENUM_STATE_RESET    1'b1


`endif