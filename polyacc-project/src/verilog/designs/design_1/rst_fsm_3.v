`timescale 1ns/1ps
/*
 * PEA Actor L3 FSM: Reset (rst_fsm_3.v)
 * Asserts the memory reset signal for one cycle.
 */
module rst_fsm_3 (
    input clk,
    input rst,
    input start, // From L2 FSM
    output reg done, // To L2 FSM
    output reg rst_all_mem // To pea_memory
);
    localparam S_IDLE = 0, S_EXEC = 1;
    reg state, next_state;

    always @(posedge clk or negedge rst)
        state <= (!rst) ? S_IDLE : next_state;
        
    always @(*) begin
        // Default outputs
        done = 1'b0;
        rst_all_mem = 1'b0;
        
        case (state)
            S_IDLE: 
                next_state = (start) ? S_EXEC : S_IDLE;
            S_EXEC: begin
                rst_all_mem = 1'b1; // Assert reset signal
                done = 1'b1;        // Done in one cycle
                next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end
endmodule
