`timescale 1ns/1ps
module firing_state_FSM_2 #(
    parameter MAX_DEGREE = 10, MAX_COEFFS = 11, COEFF_WIDTH = 16,
    parameter DATA_WIDTH = 32, DEGREE_WIDTH = 4, BLOCK_SIZE_WIDTH = 5, ADDR_WIDTH = 3
) (
    input clk, input rst, input start_in, output reg done_out,
    input [DATA_WIDTH-1:0] control_in_data, data_in_data,
    input [31:0] pop_control_in, pop_data_in, free_result_out, free_status_out,
    output reg rd_en_control, rd_en_data, wr_en_result, wr_en_status,
    output reg [DATA_WIDTH-1:0] data_out_result, data_out_status,
    output reg [3:0] mode_out
);
    localparam MODE_IDLE = 0, MODE_RST_EXECUTE = 1;
    localparam MODE_STP_READ_ARGS = 2, MODE_STP_READ_COEFS = 3;
    localparam MODE_EVP_READ_ARGS = 4, MODE_EVP_READ_X = 5, MODE_EVP_COMPUTE = 6;
    localparam MODE_EVP_WRITE_RESULT = 7, MODE_EVP_WRITE_STATUS = 8;
    localparam MODE_EVB_READ_ARGS = 9, MODE_EVB_READ_X = 10;
    
    reg [2:0] state, next_state;
    reg [3:0] current_mode;
    
    // Internal Registers
    reg [ADDR_WIDTH-1:0] current_poly_addr;
    reg [DEGREE_WIDTH-1:0] current_poly_degree;
    reg [COEFF_WIDTH-1:0] current_x;
    reg [DATA_WIDTH-1:0] current_result, current_status;
    reg [BLOCK_SIZE_WIDTH-1:0] current_block_size;

    // Sub-FSM Signals
    reg l3_stp_start, l3_evp_compute_start, l3_evb_loop_start, l3_rst_start;
    wire l3_stp_done, l3_evp_compute_done, l3_evb_loop_done, l3_rst_done;
    
    // Explicit Interconnects
    wire stp_rd_en_data;
    wire evb_rd_en_data, evb_wr_en_result, evb_wr_en_status;
    wire [DATA_WIDTH-1:0] evb_data_out_result, evb_data_out_status;
    wire evb_evp_start;
    wire [ADDR_WIDTH-1:0] evb_poly_addr;
    wire [COEFF_WIDTH-1:0] evb_x;

    // Memory Interconnects
    wire w_stp_degree_we;
    wire [DEGREE_WIDTH-1:0] w_stp_degree_in;
    wire w_stp_coeff_we;
    wire [3:0] w_stp_coeff_addr;
    wire [COEFF_WIDTH-1:0] w_stp_coeff_in;
    wire [ADDR_WIDTH-1:0] w_stp_poly_addr;

    wire [ADDR_WIDTH-1:0] w_evp_poly_addr;
    wire [3:0] w_evp_coeff_addr;
    wire w_evp_coeff_re;
    wire [DEGREE_WIDTH-1:0] w_evp_degree_out;
    wire [COEFF_WIDTH-1:0] w_evp_coeff_out;
    wire w_valid_poly;
    wire w_rst_all_mem;
    wire [DATA_WIDTH-1:0] w_evp_res, w_evp_stat;

    // State Logic
    always @(posedge clk or negedge rst) begin
        if (!rst) begin state <= 0; current_mode <= 0; end
        else begin 
            state <= next_state; 
            if (state == 1) current_mode <= mode_out; 
        end
    end

    // Data Latching
    always @(posedge clk) begin
        if (state == 1) begin
            case (current_mode)
                MODE_STP_READ_ARGS: begin
                    current_poly_addr <= control_in_data[ADDR_WIDTH-1:0];
                    current_poly_degree <= control_in_data[ADDR_WIDTH +: DEGREE_WIDTH];
                end
                MODE_EVP_READ_ARGS: current_poly_addr <= control_in_data[ADDR_WIDTH-1:0];
                MODE_EVP_READ_X: current_x <= data_in_data[COEFF_WIDTH-1:0];
                MODE_EVP_COMPUTE: begin
                    if (l3_evp_compute_done) begin
                        current_result <= w_evp_res;
                        current_status <= w_evp_stat;
                    end
                end
                MODE_EVB_READ_ARGS: begin
                    current_poly_addr <= control_in_data[ADDR_WIDTH-1:0];
                    current_block_size <= control_in_data[ADDR_WIDTH +: BLOCK_SIZE_WIDTH];
                    // Keep this helpful one
                    $display("L2: Latched EVB Args: Addr=%d Size=%d", control_in_data[ADDR_WIDTH-1:0], control_in_data[ADDR_WIDTH +: BLOCK_SIZE_WIDTH]);
                end
            endcase
        end
    end

    // Logic
    always @(*) begin
        done_out = 0; rd_en_control = 0; rd_en_data = 0; 
        wr_en_result = 0; wr_en_status = 0;
        data_out_result = 0; data_out_status = 0;
        mode_out = current_mode;
        
        l3_stp_start = 0; l3_evp_compute_start = 0; 
        l3_evb_loop_start = 0; l3_rst_start = 0;
        next_state = state;

        case (state)
            0: if (start_in) next_state = 1; 
            1: begin 
                case (current_mode)
                    MODE_IDLE: begin
                        rd_en_control = 1;
                        if (control_in_data[3:0] == 1) mode_out = MODE_STP_READ_ARGS;
                        else if (control_in_data[3:0] == 2) mode_out = MODE_EVP_READ_ARGS;
                        else if (control_in_data[3:0] == 3) mode_out = MODE_EVB_READ_ARGS;
                        else if (control_in_data[3:0] == 4) mode_out = MODE_RST_EXECUTE;
                        next_state = 2; 
                        // Keep this helpful one
                        $display("L2: IDLE -> Opcode %d", control_in_data[3:0]);
                    end
                    
                    MODE_RST_EXECUTE: begin
                        l3_rst_start = 1;
                        if (l3_rst_done) begin mode_out = MODE_IDLE; next_state = 2; end
                    end

                    MODE_STP_READ_ARGS: begin rd_en_control = 1; mode_out = MODE_STP_READ_COEFS; next_state = 2; end
                    MODE_STP_READ_COEFS: begin
                        l3_stp_start = 1;
                        rd_en_data = stp_rd_en_data; 
                        if (l3_stp_done) begin mode_out = MODE_IDLE; next_state = 2; end
                    end

                    MODE_EVP_READ_ARGS: begin rd_en_control = 1; mode_out = MODE_EVP_READ_X; next_state = 2; end
                    MODE_EVP_READ_X: begin rd_en_data = 1; mode_out = MODE_EVP_COMPUTE; next_state = 2; end
                    MODE_EVP_COMPUTE: begin
                        l3_evp_compute_start = 1;
                        if (l3_evp_compute_done) begin mode_out = MODE_EVP_WRITE_RESULT; next_state = 2; end
                    end
                    MODE_EVP_WRITE_RESULT: begin wr_en_result = 1; data_out_result = current_result; mode_out = MODE_EVP_WRITE_STATUS; next_state = 2; end
                    MODE_EVP_WRITE_STATUS: begin wr_en_status = 1; data_out_status = current_status; mode_out = MODE_IDLE; next_state = 2; end

                    MODE_EVB_READ_ARGS: begin rd_en_control = 1; mode_out = MODE_EVB_READ_X; next_state = 2; end
                    MODE_EVB_READ_X: begin
                        l3_evb_loop_start = 1;
                        rd_en_data = evb_rd_en_data;
                        wr_en_result = evb_wr_en_result;
                        wr_en_status = evb_wr_en_status;
                        data_out_result = evb_data_out_result;
                        data_out_status = evb_data_out_status;
                        if (l3_evb_loop_done) begin mode_out = MODE_IDLE; next_state = 2; end
                    end

                    default: next_state = 2;
                endcase
            end
            2: begin done_out = 1; next_state = 0; end
        endcase
    end

    // Muxing
    wire use_l2 = (current_mode == MODE_EVP_COMPUTE);
    wire [COEFF_WIDTH-1:0] evp_x_mux = (use_l2) ? current_x : evb_x;
    wire [ADDR_WIDTH-1:0] evp_addr_mux = (use_l2) ? current_poly_addr : evb_poly_addr;
    wire evp_start_mux = (use_l2) ? l3_evp_compute_start : evb_evp_start;

    // Instantiations
    pea_memory #(.MAX_DEGREE(MAX_DEGREE), .MAX_COEFFS(MAX_COEFFS), .COEFF_WIDTH(COEFF_WIDTH), .DEGREE_WIDTH(DEGREE_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) 
    memory_inst (
        .clk(clk), .rst(rst), .rst_all_mem(w_rst_all_mem),
        .stp_poly_addr(w_stp_poly_addr), .stp_degree_in(w_stp_degree_in), 
        .stp_coeff_in(w_stp_coeff_in), .stp_coeff_addr(w_stp_coeff_addr), 
        .stp_degree_we(w_stp_degree_we), .stp_coeff_we(w_stp_coeff_we),
        .evp_poly_addr(evp_addr_mux), .evp_coeff_addr(w_evp_coeff_addr), 
        .evp_coeff_re(w_evp_coeff_re), .evp_degree_out(w_evp_degree_out), 
        .evp_coeff_out(w_evp_coeff_out), .valid_poly(w_valid_poly)
    );

    rst_fsm_3 rst_inst (.clk(clk), .rst(rst), .start(l3_rst_start), .done(l3_rst_done), .rst_all_mem(w_rst_all_mem));

    stp_read_coeffs_fsm_3 #(.DEGREE_WIDTH(DEGREE_WIDTH), .COEFF_WIDTH(COEFF_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) 
    stp_inst (
        .clk(clk), .rst(rst), .start(l3_stp_start), .done(l3_stp_done),
        .data_in(data_in_data), .pop_data(pop_data_in), .rd_en_data(stp_rd_en_data),
        .poly_addr_A(current_poly_addr), .degree_N(current_poly_degree),
        .mem_degree_we(w_stp_degree_we), .mem_degree_in(w_stp_degree_in), 
        .mem_coeff_we(w_stp_coeff_we), .mem_coeff_addr(w_stp_coeff_addr), 
        .mem_coeff_in(w_stp_coeff_in), .mem_poly_addr(w_stp_poly_addr)
    );

    evp_compute_fsm_3_pipeline #(.COEFF_WIDTH(COEFF_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEGREE_WIDTH(DEGREE_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) 
    evp_inst (
        .clk(clk), .rst(rst), .start(evp_start_mux), .done(l3_evp_compute_done),
        .evp_poly_addr(w_evp_poly_addr), .evp_coeff_addr(w_evp_coeff_addr), 
        .evp_coeff_re(w_evp_coeff_re), .evp_degree_out(w_evp_degree_out), 
        .evp_coeff_out(w_evp_coeff_out), .valid_poly(w_valid_poly),
        .x_in(evp_x_mux), .result_out(w_evp_res), .status_out(w_evp_stat)
    );

    evb_loop_fsm_3 #(.BLOCK_SIZE_WIDTH(BLOCK_SIZE_WIDTH), .COEFF_WIDTH(COEFF_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) 
    evb_inst (
        .clk(clk), .rst(rst), .start(l3_evb_loop_start), .done(l3_evb_loop_done),
        .data_in(data_in_data), .pop_data(pop_data_in), .free_result(free_result_out), .free_status(free_status_out),
        .rd_en_data(evb_rd_en_data), 
        .wr_en_result(evb_wr_en_result), .wr_en_status(evb_wr_en_status),
        .data_out_result(evb_data_out_result), .data_out_status(evb_data_out_status),
        .poly_addr_A(current_poly_addr), .block_size_b(current_block_size), .mem_poly_valid(w_valid_poly),
        .evp_compute_start(evb_evp_start), .evp_compute_done(l3_evp_compute_done),
        .evp_computed_result(w_evp_res), .evp_status(w_evp_stat),
        .evp_poly_addr_out(evb_poly_addr), .evp_x_in(evb_x)
    );
endmodule
