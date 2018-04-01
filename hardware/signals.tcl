lappend signals "TOP.anton_neopixel_top.CLK_10MHZ"
lappend signals "TOP.anton_neopixel_top.NEO_DATA"
lappend signals "TOP.anton_neopixel_top.state"
lappend signals "TOP.anton_neopixel_top.counter"
lappend signals "TOP.anton_neopixel_top.bit_clk"
lappend signals "TOP.anton_neopixel_top.bit_counter"
lappend signals "TOP.anton_neopixel_top.neo_lookup"
lappend signals "TOP.anton_neopixel_top.pixel"


set num_added [ gtkwave::addSignalsFromList $signals ]
