onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+algo_object_bram -L xil_defaultlib -L xpm -L blk_mem_gen_v8_4_2 -L work -L unisims_ver -L unimacro_ver -L secureip -O5 work.algo_object_bram work.glbl

do {wave.do}

view wave
view structure

do {algo_object_bram.udo}

run -all

endsim

quit -force
