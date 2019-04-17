vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/xpm
vlib questa_lib/msim/work

vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap xpm questa_lib/msim/xpm
vmap work questa_lib/msim/work

vlog -work xil_defaultlib -64 -sv "+incdir+../../../ipstatic" "+incdir+../../../ipstatic" \
"/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work work -64 "+incdir+../../../ipstatic" "+incdir+../../../ipstatic" \
"../../../../tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks_clk_wiz.v" \
"../../../../tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks.v" \

vlog -work work \
"glbl.v"

