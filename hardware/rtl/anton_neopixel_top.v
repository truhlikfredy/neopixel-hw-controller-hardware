
module anton_neopixel_top (
  input CLK_10MHZ,
  output NEO_DATA,
  output VERBOSE_STATE);

  parameter PIXELS_MAX  = 3; // maximum number of LEDs in a strip
  parameter PIXELS_BITS = 2; // minimum required amount of bits to store the PIXELS_MAX

  //reg [PIXELS_BITS-1:0][7:0] pixels;

  reg [23:0]             pixel_value        = 24'hff00d5;  // Blue Red Green, order is from right to left and the MSB are sent first
  reg [11:0]             neo_pattern_lookup = 'd0;
            
  reg [8:0]              reset_delay        = 'd0;  // 9 bits are enough when i need to count 500
  reg [3:0]              bit_pattern_index  = 'd0;  // counting 0 - 11
  reg [PIXELS_BITS-1:0]  pixel_index        = 'd0;  // index to the current pixel transmitting
  reg [4:0]              pixel_bit_index    = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg                    state              = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg                    data_int           = 'b0;

  parameter  enum_state_transmit = 0;   // If I will make SystemVerilog variant then use proper enums for this
  parameter  enum_state_reset    = 1;
  

  always @(pixel_value[pixel_bit_index]) begin
    case (pixel_value[pixel_bit_index])
      // depending on the current bit decide what pattern to push
      // patterns are ordered from right to left
      1'b0: neo_pattern_lookup = 12'b000000000111;
      1'b1: neo_pattern_lookup = 12'b000011111111;
    endcase
  end


  always @(pixel_index) begin
    // hardcoded predefined colors for 3 pixels in a strip
    case (pixel_index)
      'd0: pixel_value = 24'hff00d5;
      'd1: pixel_value = 24'h008800;
      'd2: pixel_value = 24'h000090;
      default:  pixel_value = 24'h101010;  // slightly light to show there might be problem in configuration
    endcase
  end


  always @(posedge CLK_10MHZ) begin
    if (state == enum_state_transmit) begin
      // push patterns of the bit inside a pixel 
      data_int = neo_pattern_lookup[bit_pattern_index];
    end else begin
      // reset state, stay LOW
      data_int = 'd0;
    end
  end


  always @(posedge CLK_10MHZ) begin
    if (state == enum_state_transmit) begin

      if (bit_pattern_index < 'd11) begin
        // from 'd0 to 'd10 => 11 sub-bit ticks increment by one
        bit_pattern_index <= bit_pattern_index + 'b1;
      end else begin
        // for the 'd11 = 12th last sub-bit start with new bit and start sub-bit ticks from beging
        bit_pattern_index <= 'b0;

        if (pixel_bit_index < 'd23) begin
          // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
          pixel_bit_index <= pixel_bit_index + 'b1;
        end else begin
          // on 'd23 => 24th bit do start on a new pixel with bit 'd0
          pixel_bit_index <= 'b0;

          if (pixel_index < PIXELS_MAX-1) begin
            // for all pixels go to the next pixel
            pixel_index <= pixel_index + 'b1;
          end else begin
            // for the very last pixel overflow 0 and start reset
            pixel_index <= 'd0;
            state <= enum_state_reset;
          end
        end        
      end
    end else begin
      // when in the reset state, count 50ns
      reset_delay <= reset_delay + 'b1;
      if (reset_delay > 500) begin
        state <= 'd0;
        $finish;                // stop simulation here, went through all pixels and 1 reset
      end
    end
  end


  assign NEO_DATA      = data_int;
  assign VERBOSE_STATE = state;
  
endmodule