-makelib ies_lib/xil_defaultlib -sv \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib ies_lib/xpm \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks_clk_wiz.v" \
  "../../../../regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

