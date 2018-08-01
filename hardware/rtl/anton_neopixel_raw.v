`include "anton_common.vh"

// TODO: Downgrade the clock to 7MHz, allow for the 0 = 2 + 6 ticks and for 1 = 5 + 3 ticks
// in both cases they will be 8 ticks (power of 2) and simplify the counter (no logic to compare)
// needed and it will just overflow. Total time to transmit 1 pixel will be 1.14us instead 1.2us 
// so it should be faster on longer chains. To update 200 pixels will save 12uS (which is worth about 
// another 10 pixels of time)

//`define HARDCODED_PIXELS 1

// TODO: use bits and size properly https://stackoverflow.com/questions/13340301/size-bits-verilog

// TODO: splitup modules

// TODO: mss ready / reset signals

// TODO: idle state, writing state, ready state, do no repeately flash the content but only after finished write

// TODO: get rid if you can of the nested overflow checkers

// TODO: nodemon killall first

module anton_neopixel_raw (
  input  clk7mhz,
  output neoData,
  output neoState,
  output pixelsSync,

  input  [13:0]busAddr,
  input  [7:0]busDataIn,
  input  busClk,
  input  busWrite,
  input  busRead,
  output [7:0]busDataOut
  );

  parameter  PIXELS_MAX  = 66;  // maximum number of LEDs in a strip
  parameter  RESET_DELAY = 600; // how long the reset delay will be happening 600 == 60us (50us is minimum)
  localparam PIXELS_BITS = `CLOG2(PIXELS_MAX);   // minimum required amount of bits to store the PIXELS_MAX

  //reg [PIXELS_BITS-1:0][7:0] pixels;

  reg [7:0]              bus_data_out_buffer;
  reg [7:0]              pixels[PIXELS_MAX-1:0];
  reg [7:0]              pixel_value_8bit   = 'd0;  // pixel value before expanding
  reg [23:0]             pixel_value_32bit  = 'd0;  // Blue Red Green, order is from right to left and the MSB are sent first
  reg [7:0]              neo_pattern_lookup = 'd0;
            
  reg [9:0]              reset_delay_count  = 'd0;  // 10 bits can go to 1024 so should be enough to count ~500 (50us)
  reg [2:0]              bit_pattern_index  = 'd0;  // counting 0 - 7 (2:0) for 8x sub-bit steps @ 7MHz and counting to 8 (3:0) to detect overflow
  reg [PIXELS_BITS-1:0]  pixel_index        = {PIXELS_BITS{1'b0}};  // index to the current pixel transmitting
  reg [4:0]              pixel_bit_index    = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg                    state              = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg                    pixels_synth_buf   = 'd0;
  reg                    data_int           = 'b0;
  reg [1:0]              cycle              = 'd0;  // for simulation to track few cycles of the whole process to make sure after reset nothing funny is happening

  wire [7:0]             registers[4]; // maxL, maxH, ready, cfg (autostart, start on write & palete mode)
  reg [15:0]             reg_max;
  reg                    reg_ctrl_init;
  reg                    reg_ctrl_limit;
  reg                    reg_ctrl_run;
  reg                    reg_ctrl_loop;
  reg                    reg_ctrl_24bit;
  reg                    reg_ctrl_unused[3];
  reg                    reg_state_reset;
  reg                    reg_state_off;
  reg                    reg_state_unused[6];
  
  localparam  ENUM_STATE_TRANSMIT = 0;   // If I will make SystemVerilog variant then use proper enums for this
  localparam  ENUM_STATE_RESET    = 1;


  always @* begin
    assign registers[0]    = reg_max[7:0];
    assign registers[1]    = reg_max[15:8];
    assign registers[2][0] = reg_ctrl_init;
    assign registers[2][1] = reg_ctrl_limit;
    assign registers[2][2] = reg_ctrl_run;
    assign registers[2][3] = reg_ctrl_loop;
    assign registers[2][4] = reg_ctrl_24bit;
    assign registers[2][5] = reg_ctrl_unused[0];
    assign registers[2][6] = reg_ctrl_unused[1];
    assign registers[2][7] = reg_ctrl_unused[2];
    assign registers[3][0] = reg_state_reset;
    assign registers[3][1] = reg_state_off;
    assign registers[3][2] = reg_state_unused[0];
    assign registers[3][3] = reg_state_unused[1];
    assign registers[3][4] = reg_state_unused[2];
    assign registers[3][5] = reg_state_unused[3];
    assign registers[3][6] = reg_state_unused[4];
    assign registers[3][7] = reg_state_unused[5];
  end

  // as combinational logic should be enough
  // https://electronics.stackexchange.com/questions/29553/how-are-verilog-always-statements-implemented-in-hardware
  always @(*) begin
    case (pixel_value_32bit[pixel_bit_index])
      // depending on the current bit decide what pattern to push
      // patterns are ordered from right to left
      1'b0: neo_pattern_lookup = 8'b00000011;
      1'b1: neo_pattern_lookup = 8'b00011111;
    endcase
  end


  always @(*) begin
    `ifdef HARDCODED_PIXELS
      // hardcoded predefined colors for 3 pixels in a strip
      // TODO: use casez so bigger arrays could be auto filled with these values in tiling/overflow method
      case (pixel_index)
        'd0: pixel_value_32bit = 24'hff00d5;
        'd1: pixel_value_32bit = 24'h008800;
        'd2: pixel_value_32bit = 24'h000090;
        default:  pixel_value_32bit = 24'h101010;  // slightly light to show there might be problem in configuration
      endcase
    `else
      // 2B, 3G, 3R = 8bit source format       => [7:6]Blue,  [5:3]Green, [2-0]Red
      // 8B, 8R, 8G = 32bit destination format =>  xxxxxBBx xxxxRRRx xxxxGGGx  high bits are sent first (so reorder them to the right)
      pixel_value_32bit = { 
        5'b00000, pixel_value_8bit[6], pixel_value_8bit[7], 1'b0,                   // 2bits Blues
        4'b0000,  pixel_value_8bit[0], pixel_value_8bit[1], pixel_value_8bit[2], 1'b0,   // 3bits Red
        4'b0000,  pixel_value_8bit[3], pixel_value_8bit[4], pixel_value_8bit[5], 1'b0    // 3bits Green
      };
    `endif
  end


  always @(*) begin
    if (state == ENUM_STATE_TRANSMIT) begin
      // push pattern of a single bit inside a pixel 
      data_int = neo_pattern_lookup[bit_pattern_index[2:0]];
    end else begin
      // reset state, stay LOW
      data_int = 'd0;
    end
  end


  always @(posedge busClk) begin
    // TODO: write better tester for these writes/reads
    if (busWrite) begin
      if (busAddr[13] == 'b0) begin
        pixels[busAddr[PIXELS_BITS-1:0]] <= busDataIn;
      end else begin
        registers[busAddr[1:0]]          <= busDataIn;
      end
    end
    if (busRead) begin
      if (busAddr[13] == 'b0) begin
        bus_data_out_buffer <= pixels[busAddr[PIXELS_BITS-1:0]];
      end else begin
        bus_data_out_buffer <= registers[busAddr[1:0]];
      end
    end
  end


  always @(posedge clk7mhz) begin
    if (state == ENUM_STATE_TRANSMIT) begin

      bit_pattern_index <= bit_pattern_index + 1;

      if (bit_pattern_index == 'd7) begin

        if (pixel_bit_index < 'd23) begin
          // for 'd0 - 'd22 => 23bits of a pixel just go for the next bit
          pixel_bit_index <= pixel_bit_index + 'b1;
        end else begin
          // on 'd23 => 24th bit do start on a new pixel with bit 'd0
          pixel_bit_index <= 'b0;

          if (pixel_index < PIXELS_MAX-1) begin
            // for all pixels go to the next pixel
            pixel_index <= pixel_index + 'b1;
          end else begin
            // for the very last pixel overflow 0 and start reset
            pixel_index <= 'd0;
            state <= ENUM_STATE_RESET;
          end
          
          pixel_value_8bit <= pixels[pixel_index];
        end        
      end
    end else begin
      // when in the reset state, count 50ns (RESET_DELAY / 10)
      reset_delay_count <= reset_delay_count + 'b1;
      pixels_synth_buf  <= 1;
      reg_state_reset <= 1;

      if (reset_delay_count > RESET_DELAY) begin  
        // predefined wait in reset state was reached, let's 
        reg_state_reset <= 0;
        state <= 'd0;
        if (cycle == 'd3) $finish; // stop simulation here, went through all pixels and a reset twice
        cycle             <= cycle + 'd1;
        reset_delay_count <= 'd0;
        pixels_synth_buf  <= 0;
      end
    end
  end


  assign neoData    = data_int;
  assign neoState   = state;
  assign busDataOut = bus_data_out_buffer;
  assign pixelsSync = pixels_synth_buf;
  
endmodule