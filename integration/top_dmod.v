`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
// Copyright(C)            National Key Laboratory of Comm, UESTC
// All rights reserved     
// File name:              
// Last modified Date:     2026/03/03 15:42:48
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Wang Xin
// Created date:           2026/03/03 15:42:48
// mail      :             13834981969@163.com
// Version:                V1.0
// TEXT NAME:              top_dmod.v
// PATH:                   D:\WX\FHSS\Varible-Freqency-Hopping\V2\rtl\rx_src\dmod_src\top_dmod.v
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top_dmod 
#(parameter DATA_WIDTH = 16)
(
    input                               sys_clk                        ,
    input                               rst_n                          ,

    input                                       i_spfrm_start              , //超帧的开始
    input                                       i_sync_hop_sync_end        , //同步跳同步信息帧结束
    input                                       i_sample_vld               , //采样有效
    input                                       i_strobe_vld               , //最佳采样
    input        signed  [DATA_WIDTH-1: 0]      i_data_i                   , //输入数据I支路
    input        signed  [DATA_WIDTH-1: 0]      i_data_q                   , //输入数据Q支路

    input               [   2: 0]              i_hop_type_state           , //跳类型状态 
    input               [   6: 0]              i_sync_hop_state           , //同步跳状态
    input               [   2: 0]              i_data_hop_state           , //数据跳状态
    input               [   5: 0]              i_sync_hop_frm_state       , //同步跳帧状态
    input               [   3: 0]              i_sync_hop_info_state      , //同步跳帧内数据段状态
    input               [   5: 0]              i_data_hop_frm_state       , //数据跳帧状态
    input               [   3: 0]              i_data_hop_info_state      , //数据跳帧内数据段状态
    input                                      i_spfrm_final_hop_frm      , //当前为超帧最后一跳最后一帧

    input               [  79: 0]              i_sync_info                , //同步信息
    input                                      i_sync_info_vld            , //同步信息有效

    output                                     o_dmod_bit_vld             ,//解调比特有效
    output                                     o_dmod_bit                  //解调比特       

);

    `include "frm_strc_def.vh" // 帧结构定义
    reg [79: 0]                         lr_sync_info_d;             //同步信息寄存
    reg                                 lr_sync_info_vld_d;         //同步信息有效寄存
    reg                [   4: 0]        lr_hop_rate                 ;//跳速
    reg                [  31: 0]        lr_hop_tod                  ;//随机数key值
    reg                [   1: 0]        lr_info_rate                ;//信息速率
    reg                [   1: 0]        lr_greg                     ;//调制方式

    reg [15 : 0] lr_businfo_blk_size; //当前超帧码块组大小
    reg [7 : 0] lr_businfo_accum_num; //当前超帧码块累加的次数
    reg [7 : 0] lr_businfo_blk_num;   //当前超帧码块数量
    always @(posedge sys_clk) begin: sync_info_d_proc
        if (!rst_n) begin
            lr_sync_info_d <= 0;
            lr_sync_info_vld_d <= 0;
            lr_hop_rate <= 0;
            lr_hop_tod <= 0;
            lr_info_rate <= 0;
            lr_greg <= 0;
        end else begin
            lr_sync_info_d <= i_sync_info;
            lr_sync_info_vld_d <= i_sync_info_vld;
            if (i_sync_info_vld) begin
                lr_hop_rate <= i_sync_info[SYNC_INFO_SEG_LEN * SYNC_INFO_SEG_NUM - 1 -: 5];
                lr_hop_tod <= i_sync_info[74 : 43];
                lr_info_rate <= i_sync_info[42 : 41];
                lr_greg <= i_sync_info[40 : 39];
            end
        end
    end

    always @(posedge sys_clk) begin: frm_info_blk_get_proc
        if (!rst_n) begin
            lr_businfo_blk_size <= 0;
            lr_businfo_accum_num <= 0;
            lr_businfo_blk_num <= 0;
        end else if (lr_sync_info_vld_d) begin
            if (lr_info_rate == 0) begin
                // info_rate == 32kbps
                lr_businfo_blk_size <= businfoblk_size_32k;
                                        // if mod type is 4fsk, accumulate 2 times; 
                lr_businfo_accum_num <= lr_greg == 2 ? 2 * spfrm_businfoblk_accnum_32k[lr_hop_rate]
                                        // otherwise(bpsk/gmsk), accumulate as normal
                                            : spfrm_businfoblk_accnum_32k[lr_hop_rate];
                lr_businfo_blk_num <= spfrm_businfoblk_num_32k[lr_hop_rate]; 
            end else if (lr_info_rate == 1) begin
                // info_rate == 9.6kbps
                lr_businfo_blk_size <= businfoblk_size_9_6k;
                lr_businfo_accum_num <= lr_greg == 2 ? 2 * spfrm_businfoblk_accnum_9_6k[lr_hop_rate]
                                                    : spfrm_businfoblk_accnum_9_6k[lr_hop_rate];
                lr_businfo_blk_num <= spfrm_businfoblk_num_9_6k[lr_hop_rate];
            end else if (lr_info_rate == 2) begin
                // info_rate == 2.4kbps
                lr_businfo_blk_size <= businfoblk_size_2_4k;
                lr_businfo_accum_num <= lr_greg == 2 ? 2 * spfrm_businfoblk_accnum_2_4k[lr_hop_rate]
                                                    : spfrm_businfoblk_accnum_2_4k[lr_hop_rate];
                lr_businfo_blk_num <= spfrm_businfoblk_num_2_4k[lr_hop_rate];
            end else if (lr_info_rate == 3) begin
                // info_rate == 1.2kbps
                lr_businfo_blk_size <= businfoblk_size_1_2k;
                lr_businfo_accum_num <= lr_greg == 2 ? 2 * spfrm_businfoblk_accnum_1_2k[lr_hop_rate]
                                                    : spfrm_businfoblk_accnum_1_2k[lr_hop_rate];
                lr_businfo_blk_num <= spfrm_businfoblk_num_1_2k[lr_hop_rate];
            end
        end
    end

    // `ifdef SIMULATION
    // wire bpsk_dmod_en = lr_greg == 2'd0 || lr_greg == 2'd1; //仿真时bpsk和gmsk都使能，便于功能验证
    // `else 
    wire bpsk_dmod_en = lr_greg == 2'd0; //正式使用时只有bpsk使能
    // `endif
    wire gmsk_dmod_en = lr_greg == 2'd1;
    wire fsk4_dmod_en = lr_greg == 2'd2;

    wire bpsk_dmod_bit_vld;
    wire bpsk_dmod_bit;
    wire gmsk_dmod_bit_vld;
    wire gmsk_dmod_bit;

    bpsk_dmod # (
    .DATA_WIDTH                         (DATA_WIDTH                ) 
    )
    bpsk_dmod_inst (
    .sys_clk                            (sys_clk                   ),
    .rst_n                              (rst_n                     ),
    .enable                             (bpsk_dmod_en              ),

    .i_businfo_blk_size                 (lr_businfo_blk_size       ),
    .i_businfo_accum_num                (lr_businfo_accum_num      ),
    .i_businfo_blk_num                  (lr_businfo_blk_num        ),

    .i_sample_vld                       (i_sample_vld              ),
    .i_strobe_vld                       (i_strobe_vld              ),
    .i_data_i                           (i_data_i                  ),
    .i_data_q                           (i_data_q                  ),

    .i_hop_type_state                   (i_hop_type_state          ),
    .i_sync_hop_state                   (i_sync_hop_state          ),
    .i_data_hop_state                   (i_data_hop_state          ),
    .i_sync_hop_frm_state               (i_sync_hop_frm_state      ),
    .i_sync_hop_info_state              (i_sync_hop_info_state     ),
    .i_data_hop_frm_state               (i_data_hop_frm_state      ),
    .i_data_hop_info_state              (i_data_hop_info_state     ),
    .i_spfrm_final_hop_frm              (i_spfrm_final_hop_frm     ),

    .o_dmod_bit_vld                     (bpsk_dmod_bit_vld         ),
    .o_dmod_bit                         (bpsk_dmod_bit             ) 
    );

    //================================================
    // GMSK 解调
    //================================================

    gmsk_dmod #(
    .DATA_WIDTH                         (DATA_WIDTH                 )
    )
    gmsk_dmod_inst (
    .sys_clk                            (sys_clk                    ),
    .rst_n                              (rst_n                      ),
    .enable                             (gmsk_dmod_en               ),

    // IQ输入
    .i_sample_vld                       (i_sample_vld               ),
    .i_strobe_vld                       (i_strobe_vld               ),
    .i_data_i                           (i_data_i                   ),
    .i_data_q                           (i_data_q                   ),

    .o_dmod_bit_vld                     (gmsk_dmod_bit_vld          ),
    .o_dmod_bit                         (gmsk_dmod_bit              )
    );

    // Select only the active demodulator.  The GMSK branch bypasses all
    // BPSK-specific frequency-offset estimation and compensation stages.
    assign o_dmod_bit_vld = gmsk_dmod_en ? gmsk_dmod_bit_vld :
                            bpsk_dmod_en ? bpsk_dmod_bit_vld :
                                           1'b0;
    assign o_dmod_bit     = gmsk_dmod_en ? gmsk_dmod_bit :
                            bpsk_dmod_en ? bpsk_dmod_bit :
                                           1'b0;
    // ===========================  
    // self check monitor
    // ==========================
    wire             lose_spfrm         ;
    wire             lose_blk           ;
    wire             frm_check_vld      ;
    wire  [  14: 0]  err_num_single_blk ;
    wire             err_num_vld        ;
    wire             detect_fail        ;
    wire  [  31: 0]  total_bit_num      ;
    wire  [  31: 0]  total_err_num      ;
    rx_ber_detect  #(.MATCH_MODE(1'b0))
    rx_ber_detect_inst (
    .clk                                (sys_clk                   ),
    .rst_n                              (rst_n                     ),
    .bit_in                             (o_dmod_bit                ),
    .bit_in_vld                         (o_dmod_bit_vld            ),
    .i_businfo_blk_size                 (lr_businfo_blk_size       ),
    .err_num                            (err_num_single_blk        ),
    .err_num_vld                        (err_num_vld               ),
    .detect_fail                        (detect_fail               ),
    .total_bit_num                      (total_bit_num             ),
    .total_err_num                      (total_err_num             ) 
    );

    frm_strc_check  frm_strc_check_inst (
    .clk                                (sys_clk                   ),
    .rst_n                              (rst_n                     ),

    .bit_vld_in                         (o_dmod_bit_vld            ),
    .hop_type_state                     (i_hop_type_state          ),
    .sync_hop_state                     (i_sync_hop_state          ),
    .data_hop_state                     (i_data_hop_state          ),

    .i_tod                              (lr_hop_tod                ),
    .i_sync_info_vld                    (lr_sync_info_vld_d        ),
    .i_businfo_blk_size                 (lr_businfo_blk_size       ),
    .i_businfo_accum_num                (lr_businfo_accum_num      ),
    .i_businfo_blk_num                  (lr_businfo_blk_num        ),

    .lose_spfrm                         (lose_spfrm              ),
    .lose_blk                           (lose_blk                ),
    .frm_check_vld                      (frm_check_vld           ) 
    );

    // 对vld进行分频，便于一次收集更多数据
    reg [9:0] divide_sync_info_cnt;
    wire [9:0] divide_sync_info_thr;
    reg divide_sync_info_vld;
    wire pos_sync_info_vld = {lr_sync_info_vld_d, i_sync_info} == 2'b01;
    always @(posedge sys_clk) begin
        if (!rst_n) begin
            divide_sync_info_cnt <= 0;
            divide_sync_info_vld <= 0;
        end else if (pos_sync_info_vld)begin
            divide_sync_info_cnt <= divide_sync_info_cnt == divide_sync_info_thr-1 ? 10'b0 : divide_sync_info_cnt + 10'b1;
            divide_sync_info_vld = (divide_sync_info_cnt == 10'b0);
        end else begin
            divide_sync_info_vld <= 0;
        end
    end

`ifndef SIMULATION
    vio_sync_info_vld_divide u_vio_sync_info_vld_divide (
    .clk(sys_clk),                // input wire clk
    .probe_out0(divide_sync_info_thr)  // output wire [9 : 0] probe_out0
    );

    ila_frm_ctrl1 u_ila_frm_ctrl1 (
    .clk                                (sys_clk                   ),// input wire clk
    .probe0                             (lose_spfrm                ),// input wire [0:0]  probe0  
    .probe1                             (lose_blk                  ),// input wire [0:0]  probe1 
    .probe2                             (frm_check_vld             ),// input wire [0:0]  probe2 
    .probe3                             (i_sync_info_vld           ),// input wire [0:0]  probe3 
    .probe4                             (i_spfrm_final_hop_frm     ),// input wire [0:0]  probe4 
    .probe5                             (i_sync_info               ),// input wire [79:0]  probe5
    .probe6                             (err_num_single_blk        ),// input wire [14:0]  probe6 
    .probe7                             (err_num_vld               ),// input wire [0:0]  probe7
    .probe8                             (o_dmod_bit                ),// input wire [0:0]  probe8
    .probe9                             (o_dmod_bit_vld            ),// input wire [0:0]  probe9
    .probe10                            (total_bit_num             ),// input wire [31:0]  probe10
    .probe11                            (total_err_num             ),// input wire [31:0]  probe11
    .probe12                            (detect_fail               ),// input wire [31:0]  probe12
    .probe13                            (divide_sync_info_vld      ) // input wire [0:0]  probe13
	);
`endif
                                                                    
                                                                   
endmodule
