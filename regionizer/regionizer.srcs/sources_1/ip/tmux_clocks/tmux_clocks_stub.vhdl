-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
-- Date        : Mon Apr 22 12:11:54 2019
-- Host        : correlator2.fnal.gov running 64-bit Scientific Linux release 7.6 (Nitrogen)
-- Command     : write_vhdl -force -mode synth_stub
--               /data/rrivera/CorrelatorTrigger/otsdaq-cms-firmware/regionizer/regionizer.srcs/sources_1/ip/tmux_clocks/tmux_clocks_stub.vhdl
-- Design      : tmux_clocks
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flgb2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tmux_clocks is
  Port ( 
    clk_40 : out STD_LOGIC;
    clk_120 : out STD_LOGIC;
    clk_240 : out STD_LOGIC;
    clk_320 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end tmux_clocks;

architecture stub of tmux_clocks is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_40,clk_120,clk_240,clk_320,reset,locked,clk_in1";
begin
end;
