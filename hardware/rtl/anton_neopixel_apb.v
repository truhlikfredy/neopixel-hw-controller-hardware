
module anton_neopixel_apb (
  input clk10mhz,
  output neoData,
  output neoState,

  input apbPenable,
  input [7:0]apbPaddr,
  input [7:0]apbPwData,
  input apbPclk,
  input apbPselx,
  input apbPresern,
  input apbPwrite,

  output [7:0]apbPrData,
  output apbPready,
  output apbPslverr
  );

  wire wr_enable;
  wire rd_enable;
  wire [7:0]address;

  assign apbPready  = 1'd1;   // always ready, never delaying with a waiting state
  assign apbPslverr = 1'd0;   // never report errors
  
  assign wr_enable = (apbPenable && apbPwrite && apbPselx);
  assign rd_enable = (!apbPwrite && apbPselx);
  assign address   = { 2'd00, apbPaddr[7:2] };  // 4 bytes (word) aligned to 1 byte aligned

  anton_neopixel_raw neopixel(
    .clk10mhz(clk10mhz),
    .neoData(neoData),
    .neoState(neoState),
    .busAddr(address),
    .busDataIn(apbPwData),
    .busClk(apbPclk),
    .busWrite(wr_enable),
    .busRead(rd_enable),
    .busDataOut(apbPrData)
  );

endmodule