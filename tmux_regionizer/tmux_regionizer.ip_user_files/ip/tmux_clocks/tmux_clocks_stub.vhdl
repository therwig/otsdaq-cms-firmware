-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
-- Date        : Sun Apr 21 22:13:43 2019
-- Host        : kenny01.dhcp.fnal.gov running 64-bit CentOS Linux release 7.6.1810 (Core)
-- Command     : write_vhdl -force -mode synth_stub -rename_top tmux_clocks -prefix
--               tmux_clocks_ tmux_clocks_stub.vhdl
-- Design      : tmux_clocks
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flgb2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tmux_clocks is
  Port ( 
    clk_40 : out STD_LOGIC;
    clk_240 : out STD_LOGIC;
    clk_360 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end tmux_clocks;

architecture stub of tmux_clocks is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_40,clk_240,clk_360,reset,locked,clk_in1";
begin
end;
