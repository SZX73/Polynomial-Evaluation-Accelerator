#ifndef _PEA_C_ACTOR_H
#define _PEA_C_ACTOR_H

#include <lide_c_basic.h> 
#include <lide_c_actor.h>
#include <lide_c_fifo.h>
#include <lide_c_util.h>

// Constants //

/* Actor Instructions (from Control FIFO) */
#define INST_STP 0x01 // Store Polynomial
#define INST_EVP 0x02 // Evaluate Polynomial
#define INST_EVB 0x03 // Evaluate Block
#define INST_RST 0x04 // Reset

/* Status Codes (to Status FIFO) */
#define STATUS_OK 0x00
#define STATUS_ERROR_POLY_INVALID 0xE0
#define STATUS_ERROR_UNKNOWN_INST 0xE1

/* Polynomial Storage Limits */
#define MAX_POLYNOMIALS 8
#define MAX_DEGREE 10
#define MAX_COEFFICIENTS (MAX_DEGREE + 1)

// Actor Modes (Internal States) //

#define MODE_IDLE 0               // Waiting for a new instruction
#define MODE_RST_EXECUTE 1        // Executing the RST instruction
#define MODE_STP_READ_ARGS 2      // Reading A (address) and N (degree) for STP
#define MODE_STP_READ_COEFS 3    // Reading N+1 coefficients for STP
#define MODE_EVP_READ_ARGS 4      // Reading A (address) for EVP
#define MODE_EVP_READ_X 5         // Reading x value for EVP
#define MODE_EVP_COMPUTE 6        // Computing p(x) for EVP
#define MODE_EVP_WRITE_RESULT 7   // Writing result for EVP
#define MODE_EVP_WRITE_STATUS 8   // Writing status for EVP
#define MODE_EVB_READ_ARGS 9      // Reading A (address) and b (block size) for EVB
#define MODE_EVB_READ_X 10        // Reading next x value for EVB (loop start)
#define MODE_EVB_COMPUTE 11       // Computing p(x) for EVB
#define MODE_EVB_WRITE_RESULT 12  // Writing result for EVB
#define MODE_EVB_WRITE_STATUS 13  // Writing status for EVB (loop end)
#define MODE_ERROR_UNKNOWN_INST 14 // Handle unknown instruction

// Actor Context (Instance) Structure //

/* This struct holds the internal state of a single PEA actor instance. */
typedef struct {
    #include <lide_c_actor_context_type_common.h>

    /* FIFO connections (ports) - CORRECTED */
    lide_c_fifo_pointer control_in;
    lide_c_fifo_pointer data_in;
    lide_c_fifo_pointer result_out;
    lide_c_fifo_pointer status_out;

    /* Internal Storage for Polynomials */
    // Array of pointers to coefficient data
    int *polynomials[MAX_POLYNOMIALS];
    // Array to store the degree (N) of each polynomial
    int degrees[MAX_POLYNOMIALS];

    /* State variables for multi-cycle instructions */
    int current_instruction; // The instruction being processed (STP, EVP, etc.)
    int current_poly_addr;   // The 'A' value (0-7)
    int current_poly_degree; // The 'N' value (0-10)
    int current_block_size;  // The 'b' value for EVB
    int block_counter;       // Loop counter for EVB (counts from 0 to b-1)
    int coeff_counter;       // Loop counter for STP (counts from 0 to N)
    int current_x;           // The 'x' value being evaluated
    int current_result;      // The computed 'p(x)' result
    int current_status;      // The status code to be written

} lide_c_pea_actor_context_type;

// Actor Interface Function Prototype //

/* Constructor */
lide_c_pea_actor_context_type *lide_c_pea_actor_new(
    lide_c_fifo_pointer control_in,
    lide_c_fifo_pointer data_in,
    lide_c_fifo_pointer result_out,
    lide_c_fifo_pointer status_out);

/* Enable function */
bool lide_c_pea_actor_enable(lide_c_pea_actor_context_type *context);

/* Invoke function */
void lide_c_pea_actor_invoke(lide_c_pea_actor_context_type *context);

/* Destructor */
void lide_c_pea_actor_terminate(lide_c_pea_actor_context_type *context);

#endif

