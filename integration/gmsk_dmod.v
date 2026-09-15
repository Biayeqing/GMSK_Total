`timescale 1ns / 1ps

// GMSK receive-only demodulator.
//
// Unlike bpsk_dmod, this module has no carrier-frequency estimation,
// carrier compensation, despreading, or frame accumulation.  It directly
// processes the valid complex baseband samples using the existing GMSK
// receive filter, 10x decimator, and LLR detector.
module gmsk_dmod #(
    parameter DATA_WIDTH = 16,
    parameter signed [15:0] LC_VALUE = 16'sd2
) (
    input                                  sys_clk,
    input                                  rst_n,
    input                                  enable,

    input                                  i_sample_vld,
    input                                  i_strobe_vld,
    input signed [DATA_WIDTH-1:0]          i_data_i,
    input signed [DATA_WIDTH-1:0]          i_data_q,

    output                                 o_dmod_bit_vld,
    output                                 o_dmod_bit
);

    // Reset the GMSK history whenever this modulation branch is inactive.
    wire gmsk_rst_n = rst_n && enable;

    // The current receive chain is Q1.15 and therefore requires 16-bit IQ.
    wire signed [15:0] sample_i = i_data_i[15:0];
    wire signed [15:0] sample_q = i_data_q[15:0];

    wire [15:0] rx_lpf_i;
    wire [15:0] rx_lpf_q;
    wire        rx_lpf_i_vld;
    wire        rx_lpf_q_vld;

    rx_lowpass_filter u_rx_lowpass_filter_i (
        .clk      (sys_clk),
        .rst      (~gmsk_rst_n),
        .data_in  (sample_i),
        .din_vd   (i_sample_vld && enable),
        .data_out (rx_lpf_i),
        .dout_vd  (rx_lpf_i_vld)
    );

    rx_lowpass_filter u_rx_lowpass_filter_q (
        .clk      (sys_clk),
        .rst      (~gmsk_rst_n),
        .data_in  (sample_q),
        .din_vd   (i_sample_vld && enable),
        .data_out (rx_lpf_q),
        .dout_vd  (rx_lpf_q_vld)
    );

    wire [15:0] symbol_i;
    wire [15:0] symbol_q;
    wire        symbol_i_vld;
    wire        symbol_q_vld;

    downsample_10x u_downsample_i (
        .clk            (sys_clk),
        .rst_n          (gmsk_rst_n),
        .data_in        (rx_lpf_i),
        .data_valid     (rx_lpf_i_vld && rx_lpf_q_vld),
        .data_out       (symbol_i),
        .data_out_valid (symbol_i_vld)
    );

    downsample_10x u_downsample_q (
        .clk            (sys_clk),
        .rst_n          (gmsk_rst_n),
        .data_in        (rx_lpf_q),
        .data_valid     (rx_lpf_i_vld && rx_lpf_q_vld),
        .data_out       (symbol_q),
        .data_out_valid (symbol_q_vld)
    );

    wire signed [15:0] soft_out;
    wire               llr_input_done;
    wire               llr_result_vld;

    top_integrated_system u_gmsk_llr (
        .clk           (sys_clk),
        .rst_n         (gmsk_rst_n),
        .vld           (symbol_i_vld && symbol_q_vld),
        .data_real     (symbol_i),
        .data_imag     (symbol_q),
        .Lc            (LC_VALUE),
        .softOut       (soft_out),
        .calc_done     (llr_input_done),
        .llr_calc_done (llr_result_vld)
    );

    // softOut = metric(bit=0) - metric(bit=1):
    // negative selects bit 1; non-negative selects bit 0.
    assign o_dmod_bit_vld = enable && llr_result_vld;
    assign o_dmod_bit     = soft_out[15];

    // i_strobe_vld belongs to the BPSK best-sample path.  The GMSK MLSE
    // detector consumes the complete oversampled stream instead.
    wire unused_i_strobe_vld = i_strobe_vld;

endmodule
