module anton_neopixel_top (
  input CLK_10MHZ,
  output NEO_DATA,
  output VERBOSE_STATE);

  reg [31:0] data        = 24'hff00d5;  // Blue Red Green, order is from right to left and the MSB are sent first
  reg [11:0] neo_lookup  = 'd0;

  reg [8:0]  counter     = 'd0;  // 9 bits are enough when i need to count 500
  reg [3:0]  bit_clk     = 'd0;  // counting 0 - 11
  reg [4:0]  bit_counter = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg [1:0]  pixel_index = 'd0;  // index to the current pixel transmitting
  reg        state       = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg        data_int    = 'b0;

  always @(data[bit_counter]) begin
    case (data[bit_counter])
      // depending on the current bit decide what pattern to push
      // patterns are ordered from right to left
      1'b0: neo_lookup = 12'b000000000111;
      1'b1: neo_lookup = 12'b000011111111;
    endcase
  end

  always @(posedge CLK_10MHZ) begin
    if (state == 'd0) begin
      // push bits of a pixel
      data_int = neo_lookup[bit_clk];
    end else begin
      // reset state
      data_int = 'd0;
    end
  end

  always @(posedge CLK_10MHZ) begin
    if (state == 'd0) begin

      if (bit_clk < 'd11) begin
        // from 'd0 to 'd10 => 11 sub-bit ticks increment by one
        bit_clk <= bit_clk + 'b1;
      end else begin
        // for the 'd11 = 12th last sub-bit start with new bit and start sub-bit ticks from beging
        bit_clk <= 'b0;

        if (bit_counter < 'd23) begin
          // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
          bit_counter <= bit_counter + 'b1;
        end else begin
          // on 'd23 => 24th bit do start on a new pixel with bit 'd0
          bit_counter <= 'b0;

          if (pixel_index < 'd1) begin
            // for all pixels go to the next pixel
            pixel_index <= pixel_index + 'b1;
          end else begin
            // for the very last pixel overflow 0 and start reset
            pixel_index <= 'd0;
            state <= 'd1;
          end
        end        
      end
    end else begin
      // when in the reset state, count 50ns
      counter <= counter + 'b1;
      if (counter > 500) begin
        state <= 'd0;
        $finish;                // stop simulation here, went through all pixels and 1 reset
      end
    end
  end

  assign NEO_DATA      = data_int;
  assign VERBOSE_STATE = state;
  
endmodule