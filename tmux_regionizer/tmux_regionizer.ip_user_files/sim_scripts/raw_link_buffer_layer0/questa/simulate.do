onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib work raw_link_buffer_layer0_opt

do {wave.do}

view wave
view structure
view signals

do {raw_link_buffer_layer0.udo}

run -all

quit -force
