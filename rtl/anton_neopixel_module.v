`include "anton_common.vh"

// TODO: use bits and size properly https://stackoverflow.com/questions/13340301/size-bits-verilog

// TODO: rename streamReset to stream_sync, stream_run = streamOutput + stream_sync

// TODO: mss ready / reset signals

// TODO: nodemon killall first

module anton_neopixel_module #(
  parameter BUFFER_END  = `BUFFER_END_DEFAULT, // read anton_common.vh
  parameter RESET_DELAY = `RESET_DELAY_DEFAULT;
)(
  input  clk6_4mhz,
  input  syncStart,
  output neoData,
  output neoState,

  input  [13:0]busAddr,
  input  [7:0]busDataIn,
  input  busClk,
  input  busWrite,
  input  busRead,
  output [7:0]busDataOut
);

  // minimum required amount of bits to store the BUFFER_END
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);   

  wire [7:0]  pixels[BUFFER_END:0];
  wire [12:0] regMax;
  wire        regCtrlInit;
  wire        regCtrlLimit;
  wire        regCtrlRun;
  wire        regCtrlLoop;
  wire        regCtrl32bit;
  wire        initSlow;
  wire        initSlowDone;
  

  anton_neopixel_registers #(
    .BUFFER_END(BUFFER_END)
  ) registers(
    .busClk(busClk),
    .busAddr(busAddr),
    .busDataIn(busDataIn),
    .busWrite(busWrite),
    .busRead(busRead),
    .busDataOut(busDataOut),

    .streamSyncOf(streamSyncOf),

    .syncStart(syncStart),
    .state(neoState),
    .pixels(pixels),
    .regMax(regMax),
    .regCtrlInit(regCtrlInit),
    .regCtrlLimit(regCtrlLimit),
    .regCtrlRun(regCtrlRun),
    .regCtrlLoop(regCtrlLoop),
    .regCtrl32bit(regCtrl32bit),
    .initSlow(initSlow),
    .initSlowDone(initSlowDone)
  );


  wire [2:0] bitPatternIndex;
  wire [4:0] pixelBitIndex;
  wire [BUFFER_BITS-1:0] pixelIndex;
  wire [BUFFER_BITS-1:0] pixelIndexMax;
  wire streamOutput;
  wire streamReset;
  wire streamBitOf;
  wire streamPixelOf;
  wire streamSyncOf;


  anton_neopixel_stream #(
    .BUFFER_END(BUFFER_END)
  ) stream(
    .pixels(pixels),
    .state(neoState),
    .pixelIndex(pixelIndex),
    .pixelBitIndex(pixelBitIndex),
    .bitPatternIndex(bitPatternIndex),
    .regCtrl32bit(regCtrl32bit),
    .regCtrlRun(regCtrlRun),
    .neoData(neoData)
  );


  anton_neopixel_stream_logic #(
    .BUFFER_END(BUFFER_END),
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

    .bitPatternIndex(bitPatternIndex),
    .pixelBitIndex(pixelBitIndex),
    .pixelIndex(pixelIndex),
    .pixelIndexMax(pixelIndexMax),
    .state(neoState),
    .streamOutput(streamOutput),
    .streamReset(streamReset),
    .streamBitOf(streamBitOf),
    .streamPixelOf(streamPixelOf),
    .streamSyncOf(streamSyncOf)
  );

  
endmodule