-makelib xcelium_lib/xil_defaultlib -sv \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks_clk_wiz.v" \
  "../../../../tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

