`include "anton_common.vh"

// TODO: neoState should only show when debug is enabled
// TODO: enable debug on compilation time

module anton_neopixel_apb_top #(
  // number of bytes counting from zero, so the size is BUFFER_END+1, maximum 
  // 8192 bytes (8192 pixels in 8bit mode and 2048 pixels in 32bit mode), which should have ~4Hz refresh
  parameter BUFFER_END = `BUFFER_END_DEFAULT, // read anton_common.vh

  // How long the reset delay will be happening, minimum spec is so 
  // 50us => 50000ns/(1/6.4) = 320 000 ticks. But some arrays need bit more:
  // 81us => 81000ns/(1/6.4) = 518 400 ticks
  parameter RESET_DELAY = `RESET_DELAY_DEFAULT
)(
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

//  output [7:0]tpWD,
// input  [7:0]tpRD,
//  output [9:0]tpWAddr,
// output [9:0]tpRAddr,
// output tpWEn,
// output tpREn
);
  wire wrEnable;
  wire rdEnable;
  wire [13:0]address; // correct address packed down from 32bit aligned access to 8bit access, will be limited to 8192 pixels

  assign apbPready  = 1'd1; // always ready, never delaying with a waiting state
  assign apbPslverr = 1'd0; // never report errors
  
  assign wrEnable = (apbPenable && apbPwrite && apbPselx);
  assign rdEnable = (!apbPwrite && apbPselx);
  assign address  = apbPaddr[15:2]; // 4 bytes (word) aligned to 1 byte aligned, 16bit addr but only 14bits are used

  reg [2:0]  testUnit; // TODO: disable when not in simulation/debug

/*
  #reg [7:0]tpWDB;
 # reg [9:0]tpWAddrB;
#  reg [9:0]tpRAddrB;
  #reg tpWEnB = 0;
 # reg tpREnB = 0;

#  reg [1:0] writeState = 0;

  #always @(posedge apbPclk) begin
 #   case (writeState)
#      'd0: begin
     #   if (wrEnable) begin 
    #      writeState = 1;
   #       tpWAddrB = address[9:0];
  #        tpWDB = apbPrData;
 #       end
#      end

      #'d1: begin
     #   writeState = 2;
    #    tpWEnB = 1;
   #   end

  #    'd2: begin
 #       writeState = 3;
#      end

     # 'd3: begin
    #    writeState = 0;
   #   end
  #  endcase

 # end

#  assign tpWD    = tpWDB;
#  assign tpWAddr = tpWAddrB;
#  assign tpRAddr = tpRAddrB;
  #assign tpWEn   = tpWEnB;
#  assign tpREn   = tpREnB;
  */
  anton_neopixel_module #(
    .BUFFER_END(`SANITIZE_BUFFER_END(BUFFER_END))
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