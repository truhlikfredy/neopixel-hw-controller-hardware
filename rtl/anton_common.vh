
`ifndef _anton_common_vh_
`define _anton_common_vh_

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