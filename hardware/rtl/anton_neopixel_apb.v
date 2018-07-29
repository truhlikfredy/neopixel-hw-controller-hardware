`include "anton_common.vh"

module anton_neopixel_apb (
  input clk10mhz,
  output neoData,
  output neoState,
  output pixelsSync,

  input apbPenable,
  input [31:0]apbPaddr,  // LED data + control registers
  input [7:0]apbPwData,
  input apbPclk,
  input apbPselx,
  input apbPresern,
  input apbPwrite,

  output [7:0]apbPrData,
  output apbPready,
  output apbPslverr
  );

  parameter  PIXELS_MAX  = 66;  // maximum number of LEDs in a strip
  localparam PIXELS_BITS = `CLOG2(PIXELS_MAX);   // minimum required amount of bits to store the PIXELS_MAX + 32bit aligned accesses

  wire wr_enable;
  wire rd_enable;
  wire [PIXELS_BITS-1:0]address; // correct address packed down from 32bit aligned access to 8bit access

  assign apbPready  = 1'd1;      // always ready, never delaying with a waiting state
  assign apbPslverr = 1'd0;      // never report errors
  
  assign wr_enable = (apbPenable && apbPwrite && apbPselx);
  assign rd_enable = (!apbPwrite && apbPselx);
  assign address   = apbPaddr[PIXELS_BITS + 2 - 1:2];  // 4 bytes (word) aligned to 1 byte aligned

  anton_neopixel_raw #(
    .PIXELS_MAX(PIXELS_MAX)
  ) neopixel(
    .clk10mhz(clk10mhz),
    .neoData(neoData),
    .neoState(neoState),
    .pixelsSync(pixelsSync),
    .busAddr(address),
    .busDataIn(apbPwData),
    .busClk(apbPclk),
    .busWrite(wr_enable),
    .busRead(rd_enable),
    .busDataOut(apbPrData)
  );

endmodule