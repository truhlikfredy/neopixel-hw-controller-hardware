`include "anton_common.vh"

// TODO: Downgrade the clock to 7MHz, allow for the 0 = 2 + 6 ticks and for 1 = 5 + 3 ticks
// in both cases they will be 8 ticks (power of 2) and simplify the counter (no logic to compare)
// needed and it will just overflow. Total time to transmit 1 pixel will be 1.14us instead 1.2us 
// so it should be faster on longer chains. To update 200 pixels will save 12uS (which is worth about 
// another 10 pixels of time)

//`define HARDCODED_PIXELS 1

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

  parameter  BUFFER_END  = 7;   // number of bytes counting from zero, so the size is BUFFER_END+1, maximum 8192 pixels, which should have 4Hz refresh
  parameter  RESET_DELAY = 385; // how long the reset delay will be happening, minimum is 50us so 50/(1/7) = 350 ticks. But giving bit margin 55us => 385 ticks
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);   // minimum required amount of bits to store the BUFFER_END

  //reg [BUFFER_BITS-1:0][7:0] pixels;

  reg [7:0]              bus_data_out_buffer;
  reg [7:0]              pixels[BUFFER_END:0];
  reg [23:0]             pixel_colour_value = 'd0;  // Blue Red Green, order is from right to left and the MSB are sent first
  reg [7:0]              neo_pattern_lookup = 'd0;
            
  reg [9:0]              reset_delay_count  = 'd0;  // 10 bits can go to 1024 so should be enough to count ~500 (50us)
  reg [2:0]              bit_pattern_index  = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [BUFFER_BITS-1:0]  pixel_index        = {BUFFER_BITS{1'b0}};  // index to the current pixel transmitting
  reg [4:0]              pixel_bit_index    = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg                    state              = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg                    pixels_synth_buf   = 'b0;
  reg                    data_int           = 'b0;
  reg [1:0]              cycle              = 'd0;  // for simulation to track few cycles of the whole process to make sure after reset nothing funny is happening

  reg [15:0]             reg_max;
  reg                    reg_ctrl_init      = 'b0;
  reg                    reg_ctrl_limit     = 'b0; // Change this only when the pixel data are not streamed
  reg                    reg_ctrl_run       = 'b0;
  reg                    reg_ctrl_loop      = 'b0;
  reg                    reg_ctrl_32bit     = 'b0; // Change this only when the pixel data are not streamed
  reg                    reg_state_reset    = 'b0;
  
  reg                    reset_reg_ctrl_run = 'b0;
  
  localparam  ENUM_STATE_TRANSMIT = 0;   // If I will make SystemVerilog variant then use proper enums for this
  localparam  ENUM_STATE_RESET    = 1;


  // as combinational logic should be enough
  // https://electronics.stackexchange.com/questions/29553/how-are-verilog-always-statements-implemented-in-hardware
  always @(*) begin
    case (pixel_colour_value[pixel_bit_index])
      // depending on the current bit decide what pattern to push
      // patterns are ordered from right to left
      1'b0: neo_pattern_lookup = 8'b00000011;
      1'b1: neo_pattern_lookup = 8'b00011111;
    endcase
  end




  always @(*) begin
    `ifdef HARDCODED_PIXELS
      // hardcoded predefined colours for 3 pixels in a strip
      // TODO: use casez so bigger arrays could be auto filled with these values in tiling/overflow method
      case (pixel_index)
        'd0: pixel_colour_value = 24'hff00d5;
        'd1: pixel_colour_value = 24'h008800;
        'd2: pixel_colour_value = 24'h000090;
        default:  pixel_colour_value = 24'h101010;  // slightly light to show there might be problem in configuration
      endcase
    `else
      if (reg_ctrl_32bit) begin
        // In 32bit mode use 3 bytes to concatinate RGB values and reordered them to make it convient (4th byte is dropped)
        pixel_colour_value = { 
          pixels[{pixel_index[BUFFER_BITS-1: 2], 2'b10}], // Blue
          pixels[{pixel_index[BUFFER_BITS-1: 2], 2'b00}], // Red
          pixels[{pixel_index[BUFFER_BITS-1: 2], 2'b01}]  // Green
        };
      end else begin
        // 8bit mode
        // 2B, 3G, 3R = 8bit source format       => [7:6]Blue,  [5:3]Green, [2-0]Red
        // 8B, 8R, 8G = 32bit destination format =>  xxxxxBBx xxxxRRRx xxxxGGGx  high bits are sent first (so reorder them to the right)
        pixel_colour_value = { 
          5'b00000, pixels[pixel_index][6], pixels[pixel_index][7], 1'b0,                           // 2bits Blues
          4'b0000,  pixels[pixel_index][0], pixels[pixel_index][1], pixels[pixel_index][2], 1'b0,   // 3bits Red
          4'b0000,  pixels[pixel_index][3], pixels[pixel_index][4], pixels[pixel_index][5], 1'b0    // 3bits Green
        };
      end
    `endif
  end


  always @(*) begin
    if (state == ENUM_STATE_TRANSMIT && reg_ctrl_run) begin
      // push pattern of a single bit inside a pixel 
      data_int = neo_pattern_lookup[bit_pattern_index[2:0]];
    end else begin
      // reset state, stay LOW
      data_int = 'd0;
    end
  end


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
            1: reg_max[15:8] <= busDataIn;
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
            1: bus_data_out_buffer <= reg_max[15:8];
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
      $finish;
    end
  end

  
  always @(posedge clk7mhz) begin
    reset_reg_ctrl_run <= 'b0; // fall the flags eventually

    if (reg_ctrl_init) begin
      pixel_index     <= {BUFFER_BITS{1'b0}};
      pixel_bit_index <= 'd0;  
    end else begin
      if (reg_ctrl_run) begin
        if (state == ENUM_STATE_TRANSMIT) begin

          bit_pattern_index <= bit_pattern_index + 1;

          if (bit_pattern_index == 'd7) begin

            if (pixel_bit_index < 'd23) begin
              // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
              pixel_bit_index <= pixel_bit_index + 'b1;
            end else begin
              // on 'd23 => 24th bit do start on a new pixel with bit 'd0
              pixel_bit_index <= 'b0;

              // compare the index equivalent (in 32bit mode it jumps by 4bytes) if maximum buffer size
              // was reached, but in cases the buffer size is power of 2 it will need to be by 1 bit to match 
              // the size
              if (reg_ctrl_32bit) begin
                // In 32bit mode overflow slightly differently than in 8bit
                if ({pixel_index[BUFFER_BITS-1:2], 2'b11} < BUFFER_END)  begin
                  // for all pixels except the last one go to the next pixel
                  pixel_index <= pixel_index + 'd4;
                end else begin
                  // for the very last pixel overflow 0 and start reset
                  pixel_index <= 'd0;
                  state       <= ENUM_STATE_RESET;
                end
              end else begin
                // In 32bit mode overflow slightly differently than in 8bit
                if (pixel_index < BUFFER_END)  begin
                  // for all pixels except the last one go to the next pixel
                  pixel_index <= pixel_index + 'b1;
                end else begin
                  // for the very last pixel overflow 0 and start reset
                  pixel_index <= 'd0;
                  state       <= ENUM_STATE_RESET;
                end
              end
              
            end        
          end
        end else begin
          // when in the reset state, count 50ns (RESET_DELAY / 10)
          reset_delay_count <= reset_delay_count + 'b1;
          pixels_synth_buf  <= 1;
          reg_state_reset   <= 1;

          if (reset_delay_count > RESET_DELAY) begin  
            // predefined wait in reset state was reached, let's 
            reg_state_reset   <= 'b0;
            state             <= 'd0;
            if (cycle == 'd3) $finish; // stop simulation here, went through all pixels and a reset twice
            cycle             <= cycle + 'd1;
            reset_delay_count <= 'd0;
            pixels_synth_buf  <= 'd0;

            if (!reg_ctrl_loop) begin
              reset_reg_ctrl_run <= 'b1;
            end

          end
        end
      end
    end 
  end


  assign neoData    = data_int;
  assign neoState   = state;
  assign busDataOut = bus_data_out_buffer;
  assign pixelsSync = pixels_synth_buf;
  
endmodule