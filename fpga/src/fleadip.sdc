create_clock -period 20         clk_in_50
# With correct time interval of 9.9291 the Efinity tool can't determine the clock 
# relationship properly between the VDP clocks - "unexpandable clock pairs found in design"
# Trying to set clock relationships does not fix this error. So set to 10 instead and keep
# an eye on fmax.
create_clock -period 10         clk_100
create_generated_clock -source  clk_100 -divide_by    4 clk_25
create_generated_clock -source  clk_25  -multiply_by  2 clk_50
create_generated_clock -source  clk_25  -multiply_by 10 clk_250

create_clock -period 2235.0769  clk_grom
create_clock -period 100.0000   clk_in_z80_10
create_generated_clock -source  clk_in_z80_10 -multiply_by 5 clk_z80_50

# set_clock_groups -exclusive -group {clk_25} -group { clk_50 clk_100 clk_250}
set_clock_groups -asynchronous -group {clk_in_z80_10 clk_z80_50} -group {clk_100 clk_25 clk_50 clk_250}
set_clock_groups -asynchronous -group {clk_grom} -group {clk_100 clk_25 clk_50 clk_250}
set_clock_groups -asynchronous -group {clk_grom} -group {clk_in_50 clk_in_z80_10 clk_z80_50}
set_clock_groups -asynchronous -group {clk_in_50} -group {clk_100 clk_25 clk_50 clk_250}
set_clock_groups -asynchronous -group {clk_in_50} -group {clk_in_z80_10 clk_z80_50}
