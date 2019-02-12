`include "anton_common.vh"

// Synplify inference patterns into blocks:
// https://www.microsemi.com/document-portal/doc_view/129966-inferring-microsemi-smartfusion2-ram-blocks-app-note

// Using LSRAM 18K blocks pipelined memory blocks, example #18
module anton_ram_2port_symmetric #(
  parameter  BUFFER_END   = `BUFFER_END_DEFAULT,  // read anton_common.vh
  parameter  BUFFER_WIDTH = 8,
  localparam BUFFER_BITS  = `CLOG2(BUFFER_END+1)  // minimum required amount of bits to store the BUFFER_END
)(
  input                     clk,

  input  [BUFFER_BITS-1:0]  rAddr,
  output [BUFFER_WIDTH-1:0] dOut,

  input                     wr,
  input  [BUFFER_BITS-1:0]  wAddr,
  input  [BUFFER_WIDTH-1:0] dIn
);

reg [BUFFER_BITS-1:0]  raddr_reg;
reg [BUFFER_WIDTH-1:0] mem [0:BUFFER_END-1];
reg [BUFFER_WIDTH-1:0] dOutB1;
reg [BUFFER_WIDTH-1:0] dOutB2;

always@ (posedge clk)
begin
  raddr_reg <= rAddr;
  dOutB2 <= mem[raddr_reg];
  if (wr)
    mem[wAddr] <= dIn;
end

always@ (posedge clk)
begin
  dOutB1 <= dOutB2;
end

assign dOut = dOutB1;


endmodule