`include "anton_common.vh"

// TODO more consistent naming
module anton_neopixel_registers (
  input         busClk,
  input  [13:0] busAddr,
  input  [7:0]  busDataIn,
  input         busWrite,
  input         busRead,
  output [7:0]  busDataOut,

  input         stream_sync_of,

  input         syncStart,
  input         state,
  output [7:0]  pixels[BUFFER_END:0],
  output [12:0] reg_max,
  output        reg_ctrl_init,
  output        reg_ctrl_limit,
  output        reg_ctrl_run,
  output        reg_ctrl_loop,
  output        reg_ctrl_32bit,
  output        initSlow,
  input         initSlowDone
);

  reg [7:0]  pixels[BUFFER_END:0];
  reg [7:0]  busDataOut;

  // 13 bits in total apb is using 16 bus but -2 bit are dropped for word 
  // alignment and 1 bit used to detect control registry accesses
  reg [12:0] reg_max; 
  
  reg        reg_ctrl_init  = 'b0;
  reg        reg_ctrl_limit = 'b0; // Change this only when the pixel data are not streamed
  reg        reg_ctrl_run   = 'b0;
  reg        reg_ctrl_loop  = 'b0;
  reg        reg_ctrl_32bit = 'b0; // Change this only when the pixel data are not streamed

  parameter  BUFFER_END  = `BUFFER_END_DEFAULT;   // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);  // minimum required amount of bits to store the BUFFER_END


  // TODO: detect verilator and use it only there
  // for simulation to track few cycles of the whole process to make sure after 
  // reset nothing funny is happening
  
  always @(posedge busClk) begin
    if (initSlowDone) begin
      reg_ctrl_init <= 'b0;
      initSlow      <= 'b0;
    end

    if (reg_ctrl_init) begin
      // reg_ctrl_init   <= 'b0;
      reg_ctrl_limit  <= 'b0;
      reg_ctrl_run    <= 'b0;
      reg_ctrl_loop   <= 'b0;
      reg_ctrl_32bit  <= 'b0;

      initSlow        <= 'b1;
    end
      if (busWrite) begin
        if (busAddr[13] == 'b0) begin

          // Write buffer
          pixels[busAddr[BUFFER_BITS-1:0]] <= busDataIn;
        end else begin

          // Write register
          case (busAddr[1:0])
            0: reg_max[7:0]  <= busDataIn;
            1: reg_max[12:8] <= busDataIn[4:0];
            2: {reg_ctrl_32bit, reg_ctrl_loop, reg_ctrl_run, reg_ctrl_limit, reg_ctrl_init} <= busDataIn[4:0];
          endcase
        end
      end
      if (busRead) begin
        if (busAddr[13] == 'b0) begin
          
          // Read buffer
          busDataOut <= pixels[busAddr[BUFFER_BITS-1:0]];
        end else begin

          // Read register
          case (busAddr[1:0])
            0: busDataOut <= reg_max[7:0];
            1: busDataOut <= { 3'b000, reg_max[12:8]};
            2: busDataOut <= {3'b000, reg_ctrl_32bit, reg_ctrl_loop, reg_ctrl_run, reg_ctrl_limit, reg_ctrl_init};
            3: busDataOut <= {7'b0000000, state};
          endcase
        end
    end
  end


  always @(posedge busClk) if (stream_sync_of) reg_ctrl_run <= reg_ctrl_loop;

  always @(posedge busClk) if (syncStart) reg_ctrl_run <= 'b1;


endmodule