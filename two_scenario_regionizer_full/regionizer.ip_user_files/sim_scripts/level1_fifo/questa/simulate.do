onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib level1_fifo_opt

do {wave.do}

view wave
view structure
view signals

do {level1_fifo.udo}

run -all

quit -force
