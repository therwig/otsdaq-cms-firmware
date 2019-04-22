onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib work physics_object_bram_opt

do {wave.do}

view wave
view structure
view signals

do {physics_object_bram.udo}

run -all

quit -force
