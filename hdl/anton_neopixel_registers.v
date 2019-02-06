`include "anton_common.vh"

module anton_neopixel_registers #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT, // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1) // minimum required amount of bits to store the BUFFER_END
)(
  input                    busClk,
  input  [17:0]            busAddr,
  input  [7:0]             busDataIn,
  input                    busWrite,
  input                    busRead,
  output [7:0]             busDataOut,

  input  [BUFFER_BITS-1:0] pixelIxComb,
  output [7:0]             pixelByte,

  input                    streamSyncOf,

  input                    syncStart,
  input                    state,
  output [12:0]            regMax,
  output                   regCtrlInit,
  output                   regCtrlLimit,
  output                   regCtrlRun,
  output                   regCtrlLoop,
  output                   regCtrl32bit,
  output                   initSlow,
  input                    initSlowDone
);

  reg  [7:0]             busDataOutB;

  // 13 bits in total apb is using 16 bus but -2 bit are dropped for word 
  // alignment and 1 bit used to detect control registry accesses
  reg  [12:0]            regMaxB; 

  reg                    initSlowB     = 'b0;
  
  reg                    regCtrlInitB  = 'b0;
  reg                    regCtrlLimitB = 'b0; // Change this only when the pixel data are not streamed
  reg                    regCtrlRunB   = 'b0;
  reg                    regCtrlLoopB  = 'b0;
  reg                    regCtrl32bitB = 'b0; // Change this only when the pixel data are not streamed

  reg                    ramTwoPortWrite = 'b0;


  // instantiate LSRAM 18K pipelined memory blocks, example #18
  anton_ram_2port_raddreg #(
    .BUFFER_END(`SANITIZE_BUFFER_END(BUFFER_END))
  ) tpram(
    .clk(busClk), 

    .rAddr(pixelIxComb), 
    .dOut(pixelByte),

    .wr(ramTwoPortWrite), 
    .wAddr(busAddr[BUFFER_BITS-1:0]), 
    .dIn(busDataIn)
  );

  // TODO: detect verilator and use it only there
  // for simulation to track few cycles of the whole process to make sure after 
  // reset nothing funny is happening
  
  always @(posedge busClk) begin
    if (streamSyncOf) regCtrlRunB <= regCtrlLoopB;

    if (syncStart) regCtrlRunB <= 'b1;

    if (initSlowDone) begin
      regCtrlInitB <= 'b0;
      initSlowB    <= 'b0;
    end

    if (regCtrlInitB) begin
      regCtrlLimitB <= 'b0;
      regCtrlRunB   <= 'b0;
      regCtrlLoopB  <= 'b0;
      regCtrl32bitB <= 'b0;

      initSlowB     <= 'b1;
    end

    ramTwoPortWrite <= 'b0;
    if (busWrite) begin
      if (busAddr[17:16] == 2'b00) begin
        ramTwoPortWrite <= 'b1;
      end else begin

        // Write register
        // TODO: enums for registers indexes
        case (busAddr[2:0])
          0: regMaxB[7:0]  <= busDataIn;
          1: regMaxB[12:8] <= busDataIn[4:0];
          2: {regCtrl32bitB, regCtrlLoopB, regCtrlRunB, regCtrlLimitB, regCtrlInitB} <= busDataIn[4:0];
        endcase
      end
    end

    if (busRead) begin
      if (busAddr[17:16] == 2'b00) begin

        // Read buffer - disabled because using only 2 port memory for frame buffer
        busDataOutB <= 8'b11111111;
      end else begin

        // Read register
          case (busAddr[2:0])
          0: busDataOutB <= regMaxB[7:0];
          1: busDataOutB <= { 3'b000, regMaxB[12:8] };
          2: busDataOutB <= { 3'b000, regCtrl32bitB, regCtrlLoopB, regCtrlRunB, regCtrlLimitB, regCtrlInitB };
          3: busDataOutB <= { 7'b0000000, state };
        endcase
      end
    end
  end


  assign busDataOut   = busDataOutB;
  assign regMax       = regMaxB;
  assign initSlow     = initSlowB;
  assign regCtrlInit  = regCtrlInitB;
  assign regCtrlLimit = regCtrlLimitB;
  assign regCtrlRun   = regCtrlRunB;
  assign regCtrlLoop  = regCtrlLoopB;
  assign regCtrl32bit = regCtrl32bitB;

endmodule