-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
-- Date        : Tue Apr 30 12:14:08 2019
-- Host        : correlator2.fnal.gov running 64-bit Scientific Linux release 7.6 (Nitrogen)
-- Command     : write_vhdl -force -mode synth_stub -rename_top regionizer_clocks -prefix
--               regionizer_clocks_ regionizer_clocks_stub.vhdl
-- Design      : regionizer_clocks
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flgb2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity regionizer_clocks is
  Port ( 
    clk_40 : out STD_LOGIC;
    clk_120 : out STD_LOGIC;
    clk_240 : out STD_LOGIC;
    clk_320 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    link_clk : in STD_LOGIC
  );

end regionizer_clocks;

architecture stub of regionizer_clocks is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_40,clk_120,clk_240,clk_320,reset,locked,link_clk";
begin
end;
