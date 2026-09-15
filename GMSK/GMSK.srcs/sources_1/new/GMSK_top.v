`timescale 1ns / 1ps
module top_GMSK(
    input               clk_100M,
    input               rst,            // ��λ
    input               rst_dds,        // DDS��λ����
    
    // ����
    input               data_in,         // ��������Ʊ���
    input               data_valid,      // ���������Ч
    input               en, 

    // ��������
    input [23:0]        init_phs_in,    // ��ʼ��λ
    
    output wire signed [15:0] softOut,
    output wire calc_done,
    output wire llr_calc_done,
    output [15:0] dout_I,
    output [15:0] dout_Q,
    output dout_vd
    );

        // 内部信号声明
    wire gmsk_dout_vd;
    wire signed [15:0] gmsk_dout_I;
    wire signed [15:0] gmsk_dout_Q;
    wire [23:0] gmsk_inst_phs;
    wire [15:0]rx_lowpass_out_I;
    wire [15:0]rx_lowpass_out_Q;
    wire rx_lowpass_out_vd_I;
    wire rx_lowpass_out_vd_Q;
    wire [15:0]downsample_out_I;
    wire downsample_out_vd_I;
    wire [15:0]downsample_out_Q;
    wire downsample_out_vd_Q;
    wire bit_valid;

    assign bit_valid=data_valid&&en;

gmsk_modulator_top u_gmsk_modulator (
    // 时钟与复位
    .clk_100M       (clk_100M),          // 100MHz时钟
    .rst            (rst),          // 同步复位
    .rst_dds        (rst_dds),           // DDS复位信号
    
    // 数据输入
    .data_in        (data_in),       // 输入数据比特
    // .data_valid     (data_valid),    // 输入数据有效
    // .en             (en),    // 模块使能
    .bit_valid      (bit_valid),
    // 初始相位
    .init_phs_in    (init_phs_in),  // 初始相位 - 直接连接顶层输入
    
    // 输出
    .dout_vd        (gmsk_dout_vd),     // 输出数据有效
    .dout_I         (gmsk_dout_I),      // I路输出
    .dout_Q         (gmsk_dout_Q)    // Q路输出
);

// rx_lowpass_filter u_rx_lowpass_filter_I (
//     .clk  (clk_100M) ,
//     .rst (rst),
//     .data_in(gmsk_dout_I),
//     .din_vd(gmsk_dout_vd),
//     .init_phs_in(init_phs_in),
//     .data_out(rx_lowpass_out_I),
//     .dout_vd(rx_lowpass_out_vd_I)
// );

// rx_lowpass_filter u_rx_lowpass_filter_Q (
//     .clk  (clk_100M) ,
//     .rst (rst),
//     .data_in(gmsk_dout_Q),
//     .din_vd(gmsk_dout_vd),
//     .init_phs_in(init_phs_in),
//     .data_out(rx_lowpass_out_Q),
//     .dout_vd(rx_lowpass_out_vd_Q)
// );

downsample_10x u_downsample_10x_I (
    .clk           (clk_100M),          // 输入时钟
    .rst_n         (~rst),        // 输入异步低电平复位
    .data_in       (gmsk_dout_I),      // 输入 16 位数据
    .data_valid    (gmsk_dout_vd),   // 输入数据有效标志
    .data_out      (downsample_out_I),     // 输出 16 位下采样数据
    .data_out_valid(downsample_out_vd_I)// 输出数据有效标志
);


downsample_10x u_downsample_10x_Q (
    .clk           (clk_100M),          // 输入时钟
    .rst_n         (~rst),        // 输入异步低电平复位
    .data_in       (gmsk_dout_Q),      // 输入 16 位数据
    .data_valid    (gmsk_dout_vd),   // 输入数据有效标志
    .data_out      (downsample_out_Q),     // 输出 16 位下采样数据
    .data_out_valid(downsample_out_vd_Q)// 输出数据有效标志
);

// 实例化LLR系统
top_integrated_system u_top_llr_system (
    // 全局时钟与复位
    .clk            (clk_100M),              // 系统时钟
    .rst_n          (~rst),            // 异步复位，低有效
    
    // 数据输入接口
    .vld            (downsample_out_vd_I),       // 输入数据有效信号
    .data_real      (downsample_out_I),      // 实部数据，I路
    .data_imag      (downsample_out_Q),      // 虚部数据，Q路
    .Lc             (16'd2),       // 信道Lc值
    
    // 输出信号
    .softOut        (softOut),         // 软判决输出
    .calc_done      (calc_done),       // 计算完成标志
    .llr_calc_done  (llr_calc_done)    // LLR计算完成
);

assign  dout_vd = gmsk_dout_vd;
assign  dout_I = gmsk_dout_I;
assign  dout_Q = gmsk_dout_Q;

endmodule
