// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
// Date        : Fri May  3 11:55:36 2019
// Host        : correlator2.fnal.gov running 64-bit Scientific Linux release 7.6 (Nitrogen)
// Command     : write_verilog -force -mode synth_stub
//               /data/rrivera/CorrelatorTrigger/otsdaq-cms-firmware/regionizer_full/regionizer.srcs/sources_1/ip/level1_fifo/level1_fifo_stub.v
// Design      : level1_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flgb2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_2,Vivado 2018.2" *)
module level1_fifo(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  almost_full, empty, wr_rst_busy, rd_rst_busy)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[63:0],wr_en,rd_en,dout[63:0],full,almost_full,empty,wr_rst_busy,rd_rst_busy" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [63:0]din;
  input wr_en;
  input rd_en;
  output [63:0]dout;
  output full;
  output almost_full;
  output empty;
  output wr_rst_busy;
  output rd_rst_busy;
endmodule
