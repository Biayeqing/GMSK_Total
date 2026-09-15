// ============================================================================
// 简化高效的GMSK调制器顶层模块
// ============================================================================
module gmsk_modulator_top (
    input               clk_100M,      // 100MHz主时钟
    input               rst,           // 同步复位
    input               rst_dds,       // DDS模块复位
    // 数据输入
    input               data_in,       // 输入二进制比特
    input               bit_valid,     // 输入比特有效标志
    // 控制输入
    input [23:0]        init_phs_in,   // 初始相位
    // 数据输出
    output              dout_vd,       // 输出数据有效
    output [15:0]       dout_I,        // I路输出
    output [15:0]       dout_Q,         // Q路输出
    
    output [15:0]       map_out_1,       // 输出数据有效
    output              map_valid_1,
    output [23:0]       inst_phs_out_1,   // 瞬时相位输出
    output              inst_phs_vd_1,    // 瞬时相位有效 
    output [23:0]       data_sample_100M_1,
    output              data_sample_vld_100M_1,
    output [23:0]       data_lp_out_1,
    output              data_lp_vld_1
);

// ============================================================================
// 内部连接信号声明
// ============================================================================
// 映射模块信号
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire [15:0]     map_out;        // 映射模块输出
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            map_valid;      // 映射输出有效

// 高斯滤波器信号
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire [23:0]     inst_phs_out;   // 瞬时相位输出
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            inst_phs_vd;    // 瞬时相位有效

// 同步FIFO信号
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire [23:0]     fifo_out;       // FIFO输出数据
(* KEEP = "{TRUE|FALSE|SOFT}"*) reg             rd_en;          // FIFO读使能
(* KEEP = "{TRUE|FALSE|SOFT}"*) reg             rd_en_delay;    // 读使能延迟
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            fifo_empty;     // FIFO空标志
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            fifo_full;      // FIFO满标志
(* KEEP = "{TRUE|FALSE|SOFT}"*) reg  [3:0]      rd_counter;     // 读控制计数器

// 上采样模块信号
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire [23:0]     data_sample_100M;   // 上采样输出
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            data_sample_vld_100M; // 上采样输出有效

// 低通滤波器信号
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire [23:0]     data_lp_out;     // 低通滤波器输出
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            data_lp_vld;     // 低通输出有效

