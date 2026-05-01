`timescale 1ns/1ps

module pea_memory #(
    parameter MAX_DEGREE = 10,
    parameter MAX_COEFFS = 11,
    parameter COEFF_WIDTH = 16,
    parameter DEGREE_WIDTH = 4,
    parameter ADDR_WIDTH = 3
) (
    input clk, input rst,
    input rst_all_mem,

    // STP Interface (Fixed Widths: [3:0] for Coeff Addr)
    input [ADDR_WIDTH-1:0] stp_poly_addr,
    input [DEGREE_WIDTH-1:0] stp_degree_in,
    input [COEFF_WIDTH-1:0] stp_coeff_in,
    input [3:0] stp_coeff_addr, 
    input stp_degree_we,
    input stp_coeff_we,

    // EVP Interface
    input [ADDR_WIDTH-1:0] evp_poly_addr,
    input [3:0] evp_coeff_addr,
    input evp_coeff_re,
    output [DEGREE_WIDTH-1:0] evp_degree_out,
    output [COEFF_WIDTH-1:0] evp_coeff_out,
    output valid_poly
);

    // Internal Storage
    reg [DEGREE_WIDTH-1:0] degrees [0:7];
    wire [COEFF_WIDTH-1:0] ram_read_data [0:7];
    integer i;

    // 8 Single Port RAMs
    genvar gv_i;
    generate
        for (gv_i = 0; gv_i < 8; gv_i = gv_i + 1) begin : ram_gen
            single_port_ram #(
                .size(MAX_COEFFS), 
                .width(COEFF_WIDTH)
            ) ram_inst (
                .data(stp_coeff_in),
                // Connect 4-bit addr to 32-bit port (zero extension)
                .addr({28'b0, stp_coeff_addr}), 
                .rd_addr({28'b0, evp_coeff_addr}),
                .wr_en(stp_coeff_we && (stp_poly_addr == gv_i)),
                .re_en(evp_coeff_re),
                .clk(clk),
                .q(ram_read_data[gv_i])
            );
        end
    endgenerate

    // Degree Logic
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 8; i = i + 1) degrees[i] <= 4'hF; 
        end else if (rst_all_mem) begin
            for (i = 0; i < 8; i = i + 1) degrees[i] <= 4'hF;
        end else if (stp_degree_we) begin
            degrees[stp_poly_addr] <= stp_degree_in;
        end
    end

    // Read Logic
    assign evp_degree_out = degrees[evp_poly_addr];
    assign evp_coeff_out = ram_read_data[evp_poly_addr];
    assign valid_poly = (degrees[evp_poly_addr] != 4'hF);

endmodule
