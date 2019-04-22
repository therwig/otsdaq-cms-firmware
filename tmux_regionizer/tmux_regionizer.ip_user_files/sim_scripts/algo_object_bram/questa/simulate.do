onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib work algo_object_bram_opt

do {wave.do}

view wave
view structure
view signals

do {algo_object_bram.udo}

run -all

quit -force
