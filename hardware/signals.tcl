lappend signals "TOP.clk10mhz"
lappend signals "TOP.neoData"
lappend signals "TOP.neoState"

lappend signals "TOP.anton_neopixel_apb.neopixel.reset_delay"
lappend signals "TOP.anton_neopixel_apb.neopixel.bit_pattern_index"
lappend signals "TOP.anton_neopixel_apb.neopixel.neo_pattern_lookup"
lappend signals "TOP.anton_neopixel_apb.neopixel.pixel_bit_index"
lappend signals "TOP.anton_neopixel_apb.neopixel.pixel_index"
lappend signals "TOP.anton_neopixel_apb.neopixel.pixel_value"

lappend signals "TOP.anton_neopixel_apb.wr_enable"
lappend signals "TOP.anton_neopixel_apb.apbPwData"
lappend signals "TOP.anton_neopixel_apb.apbPaddr"
lappend signals "TOP.anton_neopixel_apb.address"
lappend signals "TOP.anton_neopixel_apb.neopixel.pixels(0)"
lappend signals "TOP.anton_neopixel_apb.neopixel.pixels(1)"
lappend signals "TOP.anton_neopixel_apb.neopixel.pixels(2)"
lappend signals "TOP.anton_neopixel_apb.apbPclk"

#lappend signals "TOP.anton_neopixel_apb.neopixel.pixels"

set num_added [ gtkwave::addSignalsFromList $signals ]
