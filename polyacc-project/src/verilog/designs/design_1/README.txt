
Design 1: Baseline Iterative PEA Implementation

This is the baseline design for the Polynomial Evaluation Accelerator (PEA).
It implements a straightforward iterative approach to polynomial evaluation
using Horner's method with a single multiply-accumulate (MAC) operation per
clock cycle.

Architecture:
- Hierarchical 3-level FSM structure following LIDE-V conventions
- Level 1: pea_v_invoke_top_module_FSM_1 (invoke/FC handshake)
- Level 2: firing_state_FSM_2 (instruction decode and mode management)
- Level 3: Instruction-specific FSMs (stp, evp, evb, rst)

Key Modules:
- pea_v_enable.v          : Actor Enable Module (AEM)
- pea_v_invoke_top_module_FSM_1.v : Top-level Actor Invoke Module (AIM)
- firing_state_FSM_2.v    : Mode management and instruction dispatch
- evp_compute_fsm_3.v     : Horner's method computation (single MAC)
- stp_read_coeffs_fsm_3.v : Coefficient storage FSM
- evb_loop_fsm_3.v        : Block evaluation loop FSM
- rst_fsm_3.v             : Reset FSM
- pea_memory.v            : Memory subsystem (8 polynomials × 11 coefficients)
- single_port_ram.v       : RAM primitive
- fifo.v                  : FIFO buffer module

Performance:
- Cycles per EVP (degree N): approximately 3N + 3 cycles
- For degree-10 polynomial: ~33 cycles

