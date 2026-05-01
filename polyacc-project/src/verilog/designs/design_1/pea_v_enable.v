`timescale 1ns/1ps
module pea_v_enable (
    input [31:0] pop_control_in,
    input [31:0] pop_data_in,
    input [31:0] free_result_out,
    input [31:0] free_status_out,
    input [3:0] mode_in,
    output reg enable
);
    localparam MODE_IDLE = 0;
    localparam MODE_RST_EXECUTE = 1;
    localparam MODE_STP_READ_ARGS = 2, MODE_STP_READ_COEFS = 3;
    localparam MODE_EVP_READ_ARGS = 4, MODE_EVP_READ_X = 5, MODE_EVP_COMPUTE = 6;
    localparam MODE_EVP_WRITE_RESULT = 7, MODE_EVP_WRITE_STATUS = 8;
    localparam MODE_EVB_READ_ARGS = 9, MODE_EVB_READ_X = 10;

    always @(*) begin
        case (mode_in)
            MODE_IDLE:          enable = (pop_control_in >= 1);
            MODE_RST_EXECUTE:   enable = 1'b1;
            
            // STP
            MODE_STP_READ_ARGS: enable = (pop_control_in >= 1); // 1 packed arg token
            MODE_STP_READ_COEFS:enable = 1'b1; // L3 handles data availability

            // EVP
            MODE_EVP_READ_ARGS: enable = (pop_control_in >= 1); // 1 addr token
            MODE_EVP_READ_X:    enable = (pop_data_in >= 1);
            MODE_EVP_COMPUTE:   enable = 1'b1; 
            MODE_EVP_WRITE_RESULT: enable = (free_result_out >= 1);
            MODE_EVP_WRITE_STATUS: enable = (free_status_out >= 1);

            // EVB
            MODE_EVB_READ_ARGS: enable = (pop_control_in >= 1); // 1 packed arg token
            MODE_EVB_READ_X:    enable = 1'b1; // L3 EVB handles data waiting internally
            
            default: enable = 1'b0;
        endcase
    end
endmodule