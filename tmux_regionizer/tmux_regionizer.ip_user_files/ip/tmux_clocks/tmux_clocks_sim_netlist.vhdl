-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
-- Date        : Sun Apr 21 22:13:43 2019
-- Host        : kenny01.dhcp.fnal.gov running 64-bit CentOS Linux release 7.6.1810 (Core)
-- Command     : write_vhdl -force -mode funcsim -rename_top tmux_clocks -prefix
--               tmux_clocks_ tmux_clocks_sim_netlist.vhdl
-- Design      : tmux_clocks
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xcvu9p-flgb2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity tmux_clocks_tmux_clocks_clk_wiz is
  port (
    clk_40 : out STD_LOGIC;
    clk_240 : out STD_LOGIC;
    clk_360 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );
end tmux_clocks_tmux_clocks_clk_wiz;

architecture STRUCTURE of tmux_clocks_tmux_clocks_clk_wiz is
  signal clk_240_tmux_clocks : STD_LOGIC;
  signal clk_360_tmux_clocks : STD_LOGIC;
  signal clk_40_tmux_clocks : STD_LOGIC;
  signal clk_in1_tmux_clocks : STD_LOGIC;
  signal clkfbout_buf_tmux_clocks : STD_LOGIC;
  signal clkfbout_tmux_clocks : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CDDCDONE_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKFBOUTB_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKFBSTOPPED_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKINSTOPPED_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT0B_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT1B_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT2B_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT3_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT3B_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT4_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT5_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_CLKOUT6_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_DRDY_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_PSDONE_UNCONNECTED : STD_LOGIC;
  signal NLW_mmcme4_adv_inst_DO_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of clkf_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM : string;
  attribute XILINX_LEGACY_PRIM of clkf_buf : label is "BUFG";
  attribute BOX_TYPE of clkin1_bufg : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM of clkin1_bufg : label is "BUFG";
  attribute BOX_TYPE of clkout1_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM of clkout1_buf : label is "BUFG";
  attribute BOX_TYPE of clkout2_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM of clkout2_buf : label is "BUFG";
  attribute BOX_TYPE of clkout3_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM of clkout3_buf : label is "BUFG";
  attribute BOX_TYPE of mmcme4_adv_inst : label is "PRIMITIVE";
begin
clkf_buf: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC"
    )
        port map (
      CE => '1',
      I => clkfbout_tmux_clocks,
      O => clkfbout_buf_tmux_clocks
    );
clkin1_bufg: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC"
    )
        port map (
      CE => '1',
      I => clk_in1,
      O => clk_in1_tmux_clocks
    );
clkout1_buf: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC"
    )
        port map (
      CE => '1',
      I => clk_40_tmux_clocks,
      O => clk_40
    );
clkout2_buf: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC"
    )
        port map (
      CE => '1',
      I => clk_240_tmux_clocks,
      O => clk_240
    );
clkout3_buf: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC"
    )
        port map (
      CE => '1',
      I => clk_360_tmux_clocks,
      O => clk_360
    );
