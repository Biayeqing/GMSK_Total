// ============================================================================
// 简化高效的GMSK调制器顶层模块
// ============================================================================
module mapping_guass (
    input               clk_100M,
    input               rst,            // 复位
    input               rst_dds,
    // 输入
    input               data_in,         // 输入二进制比特
    input               bit_valid,      // 输入比特有效


    // 控制输入
    input [23:0]        init_phs_in,    // 初始相位
    
    // 输出
    output [23:0]       lowpass_out,
    output              lowpass_vld,
    output              dout_vd,        // 输出数据有效
    output [15:0]       dout_I,         // I路输出
    output [15:0]       dout_Q         // Q路输出
   
    
);

// 内部连接信号
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire [15:0]     map_out;        // 映射模块输出
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            map_valid;      // 映射模块输出有效
// 高斯滤波器信号
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire [23:0]     inst_phs_out;   // 瞬时相位
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            inst_phs_vd;    // 瞬时相位有效
//同步fifo
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire [23:0]     fifo_out;   // 瞬时相位
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg             rd_en;    // 瞬时相位有效
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg             rd_en_delay;
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            fifo_empty;  // FIFO空标志
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            fifo_full;   // FIFO满标志
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg  [3:0]      rd_counter;


//上采样输出
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire [23:0]     data_sample_100M;        // 上采样模块输出
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            data_sample_vld_100M;      // 上采样模块输出有效

// 低通滤波器信号
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire [23:0]     data_lp_out;   // 瞬时相位
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            data_lp_vld;    // 瞬时相位有效

//DDS信号
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            dds_aresetn;    // DDS异步复位（低有效）
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire            dds_dout_vd;    // DDS输出有效
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire [31:0]     dds_dout;       // DDS输出数据（32位）


mapping u_mapping (
    .clk        (clk_100M),          // 时钟
    .rst        (rst),          // 同步复位
    
    // 原始二进制输入
    .bit_in     (data_in),       // 输入二进制比特
    .bit_valid  (bit_valid),    // 输入比特有效
    
    // 输出
    .map_out    (map_out),      // map输出
    .map_valid  (map_valid)     // 输出有效
);

// ============================================================================
// 实例化原始GMSK调制器
// ============================================================================
// 高斯滤波器实例
tx_guass_filter u_guass_filter (
    // .clk            (clk_10M),
    .clk            (clk_100M),
    .rst            (rst),
    .data_in        (map_out),
    .din_vd         (map_valid),
    .init_phs_in    ('d0),
    .data_out       (inst_phs_out),
    .dout_vd        (inst_phs_vd)
);


fifo_syn u_fifo_syn (
  .clk(clk_100M),      // input wire clk
  .din(inst_phs_out),      // input wire [23 : 0] din
  .wr_en(inst_phs_vd),  // input wire wr_en
  .rd_en(rd_en),  // input wire rd_en
  .dout(fifo_out),    // output wire [23 : 0] dout
  .full(fifo_full),    // output wire full
  .empty(fifo_empty)  // output wire empty
);

// 每隔10拍产生读使能
always @(posedge clk_100M) begin
    if (rst) begin
        rd_counter <= 0;
        rd_en <= 0;
    end else begin
        // 每10个时钟周期产生一个读使能
        if (rd_counter == 4'd9) begin
            rd_counter <= 0;
            // 只有当FIFO不空时才产生读使能
            rd_en <= ~fifo_empty;
        end else begin
            rd_counter <= rd_counter + 1;
            rd_en <= 0;
        end
    end
end


always@(posedge clk_100M or posedge rst) begin
    if(rst)
    begin
        rd_en_delay<=0;
    end
    else begin
        rd_en_delay<=rd_en;
    end
end


upsample u_upsample (
    .clk        (clk_100M),          // 时钟
    .rst        (rst),          // 同步复位
    
    // 原始二进制输入
    .bit_in     (fifo_out),     
    .bit_valid  (rd_en_delay), 
    
    // 输出
    .map_out    (data_sample_100M),      // map输出
    .map_valid  (data_sample_vld_100M)     // 输出有效
);

//低通滤波器实例
tx_lowpass_filter u_lowpass_filter(
    .clk            (clk_100M),
    .rst            (rst),
    .data_in        (data_sample_100M),
    .din_vd         (data_sample_vld_100M),
    .init_phs_in    (init_phs_in),
    .data_out       (data_lp_out),
    .dout_vd        (data_lp_vld)
);


// DDS复位生成器实例，控制dds_aresetn信号
dds_rstn_gen u_rst_gen (
    .clk            (clk_100M),
    .rst            (rst),
    .rst_dds        (rst_dds),
    .dds_aresetn    (dds_aresetn)
);

// DDS IP核实例
dds_ip u_dds (
    .aclk                   (clk_100M),
    .aclken                 (1'b1),             // 时钟使能常开
    .aresetn                (dds_aresetn),      //复位信号
    .s_axis_phase_tvalid    (data_lp_vld),
    .s_axis_phase_tdata     (data_lp_out),//滤波器的输出信号
    .m_axis_data_tvalid     (dds_dout_vd),
    .m_axis_data_tdata      (dds_dout)//dds输出信号
);

// ============================================================================
// 输出连接
// ============================================================================

assign lowpass_out = data_lp_out;
assign lowpass_vld = data_lp_vld;

assign dout_vd    = dds_dout_vd;
assign dout_I     = dds_dout[15:0];     // 低16位为I路（正弦）
assign dout_Q     = dds_dout[31:16];    // 高16位为Q路（余弦）


endmodule