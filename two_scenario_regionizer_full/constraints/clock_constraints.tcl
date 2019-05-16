###########################################
#
# constraints for the Regionizer
#
###########################################

create_clock -name link_clk -period 3.32 [get_pins link_clk_ibufg/O]


#ignore timing from clk 40 things to chipscope
#set_max_delay 32.00 -from [get_clocks CLK_bmx_40] -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ u_ila*/*)}]
#set_max_delay 32.00 -from [get_clocks CLK_bmx_40] -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ u_ila*/*/*)}]

#give lots of time for static register max values 
#set_max_delay 32.00 -from [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/*/*/phi_max_reg*)}]

#give lots of time for static read (should have address setup for 64)
#set_max_delay 32.00 -through [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U311/*)}]

#give time through output muxes to counters
#set_max_delay 32.00 -through [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U43/*)}]  -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U351/*)}]
#set_max_delay 32.00 -through [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U127/*)}] -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U353/*)}]
#set_max_delay 32.00 -through [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U187/*)}] -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U355/*)}]
#set_max_delay 32.00 -through [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U197/*)}] -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U357/*)}]
##and from output muxes to to burst trigger gate
#set_max_delay 64.00 -to [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U421/*)}]

##give time from static clock mux control register routing
#set_max_delay 32.00 -from [get_cells * -hierarchical -filter {IS_PRIMITIVE == true && (NAME =~ NIM_BLOCK/U211/*)}]

## In xdc, all clocks are related by default. This differs from ucf, where clocks are unrelated unless specified otherwise. As a result, you may now see cross-clock paths that were previously unconstrained in ucf. Commented out xdc false path constraints have been generated and can be uncommented, should you wish to remove these new paths. These commands are located after the last clock definition

#create_clock -name PHY_RXCLK -period 8.000 [get_ports PHY_RXCLK]

#create_clock -name CLK_bmx_320 -period 3.125 [get_pins CLK_mx_320_bufg/O]
#create_clock -name CLK_bmx_320 -period 6.25 [get_pins CLK_mx_160_bufg/O]
#create_clock -name CLK_bmx_40 -period 25.000 [get_pins CLK_mx_40_bufg/O]

#create_clock -name DAC_SER_CLK -period 160.000 [get_ports DAC_SER_CLK]

#create_clock -name DAC_IN_CLK -period 80.000 [get_pins DAC_CLK_bufg/O]


#set_false_path -from [get_clocks PHY_RXCLK] -to [get_clocks [list CLK_bmx_320 CLK_bmx_40 DAC_SER_CLK DAC_IN_CLK]]
#set_false_path -from [get_clocks CLK_bmx_320] -to [get_clocks [list PHY_RXCLK DAC_SER_CLK DAC_IN_CLK]]
#set_false_path -from [get_clocks CLK_bmx_40] -to [get_clocks [list PHY_RXCLK DAC_SER_CLK DAC_IN_CLK]]

#set_false_path -from [get_clocks DAC_SER_CLK] -to [get_clocks [list CLK_bmx_320 CLK_bmx_40 PHY_RXCLK DAC_IN_CLK]]
#set_false_path -from [get_clocks DAC_IN_CLK] -to [get_clocks [list CLK_bmx_320 CLK_bmx_40 PHY_RXCLK DAC_SER_CLK]]