mmcme4_adv_inst: unisim.vcomponents.MMCME4_ADV
    generic map(
      BANDWIDTH => "OPTIMIZED",
      CLKFBOUT_MULT_F => 12.000000,
      CLKFBOUT_PHASE => 0.000000,
      CLKFBOUT_USE_FINE_PS => "FALSE",
      CLKIN1_PERIOD => 8.333000,
      CLKIN2_PERIOD => 0.000000,
      CLKOUT0_DIVIDE_F => 36.000000,
      CLKOUT0_DUTY_CYCLE => 0.500000,
      CLKOUT0_PHASE => 0.000000,
      CLKOUT0_USE_FINE_PS => "FALSE",
      CLKOUT1_DIVIDE => 6,
      CLKOUT1_DUTY_CYCLE => 0.500000,
      CLKOUT1_PHASE => 0.000000,
      CLKOUT1_USE_FINE_PS => "FALSE",
      CLKOUT2_DIVIDE => 4,
      CLKOUT2_DUTY_CYCLE => 0.500000,
      CLKOUT2_PHASE => 0.000000,
      CLKOUT2_USE_FINE_PS => "FALSE",
      CLKOUT3_DIVIDE => 1,
      CLKOUT3_DUTY_CYCLE => 0.500000,
      CLKOUT3_PHASE => 0.000000,
      CLKOUT3_USE_FINE_PS => "FALSE",
      CLKOUT4_CASCADE => "FALSE",
      CLKOUT4_DIVIDE => 1,
      CLKOUT4_DUTY_CYCLE => 0.500000,
      CLKOUT4_PHASE => 0.000000,
      CLKOUT4_USE_FINE_PS => "FALSE",
      CLKOUT5_DIVIDE => 1,
      CLKOUT5_DUTY_CYCLE => 0.500000,
      CLKOUT5_PHASE => 0.000000,
      CLKOUT5_USE_FINE_PS => "FALSE",
      CLKOUT6_DIVIDE => 1,
      CLKOUT6_DUTY_CYCLE => 0.500000,
      CLKOUT6_PHASE => 0.000000,
      CLKOUT6_USE_FINE_PS => "FALSE",
      COMPENSATION => "BUF_IN",
      DIVCLK_DIVIDE => 1,
      IS_CLKFBIN_INVERTED => '0',
      IS_CLKIN1_INVERTED => '0',
      IS_CLKIN2_INVERTED => '0',
      IS_CLKINSEL_INVERTED => '0',
      IS_PSEN_INVERTED => '0',
      IS_PSINCDEC_INVERTED => '0',
      IS_PWRDWN_INVERTED => '0',
      IS_RST_INVERTED => '0',
      REF_JITTER1 => 0.010000,
      REF_JITTER2 => 0.010000,
      SS_EN => "FALSE",
      SS_MODE => "CENTER_HIGH",
      SS_MOD_PERIOD => 10000,
      STARTUP_WAIT => "FALSE"
    )
        port map (
      CDDCDONE => NLW_mmcme4_adv_inst_CDDCDONE_UNCONNECTED,
      CDDCREQ => '0',
      CLKFBIN => clkfbout_buf_tmux_clocks,
      CLKFBOUT => clkfbout_tmux_clocks,
      CLKFBOUTB => NLW_mmcme4_adv_inst_CLKFBOUTB_UNCONNECTED,
      CLKFBSTOPPED => NLW_mmcme4_adv_inst_CLKFBSTOPPED_UNCONNECTED,
      CLKIN1 => clk_in1_tmux_clocks,
      CLKIN2 => '0',
      CLKINSEL => '1',
      CLKINSTOPPED => NLW_mmcme4_adv_inst_CLKINSTOPPED_UNCONNECTED,
      CLKOUT0 => clk_40_tmux_clocks,
      CLKOUT0B => NLW_mmcme4_adv_inst_CLKOUT0B_UNCONNECTED,
      CLKOUT1 => clk_240_tmux_clocks,
      CLKOUT1B => NLW_mmcme4_adv_inst_CLKOUT1B_UNCONNECTED,
      CLKOUT2 => clk_360_tmux_clocks,
      CLKOUT2B => NLW_mmcme4_adv_inst_CLKOUT2B_UNCONNECTED,
      CLKOUT3 => NLW_mmcme4_adv_inst_CLKOUT3_UNCONNECTED,
      CLKOUT3B => NLW_mmcme4_adv_inst_CLKOUT3B_UNCONNECTED,
      CLKOUT4 => NLW_mmcme4_adv_inst_CLKOUT4_UNCONNECTED,
      CLKOUT5 => NLW_mmcme4_adv_inst_CLKOUT5_UNCONNECTED,
      CLKOUT6 => NLW_mmcme4_adv_inst_CLKOUT6_UNCONNECTED,
      DADDR(6 downto 0) => B"0000000",
      DCLK => '0',
      DEN => '0',
      DI(15 downto 0) => B"0000000000000000",
      DO(15 downto 0) => NLW_mmcme4_adv_inst_DO_UNCONNECTED(15 downto 0),
      DRDY => NLW_mmcme4_adv_inst_DRDY_UNCONNECTED,
      DWE => '0',
      LOCKED => locked,
      PSCLK => '0',
      PSDONE => NLW_mmcme4_adv_inst_PSDONE_UNCONNECTED,
      PSEN => '0',
      PSINCDEC => '0',
      PWRDWN => '0',
      RST => reset
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity tmux_clocks is
  port (
    clk_40 : out STD_LOGIC;
    clk_240 : out STD_LOGIC;
    clk_360 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of tmux_clocks : entity is true;
end tmux_clocks;

architecture STRUCTURE of tmux_clocks is
begin
inst: entity work.tmux_clocks_tmux_clocks_clk_wiz
     port map (
      clk_240 => clk_240,
      clk_360 => clk_360,
      clk_40 => clk_40,
      clk_in1 => clk_in1,
      locked => locked,
      reset => reset
    );
end STRUCTURE;