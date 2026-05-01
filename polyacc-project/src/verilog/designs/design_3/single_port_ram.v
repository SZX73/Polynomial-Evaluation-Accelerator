`timescale 1ns/1ps
module single_port_ram #(
    parameter size = 11, width = 16
) (
    input [width-1:0] data,
    input [31:0] addr, rd_addr, // simplified width for debug
    input wr_en, re_en, clk,
    output [width-1:0] q
);
    reg [width-1:0] ram[size-1:0];

    always @(posedge clk) begin
        if (wr_en) begin
            ram[addr] <= data;
            // Confirm Write for debugging purposes
            $display("RAM: Wrote %d to Addr %d", data, addr);
        end
    end

    assign q = (re_en) ? ram[rd_addr] : 0;
endmodule
