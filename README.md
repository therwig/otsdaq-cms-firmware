#Repository for P2L1PF Regionizer

##Prepare inputs
Start from text file produced using `GlobalCorrelator_HLS` code
```
cd regionizer_full_sw/tmux_sw/
g++ create_tmux_inputs.cpp
./a.out <input file> ../../regionizer_full/sim/sim_data/ 96
cd -
```
General usage is `./a.out <input file> <folder for resulting input files> <number of links>`

##Run simulation:
```
cd regionizer_full
vivado -mode batch -source run_behav_sim.tcl
```
Outputs will go to `regionizer_full/sim/sim_data`

Can then check consistency with emulator results from `GlobalCorrelator_HLS` code
