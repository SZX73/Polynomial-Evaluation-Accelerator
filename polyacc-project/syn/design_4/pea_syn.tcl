# POINT TO DESIGN 4 DIRECTORY
set srcDir "../../src/verilog/designs/design_4"

# 1. Read Shared Infrastructure
# Note: pea_memory.v in this design seems self-contained, 
# but we include single_port_ram.v just in case it is needed by other components.
read_verilog $srcDir/fifo.v
read_verilog $srcDir/single_port_ram.v
read_verilog $srcDir/pea_v_enable.v
read_verilog $srcDir/rst_fsm_3.v
read_verilog $srcDir/stp_read_coeffs_fsm_3.v
read_verilog $srcDir/evb_loop_fsm_3.v
read_verilog $srcDir/pea_v_invoke_top_module_FSM_1.v

# 2. DESIGN 4 SPECIFIC MODULES
# This version of pea_memory uses a single unified array (Unified Memory)
read_verilog $srcDir/pea_memory.v

# This version of firing_state connects to the Shift-Add compute module
read_verilog $srcDir/firing_state_FSM_2.v

# This is the "Less Hardware" Compute Module (Shift-Add Multiplier)
read_verilog $srcDir/evp_compute_fsm_3.v

# 3. TIMING CONSTRAINTS
read_xdc clock.xdc

# 4. Synthesize
synth_design -top pea_v_invoke_top_module_FSM_1 -part xczu5ev-fbvb900-2-i

# 5. Generate Reports
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt


