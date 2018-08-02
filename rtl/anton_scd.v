// Cross domain signals, two flip-flop synchronizer
// http://www.verilogpro.com/clock-domain-crossing-part-1/

module anton_scd(
    input  inputFlag,
    input  clock,
    output outputFlag
);

reg [1:0] buffer;

always @(posedge clock) begin 
    buffer[1] <= buffer[0];
    buffer[0] <= inputFlag;
end

assign outputFlag = buffer[1];

endmodule