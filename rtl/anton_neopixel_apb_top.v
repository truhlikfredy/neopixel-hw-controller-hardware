`include "anton_common.vh"

// TODO: neoState should only show when debug is enabled
// TODO: enable debug on compilation time
// TODO: double buffering

module anton_neopixel_apb_top (
  input  clk7mhz,
  input  syncStart,
  output neoData,
  output neoState,

  input apbPenable,
  input [15:0]apbPaddr,  // control registers 15 + LED data 14:2 +  ignored 1:0
  input [7:0]apbPwData,
  input apbPclk,
  input apbPselx,
  input apbPresern,
  input apbPwrite,

  output [7:0]apbPrData,
  output apbPready,
  output apbPslverr
  );

  parameter  BUFFER_END = `BUFFER_END_DEFAULT; // read anton_common.vh

  wire wr_enable;
  wire rd_enable;
  wire [13:0]address; // correct address packed down from 32bit aligned access to 8bit access, will be limited to 8192 pixels

  assign apbPready  = 1'd1; // always ready, never delaying with a waiting state
  assign apbPslverr = 1'd0; // never report errors
  
  assign wr_enable = (apbPenable && apbPwrite && apbPselx);
  assign rd_enable = (!apbPwrite && apbPselx);
  assign address   = apbPaddr[15:2]; // 4 bytes (word) aligned to 1 byte aligned

  reg [2:0]  test_unit; // TODO: disable when not in simulation/debug
  
  anton_neopixel_module #(
    .BUFFER_END(BUFFER_END)
  ) neopixel(
    .clk7mhz(clk7mhz),
    .syncStart(syncStart),
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