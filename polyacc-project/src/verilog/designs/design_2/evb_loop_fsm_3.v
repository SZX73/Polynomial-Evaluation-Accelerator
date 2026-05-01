`timescale 1ns/1ps
module evb_loop_fsm_3 #(
    parameter BLOCK_SIZE_WIDTH = 5,
    parameter COEFF_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 3
) (
    input clk, input rst, input start, output reg done,
    input [DATA_WIDTH-1:0] data_in, input [31:0] pop_data,
    input [31:0] free_result, input [31:0] free_status,
    output reg rd_en_data, output reg wr_en_result, output reg wr_en_status,
    output reg [DATA_WIDTH-1:0] data_out_result, output reg [DATA_WIDTH-1:0] data_out_status,
    input [ADDR_WIDTH-1:0] poly_addr_A, input [BLOCK_SIZE_WIDTH-1:0] block_size_b, input mem_poly_valid, 
    output reg evp_compute_start, input evp_compute_done,
    input [DATA_WIDTH-1:0] evp_computed_result, input [DATA_WIDTH-1:0] evp_status,
    output reg [ADDR_WIDTH-1:0] evp_poly_addr_out, output reg [COEFF_WIDTH-1:0] evp_x_in
);
    localparam S_IDLE = 0, S_CHECK_LOOP = 1, S_WAIT_DATA = 2, S_READ_X = 3;
    localparam S_WAIT_EVP = 4, S_WRITE_RESULT = 5, S_WRITE_STATUS = 6, S_DONE = 7;
    localparam S_ERROR_WRITE_STATUS = 8;

    reg [3:0] state, next_state;
    reg [BLOCK_SIZE_WIDTH-1:0] loop_counter;
    reg [COEFF_WIDTH-1:0] current_x;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin state <= 0; loop_counter <= 0; current_x <= 0; end
        else begin
            state <= next_state;
            if (state == S_IDLE) loop_counter <= 0;
            else if (state == S_WRITE_STATUS) loop_counter <= loop_counter + 1;
            
            if (state == S_READ_X) begin
                current_x <= data_in[COEFF_WIDTH-1:0];
                // *** KEEPING THIS DEBUG PRINT ***
                $display("EVB_FSM: Loop %d/%d. Read x=%d", loop_counter, block_size_b, data_in[COEFF_WIDTH-1:0]);
            end
        end
    end

    always @(*) begin
        done = 0; rd_en_data = 0; wr_en_result = 0; wr_en_status = 0;
        data_out_result = 0; data_out_status = 0;
        evp_compute_start = 0; evp_poly_addr_out = poly_addr_A; evp_x_in = current_x;
        next_state = state;

        case (state)
            S_IDLE: if (start) next_state = S_CHECK_LOOP;
            S_CHECK_LOOP: begin
                if (!mem_poly_valid) begin data_out_status = 32'd224; next_state = S_ERROR_WRITE_STATUS; end
                else if (loop_counter >= block_size_b) next_state = S_DONE;
                else next_state = S_WAIT_DATA;
            end
            S_WAIT_DATA: if (pop_data > 0) next_state = S_READ_X;
            S_READ_X: begin rd_en_data = 1; next_state = S_WAIT_EVP; end
            S_WAIT_EVP: begin evp_compute_start = 1; if (evp_compute_done) next_state = S_WRITE_RESULT; end
            S_WRITE_RESULT: begin wr_en_result = 1; data_out_result = evp_computed_result; next_state = S_WRITE_STATUS; end
            S_WRITE_STATUS: begin wr_en_status = 1; data_out_status = evp_status; next_state = S_CHECK_LOOP; end
            S_ERROR_WRITE_STATUS: begin wr_en_status = 1; data_out_status = 32'd224; next_state = S_DONE; end
            S_DONE: begin done = 1; next_state = S_IDLE; end
        endcase
    end
endmodule
