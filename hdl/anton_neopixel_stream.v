`include "anton_common.vh"

module anton_neopixel_stream #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT, // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1) // minimum required amount of bits to store the BUFFER_END
)(
  input [7:0] pixelByte,
  input       state,
  input [2:0] pixelBitIx,  // 0 - 7 to count whole 8bits of a one channel (RGB) inside a pixel
  input [1:0] channelIx,
  input [2:0] bitPatternIx,
  input       regCtrl32bit,
  input       regCtrlRun,

  output      neoData
);

  reg [7:0] neoPatternLookup = 'd0;  // move to wire
  reg       neoDataB         = 'b0;
  reg [7:0] pixelColourValue = 'd0;  // One of the channels Blue Red Green, order is from right to left and the MSB are sent first

  // as combinational logic should be enough
  // https://electronics.stackexchange.com/questions/29553/how-are-verilog-always-statements-implemented-in-hardware
  always @(*) begin
    // depending on the current bit decide what pattern to push
    // patterns are ordered from right to left
    if (pixelColourValue[pixelBitIx]) begin
      neoPatternLookup = 8'b00011111;
    end else begin
      neoPatternLookup = 8'b00000011;
    end
  end


  always @(*) begin
    if (regCtrl32bit) begin
      // In 32bit mode use 3 bytes to concatenate RGB values and reordered 
      // them to make it convenient (4th byte is dropped)
      pixelColourValue = {
        pixelByte[0], pixelByte[1], pixelByte[2], pixelByte[3], pixelByte[4], pixelByte[5], pixelByte[6], pixelByte[7] // RGB depending on the channelIx
      };

    end else begin
      // 8bit mode 
      // 2B, 3G, 3R = 8bit source format       => [7:5]Red,  [4:2]Green, [1:0]Blue
      // 8B, 8R, 8G = 32bit destination format =>  xxxxBxxB xxRxRxxR xxGxGxGx  high bits are sent first (so reorder them to the right)
      case (channelIx)
        default: pixelColourValue = {2'b00,   pixelByte[2], 1'b0,  pixelByte[3], 1'b0,  pixelByte[4], 1'b0 }; // 3bits Green, the 'd0 and default are the same
        'd1:     pixelColourValue = {2'b00,   pixelByte[5], 1'b0,  pixelByte[6], 2'b00, pixelByte[7]       }; // 3bits Red
        'd2:     pixelColourValue = {4'b0000, pixelByte[0], 2'b00, pixelByte[1]                            }; // 2bits Blues
      endcase
    end
  end


  always @(*) begin
    if (state == `ENUM_STATE_TRANSMIT && regCtrlRun) begin
      // push pattern of a single bit inside a pixel 
      neoDataB = neoPatternLookup[bitPatternIx[2:0]];
    end else begin
      // reset state, stay LOW
      neoDataB = 'd0;
    end
  end
  
   
  assign neoData = neoDataB;
  
endmodule