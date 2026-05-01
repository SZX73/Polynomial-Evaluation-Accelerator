#include <stdio.h>
#include <stdlib.h> 
#include <string.h>  
#include "pea_c_actor.h"

void pea_c_actor_reset(lide_c_pea_actor_context_type *context);
int pea_c_actor_compute_poly(int *coeffs, int degree, int x);

// Constructor // 
lide_c_pea_actor_context_type *lide_c_pea_actor_new(
    lide_c_fifo_pointer control_in,
    lide_c_fifo_pointer data_in,
    lide_c_fifo_pointer result_out,
    lide_c_fifo_pointer status_out) {

    lide_c_pea_actor_context_type *context = NULL;
    int i;

    context = (lide_c_pea_actor_context_type *)malloc(
        sizeof(lide_c_pea_actor_context_type));
    if (context == NULL) {
        return NULL;
    }

    /* Initialize context fields */
    context->enable = (lide_c_actor_enable_function_type)lide_c_pea_actor_enable;
    context->invoke = (lide_c_actor_invoke_function_type)lide_c_pea_actor_invoke;

    /* Connect FIFO ports */
    context->control_in = control_in;
    context->data_in = data_in;
    context->result_out = result_out;
    context->status_out = status_out;

    /* Initialize internal storage */
    for (i = 0; i < MAX_POLYNOMIALS; i++) {
        context->polynomials[i] = NULL;
        context->degrees[i] = -1;
    }

    /* Set initial state */
    pea_c_actor_reset(context); /* Use reset to init all state vars */
    context->mode = MODE_IDLE; 

    return context;
}

// Enable Function //
bool lide_c_pea_actor_enable(lide_c_pea_actor_context_type *context) {
    bool result = false;

    switch (context->mode) {
        case MODE_IDLE:
            result = (lide_c_fifo_population(context->control_in) >= 1);
            break;

        case MODE_RST_EXECUTE:
            result = true;
            break;

        case MODE_STP_READ_ARGS:
            result = (lide_c_fifo_population(context->control_in) >= 2);
            break;

        case MODE_STP_READ_COEFS:
            result = (lide_c_fifo_population(context->data_in) >= (context->current_poly_degree + 1));
            break;

        case MODE_EVP_READ_ARGS:
            result = (lide_c_fifo_population(context->control_in) >= 1);
            break;

        case MODE_EVP_READ_X:
            result = (lide_c_fifo_population(context->data_in) >= 1);
            break;

        case MODE_EVP_COMPUTE:
            result = true;
            break;

        case MODE_EVP_WRITE_RESULT:
            result = (lide_c_fifo_population(context->result_out) <
                      lide_c_fifo_capacity(context->result_out));
            break;

        case MODE_EVP_WRITE_STATUS:
        case MODE_ERROR_UNKNOWN_INST:
            result = (lide_c_fifo_population(context->status_out) <
                      lide_c_fifo_capacity(context->status_out));
            break;
        case MODE_EVB_READ_ARGS:
            result = (lide_c_fifo_population(context->control_in) >= 2);
            break;

        case MODE_EVB_READ_X:
            if (context->block_counter >= context->current_block_size) {
                result = true; 
            } else {
                result = (lide_c_fifo_population(context->data_in) >= 1);
            }
            break;

        case MODE_EVB_COMPUTE:
            result = true;
            break;

        case MODE_EVB_WRITE_RESULT:
            result = (lide_c_fifo_population(context->result_out) <
                      lide_c_fifo_capacity(context->result_out));
            break;

        case MODE_EVB_WRITE_STATUS:
            result = (lide_c_fifo_population(context->status_out) <
                      lide_c_fifo_capacity(context->status_out));
            break;
        default:
            result = false;
            break;
    }
    return result;
}

