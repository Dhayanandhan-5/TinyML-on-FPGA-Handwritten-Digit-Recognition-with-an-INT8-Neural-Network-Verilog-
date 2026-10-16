set_property PACKAGE_PIN F14 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 83.333 [get_ports clk]

set_property PACKAGE_PIN H14 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property PACKAGE_PIN H18 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

set_property PACKAGE_PIN H15 [get_ports {mm[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mm[3]}]

set_property PACKAGE_PIN E13 [get_ports {mm[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mm[2]}]

set_property PACKAGE_PIN F13 [get_ports {mm[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mm[1]}]

set_property PACKAGE_PIN E18 [get_ports {mm[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mm[0]}]




