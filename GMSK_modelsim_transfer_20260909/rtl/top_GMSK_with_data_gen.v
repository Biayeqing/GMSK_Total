`timescale 1ns / 1ps

module top_GMSK_with_data_gen(
    input               clk_100M,
    input               rst,
    input               rst_dds,
    input        [23:0] init_phs_in,

    output wire signed [15:0] softOut,
    output wire               calc_done,
    output wire               llr_calc_done,
    output wire signed [15:0] softOut_legacy,
    output wire               calc_done_legacy,
    output wire               llr_calc_done_legacy,
    output wire signed [15:0] softOut_fir,
    output wire               calc_done_fir,
    output wire               llr_calc_done_fir,
    output wire        [15:0] dout_I,
    output wire        [15:0] dout_Q,
    output wire               dout_vd
);

    localparam integer DATA_LEN = 100000;
    // Two symbols fill the LLR core and two more replace the two suppressed
    // startup decisions, so four tail symbols are required for N outputs.
    localparam integer TAIL_LEN = 4;
    localparam         TAIL_BIT = 1'b0;

    wire data_in_wire;
    wire bit_valid_wire;

    reg [6:0]  cycle_counter;
    reg [16:0] data_index;
    reg        data_bit;
    reg        bit_valid_reg;
    reg        bit_valid_delay_reg;
    reg        payload_finish;
    reg        data_finish;
    reg [1:0]  tail_count;

    // MATLAB-generated payload, one binary digit per line.
    reg data_mem [0:DATA_LEN-1];
    integer mem_file_check;

    initial begin
        // Verilog strings must use '/' (or escaped '\\') in Windows paths.
        // Check the file explicitly so a missing vector cannot silently turn
        // data_mem/data_bit into X values.
        mem_file_check = $fopen(
            "tb/random_100k.mem",
            "r"
        );
        if (mem_file_check == 0) begin
            $display("ERROR: cannot open random_100k.mem; check the simulation path");
            $finish;
        end else begin
            $fclose(mem_file_check);
            $readmemb(
                "tb/random_100k.mem",
                data_mem
            );
            if ((data_mem[0] !== 1'b0) && (data_mem[0] !== 1'b1)) begin
                $display("ERROR: random_100k.mem opened but its data is invalid");
                $finish;
            end
            $display(
                "INFO: random_100k.mem loaded, first 16 bits = %b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b",
                data_mem[0],  data_mem[1],  data_mem[2],  data_mem[3],
                data_mem[4],  data_mem[5],  data_mem[6],  data_mem[7],
                data_mem[8],  data_mem[9],  data_mem[10], data_mem[11],
                data_mem[12], data_mem[13], data_mem[14], data_mem[15]
            );
        end
    end

    // Generate one source-bit request every 100 clocks.
    always @(posedge clk_100M or posedge rst) begin
        if (rst) begin
            cycle_counter <= 7'd0;
            bit_valid_reg <= 1'b0;
        end else if (cycle_counter == 7'd99) begin
            cycle_counter <= 7'd0;
            bit_valid_reg <= 1'b1;
        end else begin
            cycle_counter <= cycle_counter + 7'd1;
            bit_valid_reg <= 1'b0;
        end
    end

    // Send the payload followed by four known traceback flush bits.
    // data_finish is asserted only after the final tail bit is issued.
    always @(posedge clk_100M or posedge rst) begin
        if (rst) begin
            data_index     <= 17'd0;
            data_bit       <= 1'b0;
            payload_finish <= 1'b0;
            data_finish    <= 1'b0;
            tail_count     <= 2'd0;
        end else if (bit_valid_reg && !data_finish) begin
            if (!payload_finish) begin
                data_bit <= data_mem[data_index];
                if (data_index == DATA_LEN-1)
                    payload_finish <= 1'b1;
                else
                    data_index <= data_index + 17'd1;
            end else begin
                data_bit   <= TAIL_BIT;
                tail_count <= tail_count + 1'b1;
                if (tail_count == TAIL_LEN-1)
                    data_finish <= 1'b1;
            end
        end
    end

    // Delay valid one clock to align it with the newly registered data_bit.
    // The old data_finish value allows the final tail bit to pass.
    always @(posedge clk_100M or posedge rst) begin
        if (rst)
            bit_valid_delay_reg <= 1'b0;
        else
            bit_valid_delay_reg <= bit_valid_reg && !data_finish;
    end

    assign data_in_wire   = data_bit;
    assign bit_valid_wire = bit_valid_delay_reg;

    top_GMSK u_top_gmsk (
        .clk_100M      (clk_100M),
        .rst           (rst),
        .rst_dds       (rst_dds),
        .data_in       (data_in_wire),
        .bit_valid     (bit_valid_wire),
        .init_phs_in   (init_phs_in),
        .softOut       (softOut),
        .calc_done     (calc_done),
        .llr_calc_done (llr_calc_done),
        .softOut_legacy       (softOut_legacy),
        .calc_done_legacy     (calc_done_legacy),
        .llr_calc_done_legacy (llr_calc_done_legacy),
        .softOut_fir          (softOut_fir),
        .calc_done_fir        (calc_done_fir),
        .llr_calc_done_fir    (llr_calc_done_fir),
        .dout_I        (dout_I),
        .dout_Q        (dout_Q),
        .dout_vd       (dout_vd)
    );

endmodule
