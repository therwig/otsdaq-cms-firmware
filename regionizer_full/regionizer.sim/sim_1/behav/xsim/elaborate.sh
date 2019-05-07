#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2018.2 (64-bit)
#
# Filename    : elaborate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for elaborating the compiled design
#
# Generated by Vivado on Tue May 07 10:09:34 CDT 2019
# SW Build 2258646 on Thu Jun 14 20:02:38 MDT 2018
#
# Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
#
# usage: elaborate.sh
#
# ****************************************************************************
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep xelab -wto 8e6c7d0b230e4011aade48dfa24eefb2 --incr --debug typical --relax --mt 8 -L fifo_generator_v13_2_2 -L xil_defaultlib -L work -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot regionizer_tb_behav work.regionizer_tb work.glbl -log elaborate.log
