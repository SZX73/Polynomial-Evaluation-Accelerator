Design 3: Semi-Pipelined PEA Implementation

This design implements a two-phase execution model for polynomial evaluation.
Phase 1 pre-loads all coefficients into a local buffer, then Phase 2 computes
using only the buffer (zero memory access stalls during computation).

Architecture:
- Same hierarchical 3-level FSM structure as Design 1
- Key difference: Uses evp_compute_fsm_3_pipeline instead of evp_compute_fsm_3
- Two-phase architecture separates memory access from computation

Key Modules:
- evp_compute_fsm_3_pipeline.v : ★ Semi-pipelined computation FSM
- All other modules same as Design 1

Two Phases:
Phase 1 - LOAD (N+1 cycles):
  - Read all coefficients from RAM into local coeff_buf[0..N] registers
  - Memory is accessed sequentially

Phase 2 - COMPUTE (N cycles):
  - Initialize: result = coeff_buf[N]
  - Loop: result = (result × x) + coeff_buf[i] for i = N-1 to 0
  - NO memory access during this phase (zero stalls!)

Advantages:
- Memory is free during compute phase for other operations
- Deterministic compute timing (no memory latency variation)
- Same hardware resources as Design 1

Performance:
- Cycles per EVP (degree N): 2N + 3 cycles
- For degree-10 polynomial: ~24 cycles
