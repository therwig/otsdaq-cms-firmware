onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xil_defaultlib -L xpm -L work -L unisims_ver -L unimacro_ver -L secureip -lib work work.tmux_clocks work.glbl

do {wave.do}

view wave
view structure
view signals

do {tmux_clocks.udo}

run -all

quit -force
