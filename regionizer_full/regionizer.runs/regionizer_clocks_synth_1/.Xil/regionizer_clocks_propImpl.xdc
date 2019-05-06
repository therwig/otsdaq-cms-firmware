set_property SRC_FILE_INFO {cfile:/data/rrivera/CorrelatorTrigger/otsdaq-cms-firmware/regionizer_full/regionizer.srcs/sources_1/ip/regionizer_clocks/regionizer_clocks.xdc rfile:../../../regionizer.srcs/sources_1/ip/regionizer_clocks/regionizer_clocks.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports link_clk]] 0.033330000000000005
