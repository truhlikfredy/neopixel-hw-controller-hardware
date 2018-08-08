`include "anton_common.vh"

module anton_neopixel_stream_ctrl (
  input  clk7mhz,
  input  reg_ctrl_init,
  input  reg_ctrl_run,
  input  reg_ctrl_limit,
  input  reg_ctrl_32bit,
  input  state,
  input  [12:0] reg_max, // 13 bits in total apb is using 16 bus but -2 bit are dropped for word alignment and 1 bit used to detect control registry accesses

  output [2:0] bit_pattern_index,
  output [4:0] pixel_bit_index,
  output [BUFFER_BITS-1:0] pixel_index,
  output [BUFFER_BITS-1:0] pixel_index_max,
  output stream_output,
  output stream_reset,
  output stream_bit_of,
  output stream_pixel_of
);

  parameter  BUFFER_END  = `BUFFER_END_DEFAULT;   // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);  // minimum required amount of bits to store the BUFFER_END

  reg [2:0] bit_pattern_index = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [4:0] pixel_bit_index   = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg [BUFFER_BITS-1:0] pixel_index = {BUFFER_BITS{1'b0}};  // index to the current pixel transmitting 

  // When 32bit mode enabled use
  // index to the current pixel transmitting, adjusted depending on 32/8 bit mode
  wire [BUFFER_BITS-1:0] pixel_index_equiv = (reg_ctrl_32bit) ? {pixel_index[BUFFER_BITS-1:2], 2'b11} : pixel_index;


  assign stream_output     = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_TRANSMIT; 
  assign stream_reset      = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_RESET;

  wire   stream_pattern_of = stream_output && bit_pattern_index == 'd7;    // does sub-bit pattern overflowing
  assign stream_bit_of     = stream_pattern_of && pixel_bit_index == 'd23; // does bit index overflowing
  assign stream_pixel_of   = pixel_index_equiv == pixel_index_max;


  always @(posedge clk7mhz) begin
    if (reg_ctrl_init) begin
      // pixel_index     <= {BUFFER_BITS{1'b0}};  // TODO: undo this
      pixel_bit_index <= 'd0;  
    end
  end


  always @(posedge clk7mhz) if (stream_output) bit_pattern_index <= bit_pattern_index + 1;


  // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
  // on 'd23 => 24th bit do start on a new pixel with bit 'd0
  always @(posedge clk7mhz) if (stream_pattern_of) pixel_bit_index <= (stream_bit_of) ? 0 : pixel_bit_index +1;


  // When limit is enabled, use software limit, but when disabled use whole buffer
  // what is the rechable maximum depending on the settings
  assign pixel_index_max = (reg_ctrl_limit)? reg_max[BUFFER_BITS-1:0] : BUFFER_END;


  always @(posedge clk7mhz) begin 
    if (stream_bit_of) begin
      // Compare the index equivalent (in 32bit mode it jumps by 4bytes) if 
      // maximum buffer size was reached, but in cases the buffer size is power 
      // of 2 it will need to be by 1 bit to match the size
        if (stream_pixel_of)  begin
          // for the very last pixel overflow 0 and start reset
          pixel_index <= 'd0;
        end else begin
          // For all pixels except the last one go to the next pixel.
          // In 32bit mode increment differently than in 8bit
          pixel_index <= (reg_ctrl_32bit) ? pixel_index + 'd4 : pixel_index + 'd1;
        end
    end
  end


endmodule