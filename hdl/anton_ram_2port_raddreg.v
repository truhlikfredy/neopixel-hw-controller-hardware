`include "anton_common.vh"

// Synplify inference patterns into blocks:
// https://www.microsemi.com/document-portal/doc_view/129966-inferring-microsemi-smartfusion2-ram-blocks-app-note

// Using LSRAM 18K blocks pipelined memory blocks, example #18
module anton_ram_2port_raddreg #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT,  // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1)  // minimum required amount of bits to store the BUFFER_END
)(
  input                    clk,

  input  [BUFFER_BITS-1:0] rAddr,
  output [7:0]             dOut,

  input                    wr,
  input  [BUFFER_BITS-1:0] wAddr,
  input  [7:0]             dIn
);

reg [BUFFER_BITS-1:0] raddr_reg;
reg [7:0]             mem [0:BUFFER_END-1];
reg [7:0]             dOut;
reg [7:0]             dOutB;

always@ (posedge clk)
begin
  raddr_reg <= rAddr;
  dOutB <= mem[raddr_reg];
  if (wr)
    mem[wAddr] <= dIn;
end

always@ (posedge clk)
begin
  dOut <= dOutB;
end


endmodule