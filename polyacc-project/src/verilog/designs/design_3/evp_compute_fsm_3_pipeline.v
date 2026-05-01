`timescale 1ns/1ps
module evp_compute_fsm_3_pipeline #(
    parameter COEFF_WIDTH = 16,
    parameter DATA_WIDTH  = 32,
    parameter DEGREE_WIDTH = 4,
    parameter ADDR_WIDTH = 3,
    parameter MAX_DEGREE  = 10
)(
    input clk, input rst, input start,
    output reg done,

    output reg [3:0] evp_coeff_addr,
    output reg       evp_coeff_re,
    input  [DEGREE_WIDTH-1:0] evp_degree_out,
    input  [COEFF_WIDTH-1:0]  evp_coeff_out,
    input [ADDR_WIDTH-1:0] evp_poly_addr,
    input  valid_poly,

    input  [COEFF_WIDTH-1:0] x_in,

    output reg [DATA_WIDTH-1:0] result_out,
    output reg [DATA_WIDTH-1:0] status_out
);

    localparam S_IDLE      = 0,
               S_LOAD      = 1,
               S_PIPE_INIT = 2,
               S_PIPE_RUN  = 3,
               S_DONE      = 4;

    reg [2:0] state, next_state;

    reg signed [DATA_WIDTH-1:0] result_reg;
    reg signed [COEFF_WIDTH-1:0] coeff_buf [0:MAX_DEGREE];

    reg signed [DEGREE_WIDTH:0] idx;
    reg signed [DEGREE_WIDTH:0] pipe_step;

    localparam STATUS_OK = 0;
    localparam STATUS_ERROR_POLY_INVALID = 224;


    // State register
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S_IDLE;
            idx <= 0;
            pipe_step <= 0;
            result_reg <= 0;
        end else begin
            state <= next_state;
        end
    end


    // Sequential work logic
    always @(posedge clk) begin

        if (state == S_IDLE && start && valid_poly) begin
            idx <= evp_degree_out;
            result_reg <= 0;
        end

        else if (state == S_LOAD) begin
            coeff_buf[idx] <= evp_coeff_out;
            idx <= idx - 1;
        end

        else if (state == S_PIPE_INIT) begin
            pipe_step <= evp_degree_out;
            result_reg <= coeff_buf[evp_degree_out];
        end

        else if (state == S_PIPE_RUN) begin
            if (pipe_step >= 1) begin
                result_reg <= (result_reg * $signed(x_in)) + 
                              $signed(coeff_buf[pipe_step-1]);
                pipe_step <= pipe_step - 1;
            end
        end
    end


    // Next-state & output logic
    always @(*) begin
        done = 0;
        evp_coeff_re = 0;
        evp_coeff_addr = 0;
        result_out = result_reg;
        status_out = STATUS_OK;

        next_state = state;

        case (state)

            S_IDLE: begin
                if (start) begin
                    if (!valid_poly) begin
                        status_out = STATUS_ERROR_POLY_INVALID;
                        result_out = 0;
                        next_state = S_DONE;
                    end else begin
                        evp_coeff_addr = evp_degree_out;
                        evp_coeff_re = 1;
                        next_state = S_LOAD;
                    end
                end
            end

            S_LOAD: begin
                if (idx < 0) begin
                    next_state = S_PIPE_INIT;
                end else begin
                    evp_coeff_addr = idx;
                    evp_coeff_re = 1;
                    next_state = S_LOAD;
                end
            end

            S_PIPE_INIT: begin
                next_state = S_PIPE_RUN;
            end

            S_PIPE_RUN: begin
                if (pipe_step <= 0)
                    next_state = S_DONE;
                else
                    next_state = S_PIPE_RUN;
            end

            S_DONE: begin
                done = 1;
                next_state = S_IDLE;
            end
        endcase
    end

endmodule
