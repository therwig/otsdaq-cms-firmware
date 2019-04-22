onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xil_defaultlib -L xpm -L blk_mem_gen_v8_4_2 -L work -L unisims_ver -L unimacro_ver -L secureip -lib work work.algo_object_bram work.glbl

do {wave.do}

view wave
view structure
view signals

do {algo_object_bram.udo}

run -all

quit -force
