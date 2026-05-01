`timescale 1ns/1ps
module evp_compute_fsm_3_dual #(
    parameter COEFF_WIDTH = 16, DATA_WIDTH = 32, DEGREE_WIDTH = 4, ADDR_WIDTH = 3
)(
    input clk, input rst, input start, output reg done,
    output reg [3:0] evp_coeff_addr,
    output reg evp_coeff_re,
    input  [DEGREE_WIDTH-1:0] evp_degree_out,
    input  [COEFF_WIDTH-1:0]  evp_coeff_out,
    input  valid_poly,
    input  [COEFF_WIDTH-1:0] x_in,
    output reg [DATA_WIDTH-1:0] result_out,
    output reg [DATA_WIDTH-1:0] status_out
);
    localparam S_IDLE=0, S_READ_HI=1, S_READ_LO=2, S_COMPUTE=3, S_DONE=4, S_COMPUTE_FINAL=5;
    reg [2:0] state, next_state;
    reg signed [DATA_WIDTH-1:0] result_reg;
    reg signed [COEFF_WIDTH-1:0] coeff_hi, coeff_lo;
    reg signed [DEGREE_WIDTH:0] idx;
    
    localparam STATUS_OK = 0;
    localparam STATUS_ERROR_POLY_INVALID = 224;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin state<=0; result_reg<=0; coeff_hi<=0; coeff_lo<=0; idx<=0; end
        else state <= next_state;
    end

    always @(posedge clk) begin
        if (state == S_IDLE && start && valid_poly) begin
             idx <= evp_degree_out;
             result_reg <= 0;
             $display("EVP_DUAL: Start. Valid=%b, Deg=%d, X=%d", valid_poly, evp_degree_out, x_in);
        end else if (state == S_READ_HI) begin
             coeff_hi <= evp_coeff_out; 
             $display("EVP_DUAL: Read HI[%d] = %d", idx, evp_coeff_out);
             idx <= idx - 1; 
        end else if (state == S_READ_LO) begin
             coeff_lo <= evp_coeff_out;
             $display("EVP_DUAL: Read LO[%d] = %d", idx, evp_coeff_out);
        end else if (state == S_COMPUTE) begin
             result_reg <= (($signed(result_reg) * $signed(x_in) + $signed(coeff_hi)) * $signed(x_in)) + $signed(coeff_lo);
             $display("EVP_DUAL: Compute Step. Result=%d", 
                      (($signed(result_reg) * $signed(x_in) + $signed(coeff_hi)) * $signed(x_in)) + $signed(coeff_lo));
             idx <= idx - 1; 
        end else if (state == S_COMPUTE_FINAL) begin
             result_reg <= ($signed(result_reg) * $signed(x_in)) + $signed(coeff_hi);
             $display("EVP_DUAL: Final Odd Step. Coeff=%d", coeff_hi);
        end
    end

    always @(*) begin
        done = 0; evp_coeff_re = 0; evp_coeff_addr = 0;
        result_out = result_reg; status_out = STATUS_OK;
        next_state = state;

        case(state)
        S_IDLE: begin
            if (start) begin
                if (!valid_poly) begin
                    status_out = STATUS_ERROR_POLY_INVALID; result_out = 0; next_state = S_DONE;
                end else begin
                    evp_coeff_addr = evp_degree_out; evp_coeff_re = 1;
                    next_state = S_READ_HI;
                end
            end else next_state = S_IDLE;
        end
        S_READ_HI: begin
            if (idx < 0) begin
                next_state = S_DONE;
            end else if (idx == 0) begin
                // *** FIX: HOLD ENABLE! ***
                evp_coeff_re = 1;  // Keep reading so we don't latch 0!
                evp_coeff_addr = idx;
                next_state = S_COMPUTE_FINAL;
            end else begin
                evp_coeff_addr = idx; evp_coeff_re = 1;
                next_state = S_READ_LO;
            end
        end
        S_READ_LO: begin
            evp_coeff_re = 1; 
            evp_coeff_addr = idx; 
            next_state = S_COMPUTE;
        end
        S_COMPUTE: begin
            if (idx < 0) next_state = S_DONE;
            else begin
                evp_coeff_addr = idx; evp_coeff_re = 1; 
                next_state = S_READ_HI;
            end
        end
        S_COMPUTE_FINAL: begin
            next_state = S_DONE;
        end
        S_DONE: begin done = 1; next_state = S_IDLE; end
        endcase
    end
endmodule
