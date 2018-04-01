module anton_neopixel_top (
  input CLK_10MHZ,
	output NEODATA);

  reg [31:0]  data = 32'b111111111000000001010101;
  reg [12:0] neolookup[1:0] = '{ 13'b111000000000, 13'b111111110000};

  reg [10:0] counter = 'd0;
  reg [3:0]  bit_clk = 'd0;
  reg [4:0]  bit_counter = 'd0;
  reg [1:0]  pixel    = 'd0;
  reg 			 data_int = 'b0;
  reg        state = 'b0;
 			     
  always @(posedge CLK_10MHZ) begin
    if (state == 'd0) begin
      bit_clk <= bit_clk + 'b1;
      if (bit_clk > 12) begin
        bit_clk <= 'b0;

        if (bit_counter < 'd31) begin
          bit_counter <= bit_counter + 'b1;
        end else begin
          bit_counter <= 'b0;
          pixel <= pixel + 'b1;
          state = 'd1;
        end
      end
      data_int = neolookup[data[bit_counter]][bit_clk];
    end else begin
      data_int = 'd0;
    end
  end

  assign NEODATA = data_int;   

  always @(posedge CLK_10MHZ) begin
    counter <= counter + 'b1;
    if (counter > 700) begin
      $finish;
    end  
  end

endmodule