// Invoke Function //
void lide_c_pea_actor_invoke(lide_c_pea_actor_context_type *context) {
    int i;
    int poly_addr;
    int poly_degree;
    int block_size;
    int temp_coeff; 
    int result; 


    switch (context->mode) {
        case MODE_IDLE:
            lide_c_fifo_read(context->control_in, &(context->current_instruction));
            switch (context->current_instruction) {
                case INST_RST:
                    context->mode = MODE_RST_EXECUTE;
                    break;
                case INST_STP:
                    context->mode = MODE_STP_READ_ARGS;
                    break;
                case INST_EVP:
                    context->mode = MODE_EVP_READ_ARGS;
                    break;
                case INST_EVB:
                    context->mode = MODE_EVB_READ_ARGS;
                    break;
                default:
                    context->current_status = STATUS_ERROR_UNKNOWN_INST;
                    context->mode = MODE_ERROR_UNKNOWN_INST;
                    break;
            }
            break;

        case MODE_ERROR_UNKNOWN_INST:
            lide_c_fifo_write(context->status_out, &(context->current_status));
            context->mode = MODE_IDLE;
            break;

        case MODE_RST_EXECUTE:
            pea_c_actor_reset(context);
            /* reset function now sets mode back to IDLE */
            break;

        case MODE_STP_READ_ARGS:
            lide_c_fifo_read(context->control_in, &poly_addr);
            lide_c_fifo_read(context->control_in, &poly_degree);

            if (poly_addr >= 0 && poly_addr < MAX_POLYNOMIALS &&
                poly_degree >= 0 && poly_degree <= MAX_DEGREE) {
                context->current_poly_addr = poly_addr;
                context->current_poly_degree = poly_degree;
                context->coeff_counter = 0;

                if (context->polynomials[poly_addr] != NULL) {
                    free(context->polynomials[poly_addr]);
                }

                context->polynomials[poly_addr] = (int *)malloc(
                    (poly_degree + 1) * sizeof(int));
                context->degrees[poly_addr] = poly_degree;
               
                context->mode = MODE_STP_READ_COEFS;
            } else {
                context->current_status = STATUS_ERROR_UNKNOWN_INST;
                context->mode = MODE_ERROR_UNKNOWN_INST;
            }
            break;

        case MODE_STP_READ_COEFS:
            for (i = 0; i <= context->current_poly_degree; i++) {
                lide_c_fifo_read(context->data_in, &temp_coeff);
                context->polynomials[context->current_poly_addr][i] = temp_coeff;
            }
            context->mode = MODE_IDLE;
            break;

        case MODE_EVP_READ_ARGS:
            lide_c_fifo_read(context->control_in, &(context->current_poly_addr));
            context->mode = MODE_EVP_READ_X;
            break;

        case MODE_EVP_READ_X:
            lide_c_fifo_read(context->data_in, &(context->current_x));
            context->mode = MODE_EVP_COMPUTE;
            break;

        case MODE_EVP_COMPUTE:
            poly_addr = context->current_poly_addr;
            if (poly_addr >= 0 && poly_addr < MAX_POLYNOMIALS &&
                context->polynomials[poly_addr] != NULL) {
                
                context->current_result = pea_c_actor_compute_poly(
                    context->polynomials[poly_addr],
                    context->degrees[poly_addr],
                    context->current_x
                );
                context->current_status = STATUS_OK;
            } else {
                context->current_result = 0;
                context->current_status = STATUS_ERROR_POLY_INVALID;
            }
            context->mode = MODE_EVP_WRITE_RESULT;
            break;

        case MODE_EVP_WRITE_RESULT:
            lide_c_fifo_write(context->result_out, &(context->current_result));
            context->mode = MODE_EVP_WRITE_STATUS;
            break;

        case MODE_EVP_WRITE_STATUS:
            lide_c_fifo_write(context->status_out, &(context->current_status));
            context->mode = MODE_IDLE;
            break;

        case MODE_EVB_READ_ARGS:
            lide_c_fifo_read(context->control_in, &(context->current_poly_addr));
            lide_c_fifo_read(context->control_in, &(context->current_block_size));
            context->block_counter = 0;
           
            poly_addr = context->current_poly_addr;
            if (poly_addr < 0 || poly_addr >= MAX_POLYNOMIALS ||
                context->polynomials[poly_addr] == NULL) {
                
                context->current_status = STATUS_ERROR_POLY_INVALID;
                context->current_result = 0; 
                context->mode = MODE_EVB_WRITE_RESULT;
            
            } else if (context->current_block_size <= 0) {
                context->mode = MODE_IDLE;
            
            } else {
                context->mode = MODE_EVB_READ_X;
            }
            break;

        case MODE_EVB_READ_X:
            if (context->block_counter >= context->current_block_size) {
                context->mode = MODE_IDLE;
            } else {
                lide_c_fifo_read(context->data_in, &(context->current_x));
                context->mode = MODE_EVB_COMPUTE;
            }
            break;

        case MODE_EVB_COMPUTE:
            result = pea_c_actor_compute_poly(
                context->polynomials[context->current_poly_addr],
                context->degrees[context->current_poly_addr],
                context->current_x
            );
            context->current_result = result;
            context->current_status = STATUS_OK;
            context->mode = MODE_EVB_WRITE_RESULT;
            break;

        case MODE_EVB_WRITE_RESULT:
            lide_c_fifo_write(context->result_out, &(context->current_result));
            context->mode = MODE_EVB_WRITE_STATUS;
            break;

        case MODE_EVB_WRITE_STATUS:
            lide_c_fifo_write(context->status_out, &(context->current_status));
            context->block_counter++;
            
            if (context->current_status == STATUS_ERROR_POLY_INVALID) {
                 if (context->block_counter >= context->current_block_size) {
                    context->mode = MODE_IDLE;
                 } else {
                    context->mode = MODE_EVB_WRITE_RESULT;
                 }
            } else {
                context->mode = MODE_EVB_READ_X; 
            }
            break;
    }
}

// Destructor (terminate) //
void lide_c_pea_actor_terminate(lide_c_pea_actor_context_type *context) {
    if (context != NULL) {
        pea_c_actor_reset(context); 
        free(context);
    }
}

// Internal Helper Functions //

/* Frees all dynamically allocated polynomial memory AND resets state */
void pea_c_actor_reset(lide_c_pea_actor_context_type *context) {
    int i;
    for (i = 0; i < MAX_POLYNOMIALS; i++) {
        if (context->polynomials[i] != NULL) {
            free(context->polynomials[i]); 
            context->polynomials[i] = NULL;
        }
        context->degrees[i] = -1;
    }
    
    context->mode = MODE_IDLE;
    context->current_instruction = 0;
    context->current_poly_addr = 0;
    context->current_poly_degree = 0;
    context->current_block_size = 0;
    context->block_counter = 0;
    context->coeff_counter = 0;
    context->current_x = 0;
    context->current_result = 0;
    context->current_status = 0;
}

/* Computes p(x) using Horner's Method.
 * Uses 64-bit intermediate type (long long) to avoid overflow.
 */
int pea_c_actor_compute_poly(int *coeffs, int degree, int x) {
    long long result; 
    int i;

    if (coeffs == NULL || degree < 0) {
        return 0;
    }
    result = coeffs[degree];
    for (i = degree - 1; i >= 0; i--) {
        result = (result * (long long)x) + coeffs[i];
    }
    return (int)result;
}
