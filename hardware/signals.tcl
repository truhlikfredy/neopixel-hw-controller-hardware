lappend signals "TOP.anton_neopixel_top.CLK_10MHZ"
lappend signals "TOP.anton_neopixel_top.NEODATA"
lappend signals "TOP.anton_neopixel_top.counter"
lappend signals "TOP.anton_neopixel_top.bit_counter"
lappend signals "TOP.anton_neopixel_top.bit_clk"
lappend signals "TOP.anton_neopixel_top.neolookup"
lappend signals "TOP.anton_neopixel_top.pixel"
lappend signals "TOP.anton_neopixel_top.state"

set num_added [ gtkwave::addSignalsFromList $signals ]
