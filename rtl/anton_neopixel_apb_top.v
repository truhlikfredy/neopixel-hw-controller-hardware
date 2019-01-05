`include "anton_common.vh"

// TODO: neoState should only show when debug is enabled
// TODO: enable debug on compilation time

module anton_neopixel_apb_top (
  input  clk6_4mhz,
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

  // number of bytes counting from zero, so the size is BUFFER_END+1, maximum 
  // 8192 pixels, which should have 4Hz refresh
  parameter BUFFER_END = `BUFFER_END_DEFAULT; // read anton_common.vh

  wire wrEnable;
  wire rdEnable;
  wire [13:0]address; // correct address packed down from 32bit aligned access to 8bit access, will be limited to 8192 pixels

  assign apbPready  = 1'd1; // always ready, never delaying with a waiting state
  assign apbPslverr = 1'd0; // never report errors
  
  assign wrEnable = (apbPenable && apbPwrite && apbPselx);
  assign rdEnable = (!apbPwrite && apbPselx);
  assign address  = apbPaddr[15:2]; // 4 bytes (word) aligned to 1 byte aligned

  reg [2:0]  testUnit; // TODO: disable when not in simulation/debug
  
  anton_neopixel_module #(
    .BUFFER_END(BUFFER_END)
  ) neopixel(
    .clk6_4mhz(clk6_4mhz),
    .syncStart(syncStart),
    .neoData(neoData),
    .neoState(neoState),
    .busAddr(address),
    .busDataIn(apbPwData),
    .busClk(apbPclk),
    .busWrite(wrEnable),
    .busRead(rdEnable),
    .busDataOut(apbPrData)
  );

endmodule