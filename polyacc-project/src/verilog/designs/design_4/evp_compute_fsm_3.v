`timescale 1ns/1ps

module evp_compute_fsm_3 #(
    parameter COEFF_WIDTH = 16, 
    parameter DATA_WIDTH = 32, 
    parameter DEGREE_WIDTH = 4, 
    parameter ADDR_WIDTH = 3
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

    // States
    localparam S_IDLE = 0;
    localparam S_START_READ = 1;
    localparam S_WAIT_READ = 2;   // Wait for FIRST coefficient (c_N)
    localparam S_MULT_INIT = 3;
    localparam S_MULT_SHIFT = 4;
    localparam S_WAIT_COEFF = 5;  // Wait for NEXT coefficient
    localparam S_ADD_COEFF = 6;
    localparam S_DONE = 7;
    
    reg [2:0] state, next_state;
    
    // Registers
    reg signed [DATA_WIDTH-1:0] accumulator;
    reg signed [COEFF_WIDTH-1:0] x_val;
    integer loop_counter;
    
    // Serial multiplier
    reg [4:0] mult_counter;
    reg [DATA_WIDTH-1:0] partial_product;
    reg [COEFF_WIDTH-1:0] multiplier;
    reg [DATA_WIDTH-1:0] multiplicand;

    // State register
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S_IDLE;
            accumulator <= 0;
            x_val <= 0;
            loop_counter <= 0;
        end else begin
            state <= next_state;
        end
    end

    // Datapath
    always @(posedge clk) begin
        if (state == S_IDLE && start) begin
            x_val <= x_in;
            accumulator <= 0;
            loop_counter <= evp_degree_out;
            $display("EVP_FSM: START. x=%d, Degree=%d", x_in, evp_degree_out);
        end 
        else if (state == S_WAIT_READ) begin
            // First coefficient (c_N) is now valid
            $display("EVP_FSM: Step i=%d. Acc=%d, x=%d, Coeff=%d", 
                     loop_counter, 32'd0, x_val, evp_coeff_out);
            accumulator <= $signed(evp_coeff_out);
            loop_counter <= loop_counter - 1;
        end
        else if (state == S_MULT_INIT) begin
            // Initialize multiplier
            partial_product <= 0;
            multiplier <= x_val;
            multiplicand <= accumulator;
            mult_counter <= 0;
        end
        else if (state == S_MULT_SHIFT) begin
            // Shift-and-add
            if (multiplier[0])
                partial_product <= partial_product + multiplicand;
            
            multiplier <= multiplier >> 1;
            multiplicand <= multiplicand << 1;
            mult_counter <= mult_counter + 1;
        end
        else if (state == S_ADD_COEFF) begin
            // Coefficient is now valid, add it
            $display("EVP_FSM: Step i=%d. Acc=%d, x=%d, Coeff=%d", 
                     loop_counter, partial_product, x_val, evp_coeff_out);
            accumulator <= $signed(partial_product) + $signed(evp_coeff_out);
            loop_counter <= loop_counter - 1;
        end
    end

    // Next state logic
    always @(*) begin
        done = 1'b0;
        evp_coeff_re = 1'b0;
        evp_coeff_addr = loop_counter[3:0];
        evp_poly_addr = 0;
        result_out = accumulator;
        status_out = 32'd0;
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start) begin
                    if (valid_poly)
                        next_state = S_START_READ;
                    else begin
                        result_out = 32'd0;
                        status_out = 32'd224;
                        next_state = S_DONE;
                    end
                end
            end
            
            S_START_READ: begin
                evp_coeff_re = 1'b1;
                next_state = S_WAIT_READ;
            end
            
            S_WAIT_READ: begin
                evp_coeff_re = 1'b1;  // Hold enable
                // After loading c_N, check if degree 0
                if (loop_counter == 0)
                    next_state = S_DONE;
                else
                    next_state = S_MULT_INIT;
            end
            
            S_MULT_INIT: begin
                next_state = S_MULT_SHIFT;
            end
            
            S_MULT_SHIFT: begin
                if (mult_counter >= 15) begin
                    evp_coeff_re = 1'b1;  // Request next coefficient
                    next_state = S_WAIT_COEFF;  // WAIT for it!
                end else begin
                    next_state = S_MULT_SHIFT;
                end
            end
            
            S_WAIT_COEFF: begin
                evp_coeff_re = 1'b1;  // Hold enable
                next_state = S_ADD_COEFF;  // Data will be valid next cycle
            end
            
            S_ADD_COEFF: begin
                evp_coeff_re = 1'b1;  // Hold enable during add
                if (loop_counter == 0)
                    next_state = S_DONE;
                else
                    next_state = S_MULT_INIT;  // Next iteration
            end
            
            S_DONE: begin
                done = 1'b1;
                next_state = S_IDLE;
            end
            
            default: next_state = S_IDLE;
        endcase
    end

endmodule
