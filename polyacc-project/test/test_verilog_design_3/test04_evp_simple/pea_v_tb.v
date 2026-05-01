`timescale 1ns/1ps

module pea_v_tb;

    parameter DATA_WIDTH = 32;
    parameter BUFFER_SIZE = 1024; 

    reg clk, rst;
    reg invoke;                 
    wire enable, FC;                    
    wire [3:0] mode_wire;       

    // FIFO Signals
    reg wr_en_control, wr_en_data;
    reg [DATA_WIDTH-1:0] control_in_val, data_in_val;
    wire rd_en_control_actor, rd_en_data_actor;
    
    // Read Logic
    wire rd_en_control_safe, rd_en_data_safe;
    reg loading_phase;

    wire [DATA_WIDTH-1:0] control_fifo_out, data_fifo_out;
    wire [31:0] pop_control, pop_data;

    // Output Signals
    reg rd_en_result, rd_en_status;
    wire wr_en_result_actor, wr_en_status_actor;
    wire [DATA_WIDTH-1:0] result_actor_out, result_fifo_out;
    wire [DATA_WIDTH-1:0] status_actor_out, status_fifo_out;
    wire [31:0] pop_result, free_result;
    wire [31:0] pop_status, free_status;

    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    assign rd_en_control_safe = (loading_phase) ? 1'b0 : rd_en_control_actor;
    assign rd_en_data_safe    = (loading_phase) ? 1'b0 : rd_en_data_actor;

    fifo #(.buffer_size(BUFFER_SIZE), .width(DATA_WIDTH)) FIFO_CONTROL (
        .clk(clk), .rst(rst), .wr_en(wr_en_control), .data_in(control_in_val),
        .rd_en(rd_en_control_safe), .data_out(control_fifo_out), .population(pop_control), .free_space()
    );
    fifo #(.buffer_size(BUFFER_SIZE), .width(DATA_WIDTH)) FIFO_DATA (
        .clk(clk), .rst(rst), .wr_en(wr_en_data), .data_in(data_in_val),
        .rd_en(rd_en_data_safe), .data_out(data_fifo_out), .population(pop_data), .free_space()
    );
    
    // *** CRITICAL: Ensure pop_result and pop_status are wired here! ***
    fifo #(.buffer_size(BUFFER_SIZE), .width(DATA_WIDTH)) FIFO_RESULT (
        .clk(clk), .rst(rst), .wr_en(wr_en_result_actor), .data_in(result_actor_out),
        .rd_en(rd_en_result), .data_out(result_fifo_out), 
        .population(pop_result), // <--- This wire must go to the Monitor Logic
        .free_space(free_result)
    );
    fifo #(.buffer_size(BUFFER_SIZE), .width(DATA_WIDTH)) FIFO_STATUS (
        .clk(clk), .rst(rst), .wr_en(wr_en_status_actor), .data_in(status_actor_out),
        .rd_en(rd_en_status), .data_out(status_fifo_out), 
        .population(pop_status), // <--- This wire must go to the Monitor Logic
        .free_space(free_status)
    );

    pea_v_enable AEM (
        .pop_control_in(pop_control), .pop_data_in(pop_data),
        .free_result_out(free_result), .free_status_out(free_status),
        .mode_in(mode_wire), .enable(enable)
    );

    pea_v_invoke_top_module_FSM_1 AIM (
        .clk(clk), .rst(rst), .invoke(invoke), .FC(FC),
        .mode_out(mode_wire), 
        .control_in_data(control_fifo_out), .data_in_data(data_fifo_out),
        .pop_control_in(pop_control), .pop_data_in(pop_data),
        .free_result_out(free_result), .free_status_out(free_status),
        .rd_en_control(rd_en_control_actor), .rd_en_data(rd_en_data_actor),
        .wr_en_result(wr_en_result_actor), .wr_en_status(wr_en_status_actor),
        .data_out_result(result_actor_out), .data_out_status(status_actor_out)
    );

    integer file_control, file_data, file_out;
    integer scan_res, temp_val;

    initial begin
        rst = 0; invoke = 0; 
        wr_en_control = 0; wr_en_data = 0; 
        rd_en_result = 0; rd_en_status = 0;
        loading_phase = 1; 

        rst = 1; #10 rst = 0; #20 rst = 1;
        $display("--- RESET COMPLETE ---");

        file_control = $fopen("control_in.txt", "r");
        while (!$feof(file_control)) begin
            scan_res = $fscanf(file_control, "%d", temp_val);
            if (scan_res == 1) begin
                @(posedge clk);
                wr_en_control = 1; control_in_val = temp_val;
                @(posedge clk);
                wr_en_control = 0;
            end
        end
        $fclose(file_control);

        file_data = $fopen("data_in.txt", "r");
        if (file_data != 0) begin
            while (!$feof(file_data)) begin
                scan_res = $fscanf(file_data, "%d", temp_val);
                if (scan_res == 1) begin
                    @(posedge clk);
                    wr_en_data = 1; data_in_val = temp_val;
                    @(posedge clk);
                    wr_en_data = 0;
                end
            end
            $fclose(file_data);
        end
        $display("--- DATA LOAD COMPLETE ---");
        
        loading_phase = 0; 
        $display("--- STARTING SCHEDULER ---");

        repeat (200000) begin
            @(posedge clk);
            #1;
            if (enable && !invoke) invoke <= 1; 
            else invoke <= 0; 
        end 

        $display("TIMEOUT: Simulation finished.");
	#200;
        $finish;
    end

    // --- Output Monitor ---
    initial file_out = $fopen("out.txt", "w");

    always @(posedge clk) begin
        // READ LOGIC: If population > 0, assert Read Enable
        if (pop_result > 0) begin
             rd_en_result <= 1;
             $display("TB: Result FIFO Pop > 0. Reading...");
        end else begin 
             rd_en_result <= 0;
        end
        
        // WRITE LOGIC: If we asserted Read Enable LAST cycle, data is valid NOW
        if (rd_en_result) begin
            $fwrite(file_out, "%d\n", result_fifo_out);
            $display("TB: Wrote Result %d to file", result_fifo_out);
        end

        // Same for Status
        if (pop_status > 0) rd_en_status <= 1;
        else rd_en_status <= 0;
        
        if (rd_en_status) begin
            $fwrite(file_out, "%d\n", status_fifo_out);
            $display("TB: Wrote Status %d to file", status_fifo_out);
        end
    end
endmodule
