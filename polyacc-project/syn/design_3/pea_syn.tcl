# POINT TO DESIGN 3 SOURCE DIRECTORY
set srcDir "../../src/verilog/designs/design_3"

# 1. Shared Infrastructure
read_verilog $srcDir/fifo.v
read_verilog $srcDir/single_port_ram.v
read_verilog $srcDir/pea_memory.v
read_verilog $srcDir/pea_v_enable.v
read_verilog $srcDir/rst_fsm_3.v
read_verilog $srcDir/stp_read_coeffs_fsm_3.v
read_verilog $srcDir/evb_loop_fsm_3.v
read_verilog $srcDir/pea_v_invoke_top_module_FSM_1.v

# 2. DESIGN 3 SPECIFIC MODULES
# Note: firing_state_FSM_2.v here must be the version that instantiates the pipeline module!
read_verilog $srcDir/firing_state_FSM_2.v
read_verilog $srcDir/evp_compute_fsm_3_pipeline.v

# 3. TIMING CONSTRAINTS
read_xdc clock.xdc

# 4. Synthesize
synth_design -top pea_v_invoke_top_module_FSM_1 -part xczu5ev-fbvb900-2-i

# 5. Generate Reports
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt


