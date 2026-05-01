# POINT TO DESIGN 1 DIRECTORY
set srcDir "../../src/verilog/designs/design_1"

# 1. Read Verilog Files
read_verilog $srcDir/fifo.v
read_verilog $srcDir/single_port_ram.v
read_verilog $srcDir/pea_memory.v
read_verilog $srcDir/pea_v_enable.v
read_verilog $srcDir/rst_fsm_3.v
read_verilog $srcDir/stp_read_coeffs_fsm_3.v
read_verilog $srcDir/evb_loop_fsm_3.v
read_verilog $srcDir/firing_state_FSM_2.v
read_verilog $srcDir/pea_v_invoke_top_module_FSM_1.v

# DESIGN 1 SPECIFIC MODULE (Iterative)
read_verilog $srcDir/evp_compute_fsm_3.v

# 2. READ CONSTRAINTS
read_xdc clock.xdc

# 3. Synthesize
synth_design -top pea_v_invoke_top_module_FSM_1 -part xczu5ev-fbvb900-2-i

# 4. Generate Reports
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt
