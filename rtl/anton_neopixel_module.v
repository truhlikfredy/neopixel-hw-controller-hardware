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


  wire [7:0]  pixels[BUFFER_END:0];
  wire [12:0] reg_max;
  wire        reg_ctrl_init;
  wire        reg_ctrl_limit;
  wire        reg_ctrl_run;
  wire        reg_ctrl_loop;
  wire        reg_ctrl_32bit;
  

  anton_neopixel_registers #(
    .BUFFER_END(BUFFER_END)
  ) registers(
    .busClk(busClk),
    .busAddr(busAddr),
    .busDataIn(busDataIn),
    .busWrite(busWrite),
    .busRead(busRead),
    .busDataOut(busDataOut),

    .stream_sync_of(stream_sync_of),

    .state(neoState),
    .pixels(pixels),
    .reg_max(reg_max),
    .reg_ctrl_init(reg_ctrl_init),
    .reg_ctrl_limit(reg_ctrl_limit),
    .reg_ctrl_run(reg_ctrl_run),
    .reg_ctrl_loop(reg_ctrl_loop),
    .reg_ctrl_32bit(reg_ctrl_32bit)
  );


  wire [2:0] bit_pattern_index;
  wire [4:0] pixel_bit_index;
  wire [BUFFER_BITS-1:0] pixel_index;
  wire [BUFFER_BITS-1:0] pixel_index_max;
  wire stream_output;
  wire stream_reset;
  wire stream_bit_of;
  wire stream_pixel_of;
  wire stream_sync_of;


  anton_neopixel_stream #(
    .BUFFER_END(BUFFER_END)
  ) stream(
    .pixels(pixels),
    .state(neoState),
    .pixel_index(pixel_index),
    .pixel_bit_index(pixel_bit_index),
    .bit_pattern_index(bit_pattern_index),
    .reg_ctrl_32bit(reg_ctrl_32bit),
    .reg_ctrl_run(reg_ctrl_run),
    .neoData(neoData)
  );


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
    .state(neoState),
    .stream_output(stream_output),
    .stream_reset(stream_reset),
    .stream_bit_of(stream_bit_of),
    .stream_pixel_of(stream_pixel_of),
    .stream_sync_of(stream_sync_of)
  );

  
endmodule