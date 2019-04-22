// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
// Date        : Sun Apr 21 22:13:43 2019
// Host        : kenny01.dhcp.fnal.gov running 64-bit CentOS Linux release 7.6.1810 (Core)
// Command     : write_verilog -force -mode synth_stub -rename_top tmux_clocks -prefix
//               tmux_clocks_ tmux_clocks_stub.v
// Design      : tmux_clocks
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flgb2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module tmux_clocks(clk_40, clk_240, clk_360, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_40,clk_240,clk_360,reset,locked,clk_in1" */;
  output clk_40;
  output clk_240;
  output clk_360;
  input reset;
  output locked;
  input clk_in1;
endmodule