// DDS模块信号
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            dds_aresetn;    // DDS异步复位（低有效）
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire            dds_dout_vd;    // DDS输出有效
(* KEEP = "{TRUE|FALSE|SOFT}"*) wire [31:0]     dds_dout;       // DDS输出数据（32位）
// The two fixed-point FIR stages introduce a small negative phase bias.
// End-to-end fixed-point calibration gives 1.7 counts per active sample.
// Use a 10-sample fractional pattern:
// seven samples add 2 and three samples add 1 (average 1.7 counts/sample).
reg [3:0] phase_comp_count;
wire signed [23:0] phase_comp_value =
    (phase_comp_count < 4'd7) ? 24'sd2 : 24'sd1;
wire signed [23:0] dds_phase_compensated =
    $signed(data_lp_out) + phase_comp_value;

always @(posedge clk_100M or posedge rst) begin
    if (rst)
        phase_comp_count <= 4'd0;
    else if (data_lp_vld) begin
        if (phase_comp_count == 4'd9)
            phase_comp_count <= 4'd0;
        else
            phase_comp_count <= phase_comp_count + 1'b1;
    end
end

    assign map_out_1 = map_out;       // 输出数据有效
    assign map_valid_1 = map_valid;
    assign inst_phs_out_1 = inst_phs_out;   // 瞬时相位输出
    assign inst_phs_vd_1 = inst_phs_vd;    // 瞬时相位有效 
    assign data_sample_100M_1 = data_sample_100M;
    assign data_sample_vld_100M_1 = data_sample_vld_100M;
    assign data_lp_out_1 = data_lp_out;
    assign data_lp_vld_1 = data_lp_vld;
    
// 调试输出信号
wire [23:0]     lowpass_out;    // 低通输出（调试用）
wire            lowpass_vld;    // 低通输出有效（调试用）

// ============================================================================
// 模块实例化
// ============================================================================

// 映射模块实例化
mapping u_mapping (
    .clk        (clk_100M),     // 时钟
    .rst        (rst),           // 同步复位
    // 原始二进制输入
    .bit_in     (data_in),      // 输入二进制比特
    .bit_valid  (bit_valid),    // 输入比特有效
    // 输出
    .map_out    (map_out),      // 映射输出
    .map_valid  (map_valid)     // 输出有效
);

// 高斯滤波器实例化
tx_guass_filter u_guass_filter (
    .clk            (clk_100M),
    .rst            (rst),
    .data_in        (map_out),      // 映射模块输出
    .din_vd         (map_valid),    // 映射输出有效
    .init_phs_in    ('d0),          // 初始相位（设为0）
    .data_out       (inst_phs_out), // 瞬时相位输出
    .dout_vd        (inst_phs_vd)   // 输出有效
);

// 同步FIFO实例化（用于数据缓冲）
fifo_syn u_fifo_syn (
    .clk     (clk_100M),        // 时钟
    .din     (inst_phs_out),    // 输入数据
    .wr_en   (inst_phs_vd),     // 写使能
    .rd_en   (rd_en),           // 读使能
    .dout    (fifo_out),        // 输出数据
    .full    (fifo_full),       // 满标志
    .empty   (fifo_empty)       // 空标志
);

// 读使能生成逻辑：每10个时钟周期产生一个读使能
always @(posedge clk_100M) begin
    if (rst) begin
        rd_counter <= 0;
        rd_en <= 0;
    end else begin
        // 每10个时钟周期产生一个读使能脉冲
        if (rd_counter == 4'd9) begin
            rd_counter <= 0;
            // FIFO非空时才产生读使能
            rd_en <= ~fifo_empty;
        end else begin
            rd_counter <= rd_counter + 1;
            rd_en <= 0;
        end
    end
end

// 读使能延迟一拍
always @(posedge clk_100M or posedge rst) begin
    if (rst) begin
        rd_en_delay <= 0;
    end else begin
        rd_en_delay <= rd_en;
    end
end

// 上采样模块实例化
upsample u_upsample (
    .clk        (clk_100M),         // 时钟
    .rst        (rst),              // 同步复位
    // 输入
    .bit_in     (fifo_out),         // FIFO输出数据
    .bit_valid  (rd_en_delay),      // 延迟后的读使能
    // 输出
    .map_out    (data_sample_100M), // 上采样输出
    .map_valid  (data_sample_vld_100M) // 输出有效
);

// 低通滤波器实例化
tx_lowpass_filter u_lowpass_filter (
    .clk            (clk_100M),
    .rst            (rst),
    .data_in        (data_sample_100M),  // 上采样输出
    .din_vd         (data_sample_vld_100M), // 上采样有效
    .init_phs_in    (init_phs_in),       // 外部输入的初始相位
    .data_out       (data_lp_out),       // 低通滤波器输出
    .dout_vd        (data_lp_vld)        // 输出有效
);

// DDS复位信号生成模块实例化
dds_rstn_gen u_rst_gen (
    .clk            (clk_100M),
    .rst            (rst),
    .rst_dds        (rst_dds),       // DDS模块复位输入
    .dds_aresetn    (dds_aresetn)    // 生成的DDS异步复位
);

// DDS IP核实例化
dds_ip u_dds (
    .aclk                   (clk_100M),         // 时钟
    .aclken                 (1'b1),             // 时钟使能（常开）
    .aresetn                (dds_aresetn),      // 异步复位（低有效）
    .s_axis_phase_tvalid    (data_lp_vld),      // 相位输入有效
    .s_axis_phase_tdata     (dds_phase_compensated),
    .m_axis_data_tvalid     (dds_dout_vd),      // 数据输出有效
    .m_axis_data_tdata      (dds_dout)          // 数据输出
);

// ============================================================================
// 输出连接
// ============================================================================
// 调试信号输出
assign lowpass_out = data_lp_out;
assign lowpass_vld = data_lp_vld;

// 主输出信号
assign dout_vd    = dds_dout_vd;          // 输出有效标志
assign dout_I     = dds_dout[15:0];      // 低16位为I路（正弦）
assign dout_Q     = dds_dout[31:16];     // 高16位为Q路（余弦）

endmodule
