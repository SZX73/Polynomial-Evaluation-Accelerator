`timescale 1ns / 1ps

/*
 * FIFO MODULE
 * Data is available at 'data_out' BEFORE 'rd_en' is asserted.
 * 'rd_en' acts as a 'pop' or 'acknowledge' signal to advance to the next data.
 */
module fifo #(
    parameter buffer_size = 16,
    parameter width = 32
) (
    input clk,
    input rst,
    input wr_en,
    input [width-1:0] data_in,
    input rd_en,
    output [width-1:0] data_out, // Changed from reg to wire (implicit)
    output reg [31:0] population,
    output [31:0] free_space
);
    reg [width-1:0] FIFO_RAM [0:buffer_size-1];
    reg [31:0] wr_addr;
    reg [31:0] rd_addr;
    wire empty;
    wire full;

    function integer log2;
        input [31:0] value;
        integer i;
        begin
            if (value <= 1) log2 = 1;
            else begin
                i = value - 1;
                for (log2 = 0; i > 0; log2 = log2 + 1) i = i >> 1;
            end
        end
    endfunction

    // Write Operation (Synchronous)
    always @(posedge clk) begin
        if (wr_en && !full) begin
            FIFO_RAM[wr_addr] <= data_in;
            wr_addr <= (wr_addr == buffer_size - 1) ? 0 : wr_addr + 1;
        end
    end

    // Read Operation (Synchronous Pointer Update)
    always @(posedge clk) begin
        if (!rst) begin
             rd_addr <= 0;
        end else if (rd_en && !empty) begin
            rd_addr <= (rd_addr == buffer_size - 1) ? 0 : rd_addr + 1;
        end
    end

    // Output Logic (Asynchronous Read)
    // Data is always available at the current read pointer
    assign data_out = FIFO_RAM[rd_addr];

    // Population Counter
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            population <= 0;
            wr_addr <= 0;
        end else begin
            if ( (wr_en && !full) && (!rd_en || empty) ) begin
                population <= population + 1;
            end 
            else if ( (rd_en && !empty) && (!wr_en || full) ) begin
                population <= population - 1;
            end
        end
    end

    assign empty = (population == 0);
    assign full = (population == buffer_size);
    assign free_space = buffer_size - population;
endmodule
