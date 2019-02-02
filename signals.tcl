lappend signals "TOP.anton_neopixel_apb_top.apbPclk"
lappend signals "TOP.clk6_4mhz"
lappend signals "TOP.syncStart"
lappend signals "TOP.neoData"
lappend signals "TOP.neoState"

lappend signals "TOP.anton_neopixel_apb_top_top.neopixel.stream.neoPatternLookup"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream.pixelColourValue"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.bitPatternIndex"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixelBitIndex"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.channelIndex"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixelIndex"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixelIndexEquiv"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.pixelIndexMax"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixelIndexComb"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.pixelByte"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.resetDelayCount"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.resetDelay"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.cycle"
lappend signals "TOP.anton_neopixel_apb_top.testUnit"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamOutput"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamReset"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamPatternOf"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamBitOf"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamChannelOf"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamPixelLast"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamPixelOf"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.stream_logic.streamSyncOf"

lappend signals "TOP.anton_neopixel_apb_top.apbPselx"
lappend signals "TOP.anton_neopixel_apb_top.wrEnable"
lappend signals "TOP.anton_neopixel_apb_top.rdEnable"
lappend signals "TOP.anton_neopixel_apb_top.apbPwData"
lappend signals "TOP.anton_neopixel_apb_top.apbPrData"
lappend signals "TOP.anton_neopixel_apb_top.apbPaddr"
lappend signals "TOP.anton_neopixel_apb_top.address"
lappend signals "TOP.anton_neopixel_apb_top.pixelsSynch"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.regMax"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.regCtrlInit"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.initSlow"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.initSlowDone"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.regCtrlRun"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.regCtrlLoop"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.regCtrl32bit"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.regStateReset"
lappend signals "TOP.anton_neopixel_apb_top.neopixel.regStateOff"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.resetRegCtrlRun"

lappend signals "TOP.anton_neopixel_apb_top.neopixel.cycle"


set num_added [ gtkwave::addSignalsFromList $signals ]
