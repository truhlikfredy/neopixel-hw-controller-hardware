lappend signals "TOP.anton_neopixel_top.CLK_10MHZ"
lappend signals "TOP.anton_neopixel_top.NEO_DATA"
lappend signals "TOP.anton_neopixel_top.state"
lappend signals "TOP.anton_neopixel_top.reset_delay"
lappend signals "TOP.anton_neopixel_top.bit_pattern_index"
lappend signals "TOP.anton_neopixel_top.neo_pattern_lookup"
lappend signals "TOP.anton_neopixel_top.pixel_bit_index"
lappend signals "TOP.anton_neopixel_top.pixel_index"
lappend signals "TOP.anton_neopixel_top.pixel_value"

#lappend signals "TOP.anton_neopixel_top.pixels"


set num_added [ gtkwave::addSignalsFromList $signals ]
