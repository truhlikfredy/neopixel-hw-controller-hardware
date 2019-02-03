`include "anton_common.vh"

module anton_neopixel_stream_logic #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT,  // read anton_common.vh
  parameter  RESET_DELAY = `RESET_DELAY_DEFAULT, // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1)  // minimum required amount of bits to store the BUFFER_END
)(
  input                    clk6_4mhz,
  input                    regCtrlInit,
  input                    regCtrlRun,
  input                    regCtrlLoop,
  input                    regCtrlLimit,
  input                    regCtrl32bit,
  input                    [12:0] regMax, // 13 bits in total apb is using 16 bus but -2 bit are dropped for word alignment and 1 bit used to detect control registry accesses
  
  input                    initSlow,
  output                   initSlowDone,

  output [2:0]             bitPatternIx,
  output [2:0]             pixelBitIx,
  output [1:0]             channelIx,
  output [BUFFER_BITS-1:0] pixelIxMax,
  output [BUFFER_BITS-1:0] pixelIxComb,
  output                   state,
  output                   streamOutput,
  output                   streamReset,
  output                   streamBitOf,
  output                   streamChannelOf,
  output                   streamPixelOf,
  output                   streamSyncOf
);

  reg [2:0]             bitPatternIxB     = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [2:0]             pixelBitIxB       = 'd0;  // 0 - 7 to count part of the 8bits of a RGB pixel
  reg [BUFFER_BITS-1:0] pixelIxB          = {BUFFER_BITS{1'b0}};  // index to the current pixel transmitting 
  reg [11:0]            resetDelayCount   = 'd0;  // 12 bits can go up to 4096 so should be enough to count the RESET_DELAY_DEFAULT 1959ticks (306ns)
  reg [1:0]             channelIxB        = 'd0;  // R G B channels inside the pixel
  reg [1:0]             channelIxRemapped = 'd0;

  reg                   stateB            = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg [3:0]             cycle             = 'd0;  

  reg                   initSlowDoneB     = 'b0;
  

  // When 32bit mode enabled use
  // index to the current pixel transmitting, adjusted depending on 32/8 bit mode
  wire [BUFFER_BITS-1:0] pixelIxEquiv    = (regCtrl32bit) ? {pixelIxB[BUFFER_BITS-1:2], 2'b11} : pixelIxB;
  wire [BUFFER_BITS-1:0] pixelIxMaxEquiv = (regCtrl32bit) ? {pixelIxMax[BUFFER_BITS-1:2], 2'b00} : pixelIxMax;
  wire [BUFFER_BITS-3:0] pixelIxPartial  = pixelIxB[BUFFER_BITS-1:2] + 1; // in 32bit mode we +4 and have 00s in the last 2
  
  assign pixelIxComb     = (regCtrl32bit) ? {pixelIxB[BUFFER_BITS-1:2], channelIxRemapped} : pixelIxB[BUFFER_BITS-1:0]; // in 32bit mode include the channelIx

  assign streamOutput    = !regCtrlInit    && regCtrlRun && stateB == `ENUM_STATE_TRANSMIT; 
  assign streamReset     = !regCtrlInit    && regCtrlRun && stateB == `ENUM_STATE_RESET;

  wire   streamPatternOf = streamOutput    && bitPatternIxB == 'd7;   // does sub-bit pattern overflowing
  assign streamBitOf     = streamPatternOf && pixelBitIxB   == 'd7;   // does bit index overflowing
  assign streamChannelOf = streamBitOf     && channelIxB    == 'd2;   // On the 3rd channel of RGB the whole pixel is done
  wire   streamPixelLast = pixelIxEquiv    >= pixelIxMaxEquiv;        // we are on the last pixel in the buffer
  assign streamPixelOf   = streamChannelOf && streamPixelLast;        // toggle the LAST PIXEL flag only on overflow of the last bit of the last channel in the pixel

  always @(posedge clk6_4mhz) if (streamOutput) bitPatternIxB <= bitPatternIxB + 1;

  // When limit is enabled, use software limit, but when disabled use whole buffer
  // what is the reachable maximum depending on the settings
  assign pixelIxMax = (regCtrlLimit) ? regMax[BUFFER_BITS-1:0] : BUFFER_END[BUFFER_BITS-1:0];


  // The neopixel channels ordering is GRB but I want to be storing in the memory RGB, so do remapping
  always @(*) begin
    case (channelIxB)
      default: channelIxRemapped = 'd1; // the 'd0 and default are the same
      'd1:     channelIxRemapped = 'd0; 
      'd2:     channelIxRemapped = 'd2; 
    endcase
  end

  always @(posedge clk6_4mhz) begin 
    // for 'd0 - 'd6 => 7bits of a pixel just go for the next bit
    // on 'd7 => 8th bit do start on a new pixel with bit 'd0
    if (streamPatternOf) pixelBitIxB <= (streamBitOf) ? 0 : pixelBitIxB +1;

    if (initSlow) begin
      pixelIxB    <= {BUFFER_BITS{1'b0}};
      pixelBitIxB <= 'd0;  
      initSlowDoneB  <= 'b1; // after the init is done signal a flag
    end

    if (initSlowDoneB) begin
      initSlowDoneB  <= 'b0; // after one slow clock, it should be enough to de-assert the flag
    end

    if (streamBitOf) begin
      // Count R, G and B (on B it will be streamChannelOf so it will reset itself to 0)
      channelIxB <= (streamChannelOf) ? 'd0 : channelIxB + 'd1;
    end

    if (streamChannelOf) begin
      // Compare the index equivalent (in 32bit mode it jumps by 4bytes) if 
      // maximum buffer size was reached, but in cases the buffer size is power 
      // of 2 it will need to be by 1 bit to match the size
        if (streamPixelLast)  begin
          // for the very last pixel overflow 0 and start reset
          pixelIxB <= 'd0;
        end else begin
          // For all pixels except the last one go to the next pixel.
          // In 32bit mode increment differently than in 8bit
          pixelIxB <= (regCtrl32bit) ? {pixelIxPartial, 2'b00} : pixelIxB + 'd1;
        end
    end
  end


  assign streamSyncOf = (resetDelayCount == RESET_DELAY);


  always @(posedge clk6_4mhz) begin
    // if last pixel is reached turn into reset stateB
    if (streamPixelOf) stateB <= `ENUM_STATE_RESET;

    if (streamReset) begin
      // when in the reset stateB, count 300ns (RESET_DELAY ticks / 7MHz clock)
      resetDelayCount <= resetDelayCount + 'b1;
    end

    if (streamSyncOf) begin  
      // predefined wait in reset stateB was reached, let's 
      if (cycle == 'd5) $finish; // stop simulation here
      stateB          <= `ENUM_STATE_TRANSMIT;
      cycle           <= cycle + 'd1;
      resetDelayCount <= 'd0;
    end
  end

  // Set the register buffers to the ports
  assign bitPatternIx = bitPatternIxB;
  assign pixelBitIx   = pixelBitIxB;
  assign channelIx    = channelIxB;
  assign state        = stateB;
  assign initSlowDone = initSlowDoneB;

endmodule