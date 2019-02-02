`include "anton_common.vh"

module anton_ram_2port_raddreg #(
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT, // read anton_common.vh
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1)  // minimum required amount of bits to store the BUFFER_END
)(clk, wr, raddr, din, waddr, dout);
input clk;
input [7:0] din;
input wr;
input [BUFFER_BITS-1:0] waddr;
input [BUFFER_BITS-1:0] raddr;

output [7:0] dout;

reg [BUFFER_BITS-1:0] raddr_reg;
reg [7:0] mem [0:BUFFER_END-1];

assign dout = mem[raddr_reg];

always@ (posedge clk)
begin
  raddr_reg <= raddr;
  if (wr)
    mem[waddr] <= din;

end
endmodule