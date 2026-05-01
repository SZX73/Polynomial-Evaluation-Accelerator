Design 2: Dual-MAC Partially Unrolled PEA Implementation=

This design unrolls the iterative Horner's method computation by a factor of 2,
processing two coefficients per clock cycle. This provides approximately 1.8×
speedup compared to the baseline Design 1.

Architecture:
- Same hierarchical 3-level FSM structure as Design 1
- KEY DIFFERENCE: Uses evp_compute_fsm_3_dual instead of evp_compute_fsm_3
- Dual-MAC datapath computes: result = ((result × x) + coeff_hi) × x + coeff_lo

Key Modules:
- evp_compute_fsm_3_dual.v : ★ Dual-MAC computation FSM (2 coefficients/cycle)
- All other modules same as Design 1

Dual-mac Operation:
Each compute cycle performs:
1. Read coefficient[i] (high)
2. Read coefficient[i-1] (low)  
3. Compute: result = ((result × x) + coeff_hi) × x + coeff_lo
4. Handle odd-degree polynomials with COMPUTE_FINAL state

Performance:
- Cycles per EVP (degree N): approximately 1.5N + 5 cycles
- For degree-10 polynomial: ~18 cycles
- Speedup vs Design 1: ~1.8×
