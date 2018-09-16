`include "anton_common.vh"

module anton_neopixel_stream_logic (
  input  clk7mhz,
  input  reg_ctrl_init,
  input  reg_ctrl_run,
  input  reg_ctrl_loop,
  input  reg_ctrl_limit,
  input  reg_ctrl_32bit,
  input  [12:0] reg_max, // 13 bits in total apb is using 16 bus but -2 bit are dropped for word alignment and 1 bit used to detect control registry accesses
  
  input  initSlow,
  output initSlowDone,

  output [2:0] bit_pattern_index,
  output [4:0] pixel_bit_index,
  output [BUFFER_BITS-1:0] pixel_index,
  output [BUFFER_BITS-1:0] pixel_index_max,
  output state,
  output stream_output,
  output stream_reset,
  output stream_bit_of,
  output stream_pixel_of,
  output stream_sync_of
);

  parameter  BUFFER_END  = `BUFFER_END_DEFAULT;   // read anton_common.vh
  parameter  RESET_DELAY = `RESET_DELAY_DEFAULT;  // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);  // minimum required amount of bits to store the BUFFER_END

  reg [2:0]             bit_pattern_index  = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [4:0]             pixel_bit_index    = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg [BUFFER_BITS-1:0] pixel_index        = {BUFFER_BITS{1'b0}};  // index to the current pixel transmitting 
  reg [9:0]             reset_delay_count  = 'd0;  // 10 bits can go to 1024 so should be enough to count ~500 (50us)

  reg                   state              = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg [3:0]             cycle              = 'd0;  

  reg                   initSlowDone       = 'b0;
  

  // When 32bit mode enabled use
  // index to the current pixel transmitting, adjusted depending on 32/8 bit mode
  wire [BUFFER_BITS-1:0] pixel_index_equiv = (reg_ctrl_32bit) ? {pixel_index[BUFFER_BITS-1:2], 2'b11} : pixel_index;


  assign stream_output     = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_TRANSMIT; 
  assign stream_reset      = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_RESET;

  wire   stream_pattern_of = stream_output && bit_pattern_index == 'd7;    // does sub-bit pattern overflowing
  assign stream_bit_of     = stream_pattern_of && pixel_bit_index == 'd23; // does bit index overflowing
  wire   stream_pixel_last = pixel_index_equiv == pixel_index_max;
  assign stream_pixel_of   = stream_bit_of && stream_pixel_last;


  always @(posedge clk7mhz) begin
    if (initSlow) begin
      pixel_index     <= {BUFFER_BITS{1'b0}};
      pixel_bit_index <= 'd0;  
      initSlowDone    <= 'b1; // after the init is done signal a flag
    end

    if (initSlowDone) begin
      initSlowDone    <= 'b0; // after one slow clock, it should be enough to de-assert the flag
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
        if (stream_pixel_last)  begin
          // for the very last pixel overflow 0 and start reset
          pixel_index <= 'd0;
        end else begin
          // For all pixels except the last one go to the next pixel.
          // In 32bit mode increment differently than in 8bit
          pixel_index <= (reg_ctrl_32bit) ? pixel_index + 'd4 : pixel_index + 'd1;
        end
    end
  end

  // if last pixel is reached turn into reset state
  always @(posedge clk7mhz) if (stream_pixel_of) state <= `ENUM_STATE_RESET;


  assign stream_sync_of = (reset_delay_count == RESET_DELAY);


  always @(posedge clk7mhz) begin
    if (stream_reset) begin
      // when in the reset state, count 50ns (RESET_DELAY / 10)
      reset_delay_count <= reset_delay_count + 'b1;
    end
  end


  always @(posedge clk7mhz) begin
    if (stream_sync_of) begin  
      // predefined wait in reset state was reached, let's 
      if (cycle == 'd5) $finish; // stop simulation here
      state             <= `ENUM_STATE_TRANSMIT;
      cycle             <= cycle + 'd1;
      reset_delay_count <= 'd0;
    end
  end


endmodule