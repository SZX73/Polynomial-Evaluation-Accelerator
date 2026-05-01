`timescale 1ns/1ps
module evp_compute_fsm_3 #(
    parameter COEFF_WIDTH = 16, DATA_WIDTH = 32, DEGREE_WIDTH = 4, ADDR_WIDTH = 3
) (
    input clk, input rst, input start, output reg done,
    output reg [ADDR_WIDTH-1:0] evp_poly_addr,
    output reg [3:0] evp_coeff_addr, 
    output reg evp_coeff_re,
    input [DEGREE_WIDTH-1:0] evp_degree_out,
    input [COEFF_WIDTH-1:0] evp_coeff_out,
    input valid_poly,
    input [COEFF_WIDTH-1:0] x_in,
    output reg [DATA_WIDTH-1:0] result_out,
    output reg [DATA_WIDTH-1:0] status_out
);
    localparam S_IDLE=0, S_START_READ=1, S_WAIT_READ=2, S_COMPUTE=3, S_DONE=4;
    reg [2:0] state, next_state;
    reg signed [DATA_WIDTH-1:0] accumulator;
    reg signed [COEFF_WIDTH-1:0] x_val;
    integer loop_counter;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin state <= 0; accumulator <= 0; x_val <= 0; loop_counter <= 0; end
        else state <= next_state;
    end

    // Computation Logic
    always @(posedge clk) begin
        if (state == S_IDLE && start) begin
            x_val <= x_in; 
            accumulator <= 0;
            loop_counter <= evp_degree_out; 
            $display("EVP_FSM: START. x=%d, Degree=%d", x_in, evp_degree_out);
        end else if (state == S_COMPUTE) begin
            // Math happens here. Data must be valid NOW.
            $display("EVP_FSM: Step i=%d. Acc=%d, x=%d, Coeff=%d", loop_counter, accumulator, x_val, evp_coeff_out);
            accumulator <= (accumulator * x_val) + $signed(evp_coeff_out);
            loop_counter <= loop_counter - 1;
        end
    end

    always @(*) begin
        done = 0; evp_coeff_re = 0; evp_coeff_addr = loop_counter[3:0]; evp_poly_addr = 0; 
        result_out = accumulator; status_out = 0;
        next_state = state;

        case (state)
            S_IDLE: if (start) next_state = S_START_READ;
            
            S_START_READ: begin
                evp_coeff_re = 1; 
                next_state = S_WAIT_READ; 
            end
            
            S_WAIT_READ: begin
                evp_coeff_re = 1; // FIX: Hold Enable so RAM doesn't output 0
                next_state = S_COMPUTE; 
            end
            
            S_COMPUTE: begin
                evp_coeff_re = 1; // FIX: Hold Enable for calculation
                if (loop_counter == 0) next_state = S_DONE;
                else next_state = S_START_READ; 
            end
            
            S_DONE: begin done = 1; next_state = S_IDLE; end
        endcase
    end
endmodule
