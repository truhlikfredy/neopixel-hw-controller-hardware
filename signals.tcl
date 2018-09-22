lappend signals "TOP.anton_neopixel_apb_top.apbPclk"
lappend signals "TOP.clk7mhz"
lappend signals "TOP.syncStart"
lappend signals "TOP.neoData"
lappend signals "TOP.neoState"

lappend signals "TOP.anton_neopixel_apb_top_top.neopixel.stream.neo_pattern_lookup"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream.pixel_colour_value"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.bit_pattern_index"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixel_bit_index"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixel_index"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixel_index_equiv"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixel_index_max"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.reset_delay_count"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.reset_delay"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.cycle"
lappend signals "TOP.anton_neopixel_apb_top.test_unit"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_output"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_reset"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_pattern_of"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_bit_of"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_pixel_last"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_pixel_of"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.stream_sync_of"

lappend signals "TOP.anton_neopixel_apb_top.apbPselx"
lappend signals "TOP.anton_neopixel_apb_top.wr_enable"
lappend signals "TOP.anton_neopixel_apb_top.apbPwData"
lappend signals "TOP.anton_neopixel_apb_top.apbPrData"
lappend signals "TOP.anton_neopixel_apb_top.apbPaddr"
lappend signals "TOP.anton_neopixel_apb_top.address"
lappend signals "TOP.anton_neopixel_apb_top.pixelsSynch"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_max"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_ctrl_init"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.initSlow"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.initSlowDone"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_ctrl_run"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_ctrl_loop"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_ctrl_32bit"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_buffer_select"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_state_reset"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.reg_state_off"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.reset_reg_ctrl_run"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.cycle"

#lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(0)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(1)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(2)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(3)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(4)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(5)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(6)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(7)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(8)"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixels(9)"

set num_added [ gtkwave::addSignalsFromList $signals ]
