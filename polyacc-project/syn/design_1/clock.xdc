# Define a clock with a 10ns period (100 MHz)
# This gives Vivado a target to calculate timing against.
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]


