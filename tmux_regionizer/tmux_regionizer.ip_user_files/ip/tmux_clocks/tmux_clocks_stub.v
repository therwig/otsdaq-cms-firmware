// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
// Date        : Sun Apr  7 11:29:28 2019
// Host        : correlator2.fnal.gov running 64-bit Scientific Linux release 7.6 (Nitrogen)
// Command     : write_verilog -force -mode synth_stub
//               /data/rrivera/CorrelatorTrigger/otsdaq-cms-firmware/tmux_regionizer/tmux_regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks_stub.v
// Design      : tmux_clocks
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1927-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module tmux_clocks(clk_40, clk_240, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_40,clk_240,reset,locked,clk_in1" */;
  output clk_40;
  output clk_240;
  input reset;
  output locked;
  input clk_in1;
endmodule
