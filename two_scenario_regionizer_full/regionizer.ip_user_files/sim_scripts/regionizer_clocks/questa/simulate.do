onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib regionizer_clocks_opt

do {wave.do}

view wave
view structure
view signals

do {regionizer_clocks.udo}

run -all

quit -force
