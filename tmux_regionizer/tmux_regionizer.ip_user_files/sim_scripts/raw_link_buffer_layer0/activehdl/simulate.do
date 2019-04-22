onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+raw_link_buffer_layer0 -L xil_defaultlib -L xpm -L fifo_generator_v13_2_3 -L work -L unisims_ver -L unimacro_ver -L secureip -O5 work.raw_link_buffer_layer0 work.glbl

do {wave.do}

view wave
view structure

do {raw_link_buffer_layer0.udo}

run -all

endsim

quit -force
