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
  input clk10mhz,
  output neoData,
  output neoState,

  input [7:0]busAddr,
  input [7:0]busData,
  input busClk,
  input busWrite
  );

  parameter PIXELS_MAX  = 5;   // maximum number of LEDs in a strip
  parameter PIXELS_BITS = 3;   // minimum required amount of bits to store the PIXELS_MAX
  parameter RESET_DELAY = 600; // how long the reset delay will be happening 500 == 50us

  //reg [PIXELS_BITS-1:0][7:0] pixels;

  reg [7:0]              pixels[PIXELS_MAX-1:0];
  reg [23:0]             pixel_value        = 'd0;  // Blue Red Green, order is from right to left and the MSB are sent first
  reg [11:0]             neo_pattern_lookup = 'd0;
            
  reg [9:0]              reset_delay_count  = 'd0;  // 10 bits can go to 1024 so should be enough to count ~500 (50us)
  reg [3:0]              bit_pattern_index  = 'd0;  // counting 0 - 11
  reg [PIXELS_BITS-1:0]  pixel_index        = 'd0;  // index to the current pixel transmitting
  reg [4:0]              pixel_bit_index    = 'd0;  // 0 - 23 to count whole 24bits of a RGB pixel
  reg                    state              = 'b0;  // 0 = transmit bits, 1 = reset mode
  reg                    data_int           = 'b0;
  reg [1:0]              cycle              = 'd0;  // for simulation to track few cycles of the whole process to make sure after reset nothing funny is happening

  localparam  ENUM_STATE_TRANSMIT = 0;   // If I will make SystemVerilog variant then use proper enums for this
  localparam  ENUM_STATE_RESET    = 1;
  
  
  // as combinational logic should be enough
  // https://electronics.stackexchange.com/questions/29553/how-are-verilog-always-statements-implemented-in-hardware
  always @(*) begin
    case (pixel_value[pixel_bit_index])
      // depending on the current bit decide what pattern to push
      // patterns are ordered from right to left
      1'b0: neo_pattern_lookup = 12'b000000000111;
      1'b1: neo_pattern_lookup = 12'b000011111111;
    endcase
  end


  always @(*) begin
    `ifdef HARDCODED_PIXELS
      // hardcoded predefined colors for 3 pixels in a strip
      // TODO: use casez so bigger arrays could be auto filled with these values
      case (pixel_index)
        'd0: pixel_value = 24'hff00d5;
        'd1: pixel_value = 24'h008800;
        'd2: pixel_value = 24'h000090;
        default:  pixel_value = 24'h101010;  // slightly light to show there might be problem in configuration
      endcase
    `else
      pixel_value = { 
                      5'b00000,  pixels[pixel_index][7:5], 
                      6'b000000, pixels[pixel_index][1:0], 
                      5'b00000,  pixels[pixel_index][4:2] 
                    };
    `endif
  end


  always @(*) begin
    if (state == ENUM_STATE_TRANSMIT) begin
      // push patterns of the bit inside a pixel 
      data_int = neo_pattern_lookup[bit_pattern_index];
    end else begin
      // reset state, stay LOW
      data_int = 'd0;
    end
  end


  always @(posedge clk10mhz) begin
    if (busWrite) begin
      // TODO: write tester for these writes
      pixels[busAddr[2:0]] <= busData;
    end else begin
      if (state == ENUM_STATE_TRANSMIT) begin

        if (bit_pattern_index < 'd11) begin
          // from 'd0 to 'd10 => 11 sub-bit ticks increment by one
          bit_pattern_index <= bit_pattern_index + 'b1;
        end else begin
          // for the 'd11 = 12th last sub-bit start with new bit and start sub-bit ticks from beging
          bit_pattern_index <= 'b0;

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
          end        
        end
      end else begin
        // when in the reset state, count 50ns (RESET_DELAY / 10)
        reset_delay_count <= reset_delay_count + 'b1;

        if (reset_delay_count > RESET_DELAY) begin  
          // predefined wait in reset state was reached, let's 
          state <= 'd0;
          if (cycle == 'd3) $finish; // stop simulation here, went through all pixels and a reset twice
          cycle <= cycle + 'd1;
          reset_delay_count <= 'd0;
        end
      end
    end
  end


  assign neoData  = data_int;
  assign neoState = state;
  
endmodule