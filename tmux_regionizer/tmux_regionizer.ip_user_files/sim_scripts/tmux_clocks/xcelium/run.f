-makelib xcelium_lib/xil_defaultlib -sv \
  "/home/tools/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/home/tools/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/home/tools/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/work \
  "../../../ip/tmux_clocks/tmux_clocks_clk_wiz.v" \
  "../../../ip/tmux_clocks/tmux_clocks.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

