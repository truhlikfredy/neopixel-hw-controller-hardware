`include "anton_common.vh"

// TODO: Downgrade the clock to 7MHz, allow for the 0 = 2 + 6 ticks and for 1 = 5 + 3 ticks
// in both cases they will be 8 ticks (power of 2) and simplify the counter (no logic to compare)
// needed and it will just overflow. Total time to transmit 1 pixel will be 1.14us instead 1.2us 
// so it should be faster on longer chains. To update 200 pixels will save 12uS (which is worth about 
// another 10 pixels of time)


// TODO: use bits and size properly https://stackoverflow.com/questions/13340301/size-bits-verilog

// TODO: splitup modules

// TODO: mss ready / reset signals

// TODO: idle state, writing state, ready state, do no repeately flash the content but only after finished write

// TODO: get rid if you can of the nested overflow checkers

// TODO: nodemon killall first

module anton_neopixel_raw (
  input  clk7mhz,
  output neoData,
  output neoState,
  output pixelsSync,

  input  [13:0]busAddr,
  input  [7:0]busDataIn,
  input  busClk,
  input  busWrite,
  input  busRead,
  output [7:0]busDataOut
  );

  parameter  BUFFER_END  = 31;   // number of bytes counting from zero, so the size is BUFFER_END+1, maximum 8192 pixels, which should have 4Hz refresh
  parameter  RESET_DELAY = 385; // how long the reset delay will be happening, minimum is 50us so 50/(1/7) = 350 ticks. But giving bit margin 55us => 385 ticks
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);   // minimum required amount of bits to store the BUFFER_END

  //reg [BUFFER_BITS-1:0][7:0] pixels;

  reg [7:0]              bus_data_out_buffer;
  reg [7:0]              pixels[BUFFER_END:0];
            
  reg [9:0]              reset_delay_count  = 'd0;  // 10 bits can go to 1024 so should be enough to count ~500 (50us)
  reg [2:0]              bit_pattern_index  = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [BUFFER_BITS-1:0]  pixel_index        = {BUFFER_BITS{1'b0}};  // index to the current pixel transmitting
  reg [4:0]              pixel_bit_index    = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg                    state              = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg                    pixels_synth_buf   = 'b0;
  reg [3:0]              cycle              = 'd0;  // for simulation to track few cycles of the whole process to make sure after reset nothing funny is happening

  reg [12:0]             reg_max;          // 13 bits in total apb is using 16 bus but -2 bit are dropped for word alignment and 1 bit used to detect control registry accesses
  reg                    reg_ctrl_init      = 'b0;
  reg                    reg_ctrl_limit     = 'b0; // Change this only when the pixel data are not streamed
  reg                    reg_ctrl_run       = 'b0;
  reg                    reg_ctrl_loop      = 'b0;
  reg                    reg_ctrl_32bit     = 'b0; // Change this only when the pixel data are not streamed
  reg                    reg_state_reset    = 'b0;
  
  reg                    reset_reg_ctrl_run = 'b0;
  
  
  anton_neopixel_stream #(
    .BUFFER_END(BUFFER_END)
  ) stream(
    .pixels(pixels),
    .state(state),
    .pixel_index(pixel_index),
    .pixel_bit_index(pixel_bit_index),
    .bit_pattern_index(bit_pattern_index),
    .reg_ctrl_32bit(reg_ctrl_32bit),
    .reg_ctrl_run(reg_ctrl_run),
    .neoData(neoData)
  );


  always @(posedge busClk) begin
    if (reg_ctrl_init) begin
      reg_ctrl_init   <= 'b0;
      reg_ctrl_limit  <= 'b0;
      reg_ctrl_run    <= 'b0;
      reg_ctrl_loop   <= 'b0;
      reg_ctrl_32bit  <= 'b0;
    end else begin

      // TODO: write better tester for these writes/reads
      if (busWrite) begin
        if (busAddr[13] == 'b0) begin

          // Write buffer
          pixels[busAddr[BUFFER_BITS-1:0]] <= busDataIn;
        end else begin

          // Write register
          case (busAddr[1:0])
            0: reg_max[7:0]  <= busDataIn;
            1: reg_max[12:8] <= busDataIn[4:0];
            2: {reg_ctrl_32bit, reg_ctrl_loop, reg_ctrl_run, reg_ctrl_limit, reg_ctrl_init} <= busDataIn[4:0];
          endcase
        end
      end
      if (busRead) begin
        if (busAddr[13] == 'b0) begin
          
          // Read buffer
          bus_data_out_buffer <= pixels[busAddr[BUFFER_BITS-1:0]];
        end else begin

          // Read register
          case (busAddr[1:0])
            0: bus_data_out_buffer <= reg_max[7:0];
            1: bus_data_out_buffer <= { 3'b000, reg_max[12:8]};
            2: bus_data_out_buffer <= {3'b000, reg_ctrl_32bit, reg_ctrl_loop, reg_ctrl_run, reg_ctrl_limit, reg_ctrl_init};
            3: bus_data_out_buffer <= {7'b0000000, reg_state_reset};
          endcase
        end
      end
    end
  end


  always @(posedge busClk) begin
    if (reset_reg_ctrl_run) begin
      reg_ctrl_run <= 0;
    end
  end


  wire stream_output       = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_TRANSMIT; 
  wire stream_reset        = !reg_ctrl_init && reg_ctrl_run && state == `ENUM_STATE_RESET;
  wire stream_pattern_of   = stream_output && bit_pattern_index == 'd7;    // does sub-bit pattern overflowing
  wire stream_bit_of       = stream_pattern_of && pixel_bit_index == 'd23; // does bit index overflowing


  always @(posedge clk7mhz) reset_reg_ctrl_run <= 'b0; // fall the flags eventually


  always @(posedge clk7mhz) if (stream_output) bit_pattern_index <= bit_pattern_index + 1;


  // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
  // on 'd23 => 24th bit do start on a new pixel with bit 'd0
  always @(posedge clk7mhz) if (stream_pattern_of) pixel_bit_index <= (stream_bit_of) ? 0 : pixel_bit_index +1;


  // When limit is enabled, use software limit, but when disabled use whole buffer
  // what is the rechable maximum depending on the settings
  wire [BUFFER_BITS-1:0] pixel_index_max = (reg_ctrl_limit)? reg_max[BUFFER_BITS-1:0] : BUFFER_END;


  // When 32bit mode enabled use
  // index to the current pixel transmitting, adjusted depending on 32/8 bit mode
  wire [BUFFER_BITS-1:0] pixel_index_equiv = (reg_ctrl_32bit) ? {pixel_index[BUFFER_BITS-1:2], 2'b11} : pixel_index;


  always @(posedge clk7mhz) begin 
    if (stream_bit_of) begin
      // compare the index equivalent (in 32bit mode it jumps by 4bytes) if maximum buffer size
      // was reached, but in cases the buffer size is power of 2 it will need to be by 1 bit to match 
      // the size
        if (pixel_index_equiv < pixel_index_max)  begin
          // for all pixels except the last one go to the next pixel          
          // In 32bit mode overflow slightly differently than in 8bit
          pixel_index <= (reg_ctrl_32bit) ? pixel_index + 'd4 : pixel_index + 'd1;
        end else begin
          // for the very last pixel overflow 0 and start reset
          pixel_index <= 'd0;
          state       <= `ENUM_STATE_RESET;
        end
    end
  end


  always @(posedge clk7mhz) begin
    if (reg_ctrl_init) begin
      pixel_index     <= {BUFFER_BITS{1'b0}};
      pixel_bit_index <= 'd0;  
    end
  end


  always @(posedge clk7mhz) begin
    if (stream_reset) begin
      // when in the reset state, count 50ns (RESET_DELAY / 10)
      reset_delay_count <= reset_delay_count + 'b1;
      pixels_synth_buf  <= 1;
      reg_state_reset   <= 1;

      if (reset_delay_count == RESET_DELAY) begin
        if (!reg_ctrl_loop) begin
          reset_reg_ctrl_run <= 'b1;
        end
      end

      if (reset_delay_count > RESET_DELAY) begin  
        // predefined wait in reset state was reached, let's 
        reg_state_reset   <= 'b0;
        state             <= 'd0;
        if (cycle == 'd5) $finish; // stop simulation here, went through all pixels and a reset twice
        cycle             <= cycle + 'd1;
        reset_delay_count <= 'd0;
        pixels_synth_buf  <= 'd0;
      end
    end
  end


  assign busDataOut = bus_data_out_buffer;
  assign pixelsSync = pixels_synth_buf;
  assign neoState   = state;
  
endmodule