`include "anton_common.vh"

module anton_neopixel_stream_logic #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT,  // read anton_common.vh
  parameter  RESET_DELAY = `RESET_DELAY_DEFAULT, // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1)  // minimum required amount of bits to store the BUFFER_END
)(
  input  clk6_4mhz,
  input  regCtrlInit,
  input  regCtrlRun,
  input  regCtrlLoop,
  input  regCtrlLimit,
  input  regCtrl32bit,
  input  [12:0] regMax, // 13 bits in total apb is using 16 bus but -2 bit are dropped for word alignment and 1 bit used to detect control registry accesses
  
  input  initSlow,
  output initSlowDone,

  output [2:0] bitPatternIndex,
  output [4:0] pixelBitIndex,
  output [BUFFER_BITS-1:0] pixelIndex,
  output [BUFFER_BITS-1:0] pixelIndexMax,
  output state,
  output streamOutput,
  output streamReset,
  output streamBitOf,
  output streamPixelOf,
  output streamSyncOf
);

  reg [2:0]             bitPatternIndexBuf = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [4:0]             pixelBitIndexBuf   = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg [BUFFER_BITS-1:0] pixelIndexBuf      = {BUFFER_BITS{1'b0}};  // index to the current pixel transmitting 
  reg [11:0]            resetDelayCount    = 'd0;  // 12 bits can go up to 4096 so should be enough to count the RESET_DELAY_DEFAULT 1959ticks (306ns)

  reg                   stateBuf           = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg [3:0]             cycle              = 'd0;  

  reg                   initSlowDone       = 'b0;
  

  // When 32bit mode enabled use
  // index to the current pixel transmitting, adjusted depending on 32/8 bit mode
  wire [BUFFER_BITS-1:0] pixelIndexEquiv = (regCtrl32bit) ? {pixelIndex[BUFFER_BITS-1:2], 2'b11} : pixelIndex;


  assign streamOutput      = !regCtrlInit && regCtrlRun && stateBuf == `ENUM_STATEBuf_TRANSMIT; 
  assign streamReset       = !regCtrlInit && regCtrlRun && stateBuf == `ENUM_STATEBuf_RESET;

  wire   streamPatternOf = streamOutput && bitPatternIndexBuf == 'd7;    // does sub-bit pattern overflowing
  assign streamBitOf     = streamPatternOf && pixelBitIndexBuf == 'd23; // does bit index overflowing
  wire   streamPixelLast = pixelIndexEquiv == pixelIndexMax;
  assign streamPixelOf   = streamBitOf && streamPixelLast;


  always @(posedge clk6_4mhz) begin
    if (initSlow) begin
      pixelIndexBuf    <= {BUFFER_BITS{1'b0}};
      pixelBitIndexBuf <= 'd0;  
      initSlowDone  <= 'b1; // after the init is done signal a flag
    end

    if (initSlowDone) begin
      initSlowDone  <= 'b0; // after one slow clock, it should be enough to de-assert the flag
    end
  end


  always @(posedge clk6_4mhz) if (streamOutput) bitPatternIndexBuf <= bitPatternIndexBuf + 1;


  // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
  // on 'd23 => 24th bit do start on a new pixel with bit 'd0
  always @(posedge clk6_4mhz) if (streamPatternOf) pixelBitIndexBuf <= (streamBitOf) ? 0 : pixelBitIndexBuf +1;


  // When limit is enabled, use software limit, but when disabled use whole buffer
  // what is the rechable maximum depending on the settings
  assign pixelIndexMax = (regCtrlLimit)? regMax[BUFFER_BITS-1:0] : BUFFER_END;


  always @(posedge clk6_4mhz) begin 
    if (streamBitOf) begin
      // Compare the index equivalent (in 32bit mode it jumps by 4bytes) if 
      // maximum buffer size was reached, but in cases the buffer size is power 
      // of 2 it will need to be by 1 bit to match the size
        if (streamPixelLast)  begin
          // for the very last pixel overflow 0 and start reset
          pixelIndexBuf <= 'd0;
        end else begin
          // For all pixels except the last one go to the next pixel.
          // In 32bit mode increment differently than in 8bit
          pixelIndexBuf <= (regCtrl32bit) ? pixelIndexBuf + 'd4 : pixelIndexBuf + 'd1;
        end
    end
  end

  // if last pixel is reached turn into reset stateBuf
  always @(posedge clk6_4mhz) if (streamPixelOf) stateBuf <= `ENUM_STATEBuf_RESET;


  assign streamSyncOf = (resetDelayCount == RESET_DELAY);


  always @(posedge clk6_4mhz) begin
    if (streamReset) begin
      // when in the reset stateBuf, count 300ns (RESET_DELAY ticks / 7MHz clock)
      resetDelayCount <= resetDelayCount + 'b1;
    end
  end


  always @(posedge clk6_4mhz) begin
    if (streamSyncOf) begin  
      // predefined wait in reset stateBuf was reached, let's 
      if (cycle == 'd5) $finish; // stop simulation here
      stateBuf           <= `ENUM_STATEBuf_TRANSMIT;
      cycle           <= cycle + 'd1;
      resetDelayCount <= 'd0;
    end
  end

  // Set the register buffers to the ports
  assign bitPatternIndex = bitPatternIndexBuf;
  assign pixelBitIndex   = pixelBitIndexBuf;
  assign state           = stateBuf;

endmodule