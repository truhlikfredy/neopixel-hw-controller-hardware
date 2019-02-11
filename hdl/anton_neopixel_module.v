`include "anton_common.vh"

// TODO: use bits and size properly https://stackoverflow.com/questions/13340301/size-bits-verilog

// TODO: rename streamReset to stream_sync, stream_run = streamOutput + stream_sync

// TODO: mss ready / reset signals

// TODO: nodemon killall first

module anton_neopixel_module #(
  parameter BUFFER_END  = `BUFFER_END_DEFAULT, // read anton_common.vh
  parameter VIRTUAL_END = `BUFFER_END_DEFAULT, // read anton_common.vh
  parameter RESET_DELAY = `RESET_DELAY_DEFAULT
)(
  input         clk6_4mhz,
  input         syncStart,
  output        neoData,
  output        neoState,

  input  [17:0] busAddr,
  input  [7:0]  busDataIn,
  input         busClk,
  input         busWrite,
  input         busRead,
  output [7:0]  busDataOut
);

  // minimum required amount of bits to store the BUFFER_END
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);   

  wire [12:0]            regMax;
  wire                   regCtrlInit;
  wire                   regCtrlLimit;
  wire                   regCtrlRun;
  wire                   regCtrlLoop;
  wire                   regCtrl32bit;
  wire                   initSlow;
  wire                   initSlowDone;
  wire                   streamSyncOf;

  wire [BUFFER_BITS-1:0] pixelIxComb;
  wire [7:0]             pixelByte;
  
  anton_neopixel_registers #(
    .BUFFER_END(`SANITIZE_BUFFER_END(BUFFER_END)),
    .VIRTUAL_END(`SANITIZE_BUFFER_END(VIRTUAL_END))
  ) registers(
    .busClk(busClk),
    .busAddr(busAddr),
    .busDataIn(busDataIn),
    .busWrite(busWrite),
    .busRead(busRead),
    .busDataOut(busDataOut),

    .pixelIxComb(pixelIxComb),
    .pixelByte(pixelByte),

    .streamSyncOf(streamSyncOf),

    .syncStart(syncStart),
    .state(neoState),
    .regMax(regMax),
    .regCtrlInit(regCtrlInit),
    .regCtrlLimit(regCtrlLimit),
    .regCtrlRun(regCtrlRun),
    .regCtrlLoop(regCtrlLoop),
    .regCtrl32bit(regCtrl32bit),
    .initSlow(initSlow),
    .initSlowDone(initSlowDone)
  );

  wire [2:0]             bitPatternIx; // 8 patterns in a bit
  wire [2:0]             pixelBitIx;   // 8 bits in channel
  wire [1:0]             channelIx;    // 3 channels in pixel
  wire [BUFFER_BITS-1:0] pixelIxMax;
  wire                   streamOutput;
  wire                   streamReset;
  wire                   streamBitOf;
  wire                   streamChannelOf;
  wire                   streamPixelOf;

  anton_neopixel_stream_logic #(
    .BUFFER_END(`SANITIZE_BUFFER_END(BUFFER_END)),
    .RESET_DELAY(RESET_DELAY)
  ) stream_logic(
    .clk6_4mhz(clk6_4mhz),
    .regCtrlInit(regCtrlInit),
    .regCtrlRun(regCtrlRun),
    .regCtrlLoop(regCtrlLoop),
    .regCtrlLimit(regCtrlLimit),
    .regCtrl32bit(regCtrl32bit),
    .regMax(regMax),

    .initSlow(initSlow),
    .initSlowDone(initSlowDone),

    .bitPatternIx(bitPatternIx),
    .pixelBitIx(pixelBitIx),
    .channelIx(channelIx),
    .pixelIxMax(pixelIxMax),
    .pixelIxComb(pixelIxComb),
    
    .state(neoState),
    .streamOutput(streamOutput),
    .streamReset(streamReset),
    .streamBitOf(streamBitOf),
    .streamChannelOf(streamChannelOf),
    .streamPixelOf(streamPixelOf),
    .streamSyncOf(streamSyncOf)
  );


  anton_neopixel_stream #(
    .BUFFER_END(`SANITIZE_BUFFER_END(BUFFER_END))
  ) stream(
    .pixelByte(pixelByte),
    .state(neoState),
    .channelIx(channelIx),
    .pixelBitIx(pixelBitIx),
    .bitPatternIx(bitPatternIx),
    .regCtrl32bit(regCtrl32bit),
    .regCtrlRun(regCtrlRun),
    .neoData(neoData)
  );
  
endmodule