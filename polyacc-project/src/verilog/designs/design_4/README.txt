Design 4: Serial Multiplier PEA Implementation (Resource-Optimized)

This design implements polynomial evaluation using a serial shift-and-add
multiplier instead of relying on synthesized hardware multipliers or DSP
blocks. This results in zero DSP block usage but significantly slower
computation.

Architecture
- Same hierarchical 3-level FSM structure as Design 1
- KEY DIFFERENCE: evp_compute_fsm_3 uses shift-and-add for multiplication
- 16 clock cycles required per multiply operation

Key Modules:
- evp_compute_fsm_3.v : ★ Serial multiplier implementation
- All other modules same as Design 1

Serial Multiplier Algorithm:
For each multiplication (accumulator × x):
  1. MULT_INIT: Initialize partial_product = 0, load multiplier and multiplicand
  2. MULT_SHIFT (16 iterations):
     - If multiplier[0] == 1: partial_product += multiplicand
     - multiplier >>= 1  (shift right)
     - multiplicand <<= 1 (shift left)
  3. Result available after 16 cycles

States:
IDLE → START_READ → WAIT_READ → MULT_INIT → MULT_SHIFT (×16) →
WAIT_COEFF → ADD_COEFF → (loop or DONE)

Use case:
- Minimum resource FPGA/ASIC targets where DSP blocks are unavailable
- Applications where area is critical and latency is acceptable
- Educational demonstration of serial arithmetic

Performance:
- Cycles per EVP (degree N): approximately 18N + 5 cycles
- For degree-10 polynomial: ~185 cycles
- Trade-off: Much slower but uses zero DSP slices
