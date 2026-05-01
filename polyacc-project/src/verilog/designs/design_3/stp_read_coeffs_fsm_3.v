`timescale 1ns/1ps
module stp_read_coeffs_fsm_3 #(
    parameter DEGREE_WIDTH = 4, COEFF_WIDTH = 16, ADDR_WIDTH = 3
) (
    input clk, input rst, input start, output reg done,
    input [31:0] data_in, input [31:0] pop_data, output reg rd_en_data,
    input [ADDR_WIDTH-1:0] poly_addr_A, input [DEGREE_WIDTH-1:0] degree_N,
    output reg mem_degree_we, output reg [DEGREE_WIDTH-1:0] mem_degree_in,
    output reg mem_coeff_we, output reg [3:0] mem_coeff_addr, 
    output reg [COEFF_WIDTH-1:0] mem_coeff_in, output reg [ADDR_WIDTH-1:0] mem_poly_addr
);
    localparam S_IDLE=0, S_WRITE_DEGREE=1, S_WAIT_DATA=2, S_READ_WRITE=3, S_DONE=4;
    reg [2:0] state, next_state;
    reg [3:0] coeff_counter;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin state <= 0; coeff_counter <= 0; end
        else begin 
            state <= next_state;
            if (state == S_IDLE) coeff_counter <= 0;
            else if (state == S_READ_WRITE) coeff_counter <= coeff_counter + 1;
            
            // *** KEEPING THIS DEBUG PRINT AS REQUESTED ***
            if (state != next_state) 
                $display("STP_FSM: State %d -> %d | Counter: %d | Deg: %d | Pop: %d", 
                         state, next_state, coeff_counter, degree_N, pop_data);
        end
    end

    always @(*) begin
        done = 0; rd_en_data = 0; mem_degree_we = 0; mem_coeff_we = 0;
        mem_degree_in = 0; mem_coeff_addr = coeff_counter; mem_coeff_in = 0; mem_poly_addr = poly_addr_A;
        next_state = state;

        case (state)
            S_IDLE: if (start) next_state = S_WRITE_DEGREE;
            S_WRITE_DEGREE: begin
                mem_degree_we = 1; mem_degree_in = degree_N;
                next_state = S_WAIT_DATA;
            end
            S_WAIT_DATA: begin
                if (coeff_counter > degree_N) next_state = S_DONE;
                else if (pop_data >= 1) next_state = S_READ_WRITE;
            end
            S_READ_WRITE: begin
                rd_en_data = 1; mem_coeff_we = 1; mem_coeff_in = data_in[COEFF_WIDTH-1:0];
                next_state = S_WAIT_DATA;
            end
            S_DONE: begin done = 1; next_state = S_IDLE; end
        endcase
    end
endmodule
