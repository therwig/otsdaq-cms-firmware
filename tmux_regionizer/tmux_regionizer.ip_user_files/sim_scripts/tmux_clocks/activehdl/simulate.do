onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+tmux_clocks -L xil_defaultlib -L xpm -L work -L unisims_ver -L unimacro_ver -L secureip -O5 work.tmux_clocks work.glbl

do {wave.do}

view wave
view structure

do {tmux_clocks.udo}

run -all

endsim

quit -force
