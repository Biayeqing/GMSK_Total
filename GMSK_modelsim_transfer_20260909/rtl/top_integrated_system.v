`timescale 1ns / 1ps

// Top-level connection between the GMSK receive samples and LLR calculator.
module top_integrated_system(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               vld,
    input  wire        [15:0] data_real,
    input  wire        [15:0] data_imag,
    input  wire signed [15:0] Lc,

    output wire signed [15:0] softOut,
    output wire               calc_done,
    output wire               llr_calc_done
);
    localparam integer LLR_WARMUP_RESULTS = 2;

    reg start_llr_cal;

    wire [159:0] real_fifo_out;
    wire [159:0] imag_fifo_out;
    wire         fifo_data_ready;
    wire         fifo_rd_en;
    wire         first_complete;
    wire signed [15:0] softOut_raw;
    wire               llr_calc_done_raw;
    reg  signed [15:0] softOut_valid;
    reg                llr_calc_done_valid;
    reg          [1:0] llr_warmup_count;

    // Raw completion must continue scheduling the internal calculations.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_llr_cal <= 1'b0;
        else if (first_complete || (llr_calc_done_raw && fifo_data_ready))
            start_llr_cal <= 1'b1;
        else
            start_llr_cal <= 1'b0;
    end

    // The first two raw decisions are pipeline startup values.  Suppress
    // their valid pulses; the first visible result then corresponds to
    // payload bit 0.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            softOut_valid       <= 16'sd0;
            llr_calc_done_valid <= 1'b0;
            llr_warmup_count    <= 2'd0;
        end else begin
            llr_calc_done_valid <= 1'b0;
            if (llr_calc_done_raw) begin
                if (llr_warmup_count < LLR_WARMUP_RESULTS)
                    llr_warmup_count <= llr_warmup_count + 1'b1;
                else begin
                    softOut_valid       <= softOut_raw;
                    llr_calc_done_valid <= 1'b1;
                end
            end
        end
    end

    assign softOut       = softOut_valid;
    assign llr_calc_done = llr_calc_done_valid;

    FIFO_Q15_Q5_10 fifo_module (
        .clk             (clk),
        .rst_n           (rst_n),
        .vld             (vld),
        .data_real       (data_real),
        .data_imag       (data_imag),
        .real_fifo_out   (real_fifo_out),
        .imag_fifo_out   (imag_fifo_out),
        .fifo_data_ready (fifo_data_ready),
        .first_complete  (first_complete),
        .test_rd_en      (fifo_rd_en)
    );

    top_LLRcalculate_with_FIFO #(
        .DATA_WIDTH (16),
        .NUM_STATES (8),
        .tbDepth    (2),
        .LOG_MIN    (-32768)
    ) llr_module (
        .clk             (clk),
        .rst_n           (rst_n),
        .start_llr_cal   (start_llr_cal),
        .real_fifo_out   (real_fifo_out),
        .imag_fifo_out   (imag_fifo_out),
        .fifo_data_ready (fifo_data_ready),
        .Lc              (Lc),
        .softOut         (softOut_raw),
        .calc_done       (calc_done),
        .llr_calc_done   (llr_calc_done_raw),
        .fifo_rd_en      (fifo_rd_en)
    );

endmodule
