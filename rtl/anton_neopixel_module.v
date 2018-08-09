`include "anton_common.vh"

// TODO: use bits and size properly https://stackoverflow.com/questions/13340301/size-bits-verilog

// TODO: rename stream_reset to stream_sync, stream_run = stream_output + stream_sync

// TODO: mss ready / reset signals

// TODO: nodemon killall first

module anton_neopixel_module (
  input  clk7mhz,
  output neoData,
  output neoState,

  input  [13:0]busAddr,
  input  [7:0]busDataIn,
  input  busClk,
  input  busWrite,
  input  busRead,
  output [7:0]busDataOut
  );

  // number of bytes counting from zero, so the size is BUFFER_END+1, maximum 
  // 8192 pixels, which should have 4Hz refresh
  parameter  BUFFER_END  = `BUFFER_END_DEFAULT;

  // how long the reset delay will be happening, minimum is 50us so 50/(1/7) =
  // 350 ticks. But giving bit margin 55us => 385 ticks
  parameter  RESET_DELAY = `RESET_DELAY_DEFAULT; 

  // minimum required amount of bits to store the BUFFER_END
  localparam BUFFER_BITS = `CLOG2(BUFFER_END+1);   


  reg [7:0]  bus_data_out_buffer;
  reg [7:0]  pixels[BUFFER_END:0];
            
  
  // 13 bits in total apb is using 16 bus but -2 bit are dropped for word 
  // alignment and 1 bit used to detect control registry accesses
  reg [12:0] reg_max; 
  
  reg        reg_ctrl_init  = 'b0;
  reg        reg_ctrl_limit = 'b0; // Change this only when the pixel data are not streamed
  reg        reg_ctrl_run   = 'b0;
  reg        reg_ctrl_loop  = 'b0;
  reg        reg_ctrl_32bit = 'b0; // Change this only when the pixel data are not streamed
  
  
  // TODO: detect verilator and use it only there
  // for simulation to track few cycles of the whole process to make sure after 
  // reset nothing funny is happening
  
  always @(posedge busClk) begin
    if (reg_ctrl_init) begin
      reg_ctrl_init   <= 'b0;
      reg_ctrl_limit  <= 'b0;
      reg_ctrl_run    <= 'b0;
      reg_ctrl_loop   <= 'b0;
      reg_ctrl_32bit  <= 'b0;
    end else begin

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
          bus_data_out_buffer <= pixels[busAddr[BUFFER_BITS-1:0]];
        end else begin

          // Read register
          case (busAddr[1:0])
            0: bus_data_out_buffer <= reg_max[7:0];
            1: bus_data_out_buffer <= { 3'b000, reg_max[12:8]};
            2: bus_data_out_buffer <= {3'b000, reg_ctrl_32bit, reg_ctrl_loop, reg_ctrl_run, reg_ctrl_limit, reg_ctrl_init};
            3: bus_data_out_buffer <= {7'b0000000, state};
          endcase
        end
      end
    end
  end


  always @(posedge busClk) if (stream_sync_of) reg_ctrl_run <= reg_ctrl_loop;


  anton_neopixel_stream #(
    .BUFFER_END(BUFFER_END)
  ) stream(
    .pixels(pixels),
    .state(state),
    .pixel_index(pixel_index),
    .pixel_bit_index(pixel_bit_index),
    .bit_pattern_index(bit_pattern_index),
    .reg_ctrl_32bit(reg_ctrl_32bit),
    .reg_ctrl_run(reg_ctrl_run),
    .neoData(neoData)
  );


  wire [2:0] bit_pattern_index;
  wire [4:0] pixel_bit_index;
  wire [BUFFER_BITS-1:0] pixel_index;
  wire [BUFFER_BITS-1:0] pixel_index_max;
  wire state;
  wire stream_output;
  wire stream_reset;
  wire stream_bit_of;
  wire stream_pixel_of;
  wire stream_sync_of;


  anton_neopixel_stream_logic #(
    .BUFFER_END(BUFFER_END),
    .RESET_DELAY(RESET_DELAY)
  ) stream_logic(
    .clk7mhz(clk7mhz),
    .reg_ctrl_init(reg_ctrl_init),
    .reg_ctrl_run(reg_ctrl_run),
    .reg_ctrl_loop(reg_ctrl_loop),
    .reg_ctrl_limit(reg_ctrl_limit),
    .reg_ctrl_32bit(reg_ctrl_32bit),
    .reg_max(reg_max),

    .bit_pattern_index(bit_pattern_index),
    .pixel_bit_index(pixel_bit_index),
    .pixel_index(pixel_index),
    .pixel_index_max(pixel_index_max),
    .state(state),
    .stream_output(stream_output),
    .stream_reset(stream_reset),
    .stream_bit_of(stream_bit_of),
    .stream_pixel_of(stream_pixel_of),
    .stream_sync_of(stream_sync_of)
  );


  assign busDataOut = bus_data_out_buffer;
  assign neoState   = state;
  
endmodule