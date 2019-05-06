-makelib xcelium_lib/xil_defaultlib -sv \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/opt/local/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../regionizer.srcs/sources_1/ip/regionizer_clocks/regionizer_clocks_clk_wiz.v" \
  "../../../../regionizer.srcs/sources_1/ip/regionizer_clocks/regionizer_clocks.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

