#!/bin/sh

sed -i "s@/data/rrivera/CorrelatorTrigger/puppi_regionizer_repo/otsdaq-cms-firmware@$PWD@g" regionizer_full/sim/regionizer_TB.vhd
sed -i "s@/data/drankin/otsdaq-cms-firmware@$PWD@g" regionizer_full/run_behav_sim.tcl
