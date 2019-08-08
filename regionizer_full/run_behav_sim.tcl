open_project /data/drankin/otsdaq-cms-firmware/regionizer_full/regionizer.xpr
reset_project
reset_target all [get_ips *]
generate_target all [get_ips *]
launch_simulation
