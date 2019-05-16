onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+regionizer_clocks -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.regionizer_clocks xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {regionizer_clocks.udo}

run -all

endsim

quit -force
