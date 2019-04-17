vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/work

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm
vmap work modelsim_lib/msim/work

vlog -work xil_defaultlib -64 -incr -sv "+incdir+../../../ipstatic" "+incdir+../../../ipstatic" \
"/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work work -64 -incr "+incdir+../../../ipstatic" "+incdir+../../../ipstatic" \
"../../../../tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks_clk_wiz.v" \
"../../../../tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks.v" \

vlog -work work \
"glbl.v"

