`include "anton_common.vh"

//`define HARDCODED_PIXELS 1

module anton_neopixel_stream (
  input [7:0]              pixels[BUFFER_END:0],
  input                    state,
  input [BUFFER_BITS-1:0]  pixel_index,     // index to the current pixel transmitting
  input [4:0]              pixel_bit_index, // 0 - 23 to count whole 24bits of a RGB pixel
  input [2:0]              bit_pattern_index,
  input                    reg_ctrl_32bit,
  input                    reg_ctrl_run,

  output                   neoData
  );

  reg [7:0]              neo_pattern_lookup = 'd0;  // move to wire
  reg                    data_int           = 'b0;
  reg [23:0]             pixel_colour_value = 'd0;  // Blue Red Green, order is from right to left and the MSB are sent first
  
  parameter  BUFFER_END  = 31;   // number of bytes counting from zero, so the size is BUFFER_END+1, maximum 8192 pixels, which should have 4Hz refresh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);   // minimum required amount of bits to store the BUFFER_END

  // as combinational logic should be enough
  // https://electronics.stackexchange.com/questions/29553/how-are-verilog-always-statements-implemented-in-hardware
  always @(*) begin
    // depending on the current bit decide what pattern to push
    // patterns are ordered from right to left
    if (pixel_colour_value[pixel_bit_index]) begin
      neo_pattern_lookup = 8'b00011111;
    end else begin
      neo_pattern_lookup = 8'b00000011;
    end
  end


  always @(*) begin
    `ifdef HARDCODED_PIXELS
      // hardcoded predefined colours for 3 pixels in a strip
      // TODO: use casez so bigger arrays could be auto filled with these values in tiling/overflow method
      case (pixel_index)
        'd0: pixel_colour_value = 24'hff00d5;
        'd1: pixel_colour_value = 24'h008800;
        'd2: pixel_colour_value = 24'h000090;
        'd3: pixel_colour_value = 24'h000010;
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
    if (state == `ENUM_STATE_TRANSMIT && reg_ctrl_run) begin
      // push pattern of a single bit inside a pixel 
      data_int = neo_pattern_lookup[bit_pattern_index[2:0]];
    end else begin
      // reset state, stay LOW
      data_int = 'd0;
    end
  end
  
   
  assign neoData    = data_int;
  
endmodule