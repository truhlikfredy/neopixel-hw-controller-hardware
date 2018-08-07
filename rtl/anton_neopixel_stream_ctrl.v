`include "anton_common.vh"

module anton_neopixel_stream_ctrl (
  input  clk7mhz,
  input  reg_ctrl_init,
  input  reg_ctrl_run,
  input  reg_ctrl_32bit,
  input  state,
  input  [4:0]pixel_bit_index,


  output [2:0] bit_pattern_index_out,
  output stream_output,
  output stream_reset,
  output stream_pattern_of,
  output stream_bit_of
);

  reg [2:0]              bit_pattern_index  = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  
  assign stream_output     = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_TRANSMIT; 
  assign stream_reset      = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_RESET;
  assign stream_pattern_of = stream_output && bit_pattern_index == 'd7;    // does sub-bit pattern overflowing
  assign stream_bit_of     = stream_pattern_of && pixel_bit_index == 'd23; // does bit index overflowing

  always @(posedge clk7mhz) if (stream_output) bit_pattern_index <= bit_pattern_index + 1;


  assign bit_pattern_index_out = bit_pattern_index;


endmodule