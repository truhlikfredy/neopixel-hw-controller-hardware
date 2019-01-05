`include "anton_common.vh"

module anton_neopixel_registers #(
  parameter BUFFER_END = `BUFFER_END_DEFAULT // read anton_common.vh
)(
  input         busClk,
  input  [13:0] busAddr,
  input  [7:0]  busDataIn,
  input         busWrite,
  input         busRead,
  output [7:0]  busDataOut,

  input         streamSyncOf,

  input         syncStart,
  input         state,
  output [7:0]  pixels[BUFFER_END:0],
  output [12:0] regMax,
  output        regCtrlInit,
  output        regCtrlLimit,
  output        regCtrlRun,
  output        regCtrlLoop,
  output        regCtrl32bit,
  output        initSlow,
  input         initSlowDone
);

  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);  // minimum required amount of bits to store the BUFFER_END

  reg [7:0]  pixelsBuf[BUFFER_END:0];
  reg [7:0]  busDataOutBuf;

  // 13 bits in total apb is using 16 bus but -2 bit are dropped for word 
  // alignment and 1 bit used to detect control registry accesses
  reg [12:0] regMaxBuf; 

  reg        initSlowBuf     = 'b0;
  
  reg        regCtrlInitBuf  = 'b0;
  reg        regCtrlLimitBuf = 'b0; // Change this only when the pixel data are not streamed
  reg        regCtrlRunBuf   = 'b0;
  reg        regCtrlLoopBuf  = 'b0;
  reg        regCtrl32bitBuf = 'b0; // Change this only when the pixel data are not streamed


  // TODO: detect verilator and use it only there
  // for simulation to track few cycles of the whole process to make sure after 
  // reset nothing funny is happening
  
  always @(posedge busClk) begin
    if (streamSyncOf) regCtrlRunBuf <= regCtrlLoopBuf;

    if (syncStart) regCtrlRunBuf <= 'b1;

    if (initSlowDone) begin
      regCtrlInitBuf <= 'b0;
      initSlowBuf    <= 'b0;
    end

    if (regCtrlInitBuf) begin
      regCtrlLimitBuf <= 'b0;
      regCtrlRunBuf   <= 'b0;
      regCtrlLoopBuf  <= 'b0;
      regCtrl32bitBuf <= 'b0;

      initSlowBuf     <= 'b1;
    end
      if (busWrite) begin
        if (busAddr[13] == 'b0) begin

          // Write buffer
          pixelsBuf[busAddr[BUFFER_BITS-1:0]] <= busDataIn;
        end else begin

          // Write register
          // TODO: enums for registers indexes
          case (busAddr[2:0])
            0: regMaxBuf[7:0]  <= busDataIn;
            1: regMaxBuf[12:8] <= busDataIn[4:0];
            2: {regCtrl32bitBuf, regCtrlLoopBuf, regCtrlRunBuf, regCtrlLimitBuf, regCtrlInitBuf} <= busDataIn[4:0];
          endcase
        end
      end
      if (busRead) begin
        if (busAddr[13] == 'b0) begin
          
          // Read buffer
          busDataOutBuf <= pixelsBuf[busAddr[BUFFER_BITS-1:0]];
        end else begin

          // Read register
          case (busAddr[2:0])
            0: busDataOutBuf <= regMaxBuf[7:0];
            1: busDataOutBuf <= { 3'b000, regMaxBuf[12:8] };
            2: busDataOutBuf <= { 3'b000, regCtrl32bitBuf, regCtrlLoopBuf, regCtrlRunBuf, regCtrlLimitBuf, regCtrlInitBuf };
            3: busDataOutBuf <= { 7'b0000000, state };
          endcase
        end
    end
  end


  // Assign the register buffers to their outputs
  assign pixels       = pixelsBuf;
  assign busDataOut   = busDataOutBuf;
  assign regMax       = regMaxBuf;
  assign initSlow     = initSlowBuf;
  assign regCtrlInit  = regCtrlInitBuf;
  assign regCtrlLimit = regCtrlLimitBuf;
  assign regCtrlRun   = regCtrlRunBuf;
  assign regCtrlLoop  = regCtrlLoopBuf;
  assign regCtrl32bit = regCtrl32bitBuf;

endmodule