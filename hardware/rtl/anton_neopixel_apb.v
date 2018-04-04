
module anton_neopixel_apb (
  input clk10mhz,
  output neoData,
  output neoState,

  input aobPenable,
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

  assign apbPready  = 1'd0;
  assign apbPslverr = 1'd0;
  assign apbPrData  = 8'd0;

  assign wr_enable = (aobPenable && apbPwrite && apbPselx);
  assign rd_enable = (!apbPwrite && apbPselx);

  anton_neopixel_raw neopixel(
    .clk10mhz(clk10mhz),
    .neoData(neoData),
    .neoState(neoState),
    .busAddr(apbPaddr),
    .busData(apbPwData),
    .busClk(apbPclk),
    .busWrite(wr_enable) 
  );

endmodule