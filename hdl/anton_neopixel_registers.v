`include "anton_common.vh"

module anton_neopixel_registers #(
  parameter  BUFFER_END   = `BUFFER_END_DEFAULT,  // read anton_common.vh
  parameter  VIRTUAL_END  = `BUFFER_END_DEFAULT,  // read anton_common.vh
  localparam BUFFER_BITS  = `CLOG2(BUFFER_END+1), // minimum required amount of bits to store the BUFFER_END
  localparam VIRTUAL_BITS = `CLOG2(VIRTUAL_END+1) // minimum required amount of bits to store the BUFFER_END
)(
  input                    busClk,
  input  [17:0]            busAddr,
  input  [7:0]             busDataIn,
  input                    busWrite,
  input                    busRead,
  output [7:0]             busDataOut,
  output                   busReady,

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

  reg  [7:0]              busDataOutB;
  reg                     busReadyB       = 'b1;

  // 13 bits in total apb is using 16 bus but -2 bit are dropped for word 
  // alignment and 1 bit used to detect control registry accesses
  reg  [12:0]             regMaxB; 

  reg                     initSlowB       = 'b0;
  
  reg                     regCtrlInitB    = 'b0;
  reg                     regCtrlLimitB   = 'b0; // Change this only when the pixel data are not streamed
  reg                     regCtrlRunB     = 'b0;
  reg                     regCtrlLoopB    = 'b0;
  reg                     regCtrl32bitB   = 'b0; // Change this only when the pixel data are not streamed
  reg  [13:0]             regWidth        = 'd0; // Similar range as regMax, but counting from 1 and not from 0 allowing 8192x1 virtual buffers
  reg  [13:0]             regHeight       = 'd0; // Similar range as regMax, but counting from 1 and not from 0 allowing 1x8192 virtual buffers

  reg                     ramTwoPortWrite = 'b0;
  reg  [BUFFER_BITS-1:0]  ramTwoPortAddr  = 'b0;
  
  reg                     ramDeltaWrite   = 'b0;
  reg  [16:0]             ramDeltaAccAddr = 'b0; // busAddr width - 1 as we do LOW/HIGH and do not need to keep least sig. bit TODO: use $bits and consider Virtual WIDTH

  reg                     ramVirtualWrite = 'b0;
  reg  [VIRTUAL_BITS-1:0] ramVirtualAddr  = 'b0;
  reg  [7:0]              ramVirtualB     = 'b0;
 

  // instantiate LSRAM 18K pipelined memory blocks, example #18, for the raw pixels
  anton_ram_2port_symmetric #(
    .BUFFER_END(`SANITIZE_BUFFER_END(BUFFER_END)),
    .BUFFER_WIDTH(8)
  ) tpRam(
    .clk(busClk), 

    .rAddr(pixelIxComb), 
    .dOut(pixelByte),

    .wr(ramTwoPortWrite), 
    .wAddr(ramTwoPortAddr), 
    .dIn(busDataIn)
  );


  // instantiate LSRAM 18K pipelined memory blocks, example #18, for the delta information
  anton_ram_2port_symmetric #(
    .BUFFER_END(`SANITIZE_BUFFER_END(VIRTUAL_END)),
    .BUFFER_WIDTH(8)
  ) deltaRam(
    .clk(busClk), 

    .rAddr(ramVirtualAddr[VIRTUAL_BITS-1:0]), 
    .dOut(ramVirtualB),

    .wr(ramDeltaWrite), 
    .wAddr(ramDeltaAccAddr[VIRTUAL_BITS-1:0]),
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
    ramDeltaWrite   <= 'b0;

    if (ramVirtualWrite == 'b1) begin
      // 2nd Stage Virtual Write
      ramVirtualWrite <= 'b0;
      ramTwoPortWrite <= 'b1;
      ramTwoPortAddr  <= ramVirtualB[BUFFER_BITS-1:0];
    end

    if (busWrite) begin
      if (busAddr[17:16] == 2'b00) begin

        // 1st stage Virtual writes first read the Delta index and then write to the Raw buffer
        ramVirtualWrite <= 'b1;
        ramVirtualAddr  <= busAddr[VIRTUAL_BITS-1:0];

      end else if (busAddr[17:16] == 2'b01) begin

        ramDeltaAccAddr   <= busAddr[17:1];
        ramDeltaWrite     <= 'b1;

      end else if (busAddr[17:16] == 2'b10) begin
        
        // Regular raw buffer write
        ramTwoPortWrite <= 'b1;
        ramTwoPortAddr  <= busAddr[BUFFER_BITS-1:0];

      end else if (busAddr[17:16] == 2'b11) begin

        // Write register
        // TODO: enums for registers indexes
        case (busAddr[3:0])
          0: regMaxB[7:0]    <= busDataIn;
          1: regMaxB[12:8]   <= busDataIn[4:0];
          2: {regCtrl32bitB, regCtrlLoopB, regCtrlRunB, regCtrlLimitB, regCtrlInitB} <= busDataIn[4:0];

          5: regWidth[7:0]   <= busDataIn;
          6: regWidth[13:8]  <= busDataIn[5:0];

          7: regHeight[7:0]  <= busDataIn;
          8: regHeight[13:8] <= busDataIn[5:0];
        endcase
      end
    end

    if (busRead) begin
      if (busAddr[17:16] == 2'b11) begin

        // Read register
          case (busAddr[3:0])
          0: busDataOutB <= regMaxB[7:0];
          1: busDataOutB <= { 3'b000, regMaxB[12:8] };
          2: busDataOutB <= { 3'b000, regCtrl32bitB, regCtrlLoopB, regCtrlRunB, regCtrlLimitB, regCtrlInitB };
          3: busDataOutB <= { 7'b0000000, state };

          5: busDataOutB <= regWidth[7:0];
          6: busDataOutB <= { 2'b00, regWidth[13:8] };

          7: busDataOutB <= regHeight[7:0];
          8: busDataOutB <= { 2'b00, regHeight[13:8] };
        endcase
      end else begin
        // Read buffer raw/delta/virtual - disabled because using only 2 port memory for frame buffer
        busDataOutB <= 8'b11111111;
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
  assign busReady     = busReadyB;

endmodule