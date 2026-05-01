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
    input [log2(MAX_COEFFS)-1:0] stp_coeff_addr, 
    input stp_degree_we,
    input stp_coeff_we,

    // EVP Interface
    input [ADDR_WIDTH-1:0] evp_poly_addr,
    input [log2(MAX_COEFFS)-1:0] evp_coeff_addr,
    input evp_coeff_re,
    output [DEGREE_WIDTH-1:0] evp_degree_out,
    output [COEFF_WIDTH-1:0] evp_coeff_out,
    output valid_poly
);

    // Internal Storage
    reg [DEGREE_WIDTH-1:0] degrees [0:7];
    reg [COEFF_WIDTH-1:0] unified_ram [0:87];

	//Address Calculation
	wire [6:0] write_addr = stp_poly_addr * MAX_COEFFS + stp_coeff_addr;
	wire [6:0] read_addr = evp_poly_addr * MAX_COEFFS + evp_coeff_addr;
	integer i,j;

	always @(posedge clk) begin
		if (stp_coeff_we) begin
			unified_ram[write_addr] <= stp_coeff_in;
		end
	end

    // Degree Logic
    always @(posedge clk or negedge rst) begin
        if (!rst || rst_all_mem) begin
            for (j = 0; j < 8; j = j + 1) 
				degrees[j] <= 4'hF; 
        end else if (stp_degree_we) begin
            degrees[stp_poly_addr] <= stp_degree_in;
        end
    end

    // Read Logic
    assign evp_degree_out = degrees[evp_poly_addr];
    assign evp_coeff_out = (evp_coeff_re) ? unified_ram[read_addr] : 16'b0;
	assign valid_poly = (degrees[evp_poly_addr] != 4'hF);

	function integer log2;
		input [31:0] value;
		integer k;
		begin
			if (value <= 1)
				log2 = 1;
			else begin
				k = value - 1;
				for (log2 = 0; k > 0; log2 = log2 + 1)
					k = k >> 1;
			end
		end
	endfunction
endmodule
