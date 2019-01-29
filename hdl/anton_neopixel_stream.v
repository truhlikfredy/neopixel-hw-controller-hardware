`include "anton_common.vh"

//TODO: Index naming could shortened to Ix and Buf to B (or use SV and do not use buf at all)

module anton_neopixel_stream #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT, // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1) // minimum required amount of bits to store the BUFFER_END
)(
  input [7:0]              pixels[BUFFER_END:0],
  input                    state,
  input [BUFFER_BITS-1:0]  pixelIndex,     // index to the current pixel transmitting
  input [2:0]              pixelBitIndex,  // 0 - 7 to count whole 8bits of a one channel (RGB) inside a pixel
  input [1:0]              channelIndex,
  input [2:0]              bitPatternIndex,
  input                    regCtrl32bit,
  input                    regCtrlRun,

  output                   neoData
);

  reg [7:0] neoPatternLookup = 'd0;  // move to wire
  reg       neoDataBuf       = 'b0;
  reg [7:0] pixelColourValue = 'd0;  // One of the channels Blue Red Green, order is from right to left and the MSB are sent first

  // Pixel values for 32bit RGB mode
  wire [7:0] pChannel = pixels[{pixelIndex[BUFFER_BITS-1:2], channelIndex}][7:0];

  // as combinational logic should be enough
  // https://electronics.stackexchange.com/questions/29553/how-are-verilog-always-statements-implemented-in-hardware
  always @(*) begin
    // depending on the current bit decide what pattern to push
    // patterns are ordered from right to left
    if (pixelColourValue[pixelBitIndex]) begin
      neoPatternLookup = 8'b00011111;
    end else begin
      neoPatternLookup = 8'b00000011;
    end
  end


  always @(*) begin
    `ifdef HARDCODED_PIXELS
      // hardcoded predefined colours for 3 pixels in a strip
      // TODO: use casez so bigger arrays could be auto filled with these 
      // values in tiling/overflow method
      case ({pixelIndex, channelIndex})
        'd0:      pixelColourValue = 8'hff;
        'd1:      pixelColourValue = 8'h00;
        'd2:      pixelColourValue = 8'hd5;

        'd4:      pixelColourValue = 8'h00;
        'd5:      pixelColourValue = 8'h88;
        'd6:      pixelColourValue = 8'h00;

        'd8:      pixelColourValue = 8'h00;
        'd9:      pixelColourValue = 8'h00;
        'd10:     pixelColourValue = 8'h90;

        'd11:     pixelColourValue = 8'h00;
        'd12:     pixelColourValue = 8'h00;
        'd13:     pixelColourValue = 8'h10;

        default:  pixelColourValue = 8'h10; // slightly light to show there might be problem in configuration
      endcase
    `else
      if (regCtrl32bit) begin
        // In 32bit mode use 3 bytes to concatenate RGB values and reordered 
        // them to make it convenient (4th byte is dropped)
        pixelColourValue = {
          pChannel[0], pChannel[1], pChannel[2], pChannel[3], pChannel[4], pChannel[5], pChannel[6], pChannel[7] // RGB depending on the channelIndex
        };

      end else begin
        // 8bit mode, to calculate inside speed calc: hex( (Red >> 5) + ((Green >> 5) << 3 ) +  ((Blue >> 6) << 6) )
        // 2B, 3G, 3R = 8bit source format       => [7:6]Blue,  [5:3]Green, [2:0]Red
        // 8B, 8R, 8G = 32bit destination format =>  xxxxBxxB xxRxRxxR xxGxGxGx  high bits are sent first (so reorder them to the right)
        case (channelIndex)
          default; pixelColourValue = {2'b00,   pixels[pixelIndex][3], 1'b0,  pixels[pixelIndex][4], 1'b0,  pixels[pixelIndex][5], 1'b0 }; // 3bits Green
          'd1:     pixelColourValue = {4'b0000, pixels[pixelIndex][6], 2'b00, pixels[pixelIndex][7]                                     }; // 2bits Blues
          'd2:     pixelColourValue = {2'b00,   pixels[pixelIndex][0], 1'b0,  pixels[pixelIndex][1], 2'b00, pixels[pixelIndex][2]       }; // 3bits Red
        endcase
      end
    `endif
  end


  always @(*) begin
    if (state == `ENUM_STATE_TRANSMIT && regCtrlRun) begin
      // push pattern of a single bit inside a pixel 
      neoDataBuf = neoPatternLookup[bitPatternIndex[2:0]];
    end else begin
      // reset state, stay LOW
      neoDataBuf = 'd0;
    end
  end
  
   
  assign neoData = neoDataBuf;
  
endmodule