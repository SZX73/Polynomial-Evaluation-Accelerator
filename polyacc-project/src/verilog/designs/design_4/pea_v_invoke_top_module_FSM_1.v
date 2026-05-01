`timescale 1ns/1ps
module pea_v_invoke_top_module_FSM_1 #(
    parameter MAX_DEGREE = 10, MAX_COEFFS = 11, COEFF_WIDTH = 16,
    parameter DATA_WIDTH = 32, DEGREE_WIDTH = 4, BLOCK_SIZE_WIDTH = 5, ADDR_WIDTH = 3
) (
    input clk, input rst,
    input invoke, output FC, 
    output [3:0] mode_out, // Connection to AEM
    
    // FIFO Data
    input [DATA_WIDTH-1:0] control_in_data, data_in_data,
    input [31:0] pop_control_in, pop_data_in, free_result_out, free_status_out,

    // FIFO Controls (CRITICAL OUTPUTS)
    output rd_en_control, rd_en_data,
    output wr_en_result, wr_en_status,
    output [DATA_WIDTH-1:0] data_out_result, data_out_status
);
    // FSM States
    localparam STATE_IDLE = 2'b00, STATE_FIRING_START = 2'b01, STATE_FIRING_WAIT = 2'b10;
    reg [1:0] state, next_state;
    reg start_in_child;
    wire done_out_child;

    assign FC = done_out_child;

    // Instantiate Level 2 FSM
    firing_state_FSM_2 #(
        .MAX_DEGREE(MAX_DEGREE), .MAX_COEFFS(MAX_COEFFS), .COEFF_WIDTH(COEFF_WIDTH),
        .DATA_WIDTH(DATA_WIDTH), .DEGREE_WIDTH(DEGREE_WIDTH), .BLOCK_SIZE_WIDTH(BLOCK_SIZE_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) FSM2 (
        .clk(clk), .rst(rst),
        .start_in(start_in_child), .done_out(done_out_child),
        .mode_out(mode_out),
        
        .control_in_data(control_in_data), .data_in_data(data_in_data),
        .pop_control_in(pop_control_in), .pop_data_in(pop_data_in),
        .free_result_out(free_result_out), .free_status_out(free_status_out),
        
        // *** CRITICAL FIX: Ensure these are connected to the OUTPUT ports ***
        .rd_en_control(rd_en_control),
        .rd_en_data(rd_en_data),
        .wr_en_result(wr_en_result),
        .wr_en_status(wr_en_status),
        .data_out_result(data_out_result),
        .data_out_status(data_out_status)
    );

    // Level 1 Logic
    always @(posedge clk or negedge rst) begin
        if (!rst) state <= STATE_IDLE;
        else state <= next_state;
    end

    always @(*) begin
        start_in_child = 0;
        next_state = state;
        case (state)
            STATE_IDLE: if (invoke) next_state = STATE_FIRING_START;
            STATE_FIRING_START: begin
                start_in_child = 1;
                next_state = STATE_FIRING_WAIT;
            end
            STATE_FIRING_WAIT: if (done_out_child) next_state = STATE_IDLE;
        endcase
    end
endmodule
