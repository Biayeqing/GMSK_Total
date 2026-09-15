// ============================================================================
// 33阶高斯滤波器，用于GMSK相位生成
// ============================================================================
module tx_guass_filter (
    input               clk,            // 时钟
    input               rst,            // 复位
    input [15:0]        data_in,        // 输入数据 (1,16,13)
    input               din_vd,         // 输入数据有效
    input [23:0]        init_phs_in,    // 初始相位 (0,24,24)
    output reg [23:0]    data_out,       // 输出相位 (1,24,23)
    output reg            dout_vd         // 输出有效
);

// ============================================================================
// 参数定义
// ============================================================================
// 滤波器系数 (1,16,15)
// 滤波器系数数组
reg signed [15:0] filt_coeff [0:16];


// 初始化滤波器系数
initial begin
    // 滤波器系数初始化
    filt_coeff[0]  = 16'h0001;
    filt_coeff[1]  = 16'h0002;
    filt_coeff[2]  = 16'h0005;
    filt_coeff[3]  = 16'h000A;
    filt_coeff[4]  = 16'h0012;
    filt_coeff[5]  = 16'h0021;
    filt_coeff[6]  = 16'h0039;
    filt_coeff[7]  = 16'h005D;
    filt_coeff[8]  = 16'h008F;
    filt_coeff[9]  = 16'h00D3;
    filt_coeff[10] = 16'h0126;
    filt_coeff[11] = 16'h0186;
    filt_coeff[12] = 16'h01EB;
    filt_coeff[13] = 16'h024C;
    filt_coeff[14] = 16'h029C;
    filt_coeff[15] = 16'h02D1;
    filt_coeff[16] = 16'h02E4;
end

// ============================================================================
// 内部信号声明
// ============================================================================

// 移位寄存器
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [15:0] din_sreg [0:32];      // 33级移位寄存器

// 折叠相加后的输入
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [16:0] prodt_din [0:16];     // (1,17,13)

// 乘法结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [32:0] prodt_L [0:16];       // (1,33,28)

// 截位后的乘积
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] prodt_dout [0:16];   // (1,25,24)

// 多级加法器
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] add_s1 [0:8];        // 第1级加法结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] add_s2 [0:4];        // 第2级加法结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed  [24:0] add_s3 [0:2];         // 第3级加法结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] add_s4 [0:1];        // 第4级加法结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] dout_L;              // 最终加法结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] comp_dout_L;         // 有符号转无符号补偿

// 处理延迟
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg [34:0] din_vd_reg;                  // 35级有效信号延迟

// 临时变量
integer i, j;

// ============================================================================
// 有效信号延迟逻辑
// ============================================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        din_vd_reg <= 35'b0;
        dout_vd <= 1'b0;
    end
    else begin
        din_vd_reg[0] <= din_vd;//数据输入时赋值
        din_vd_reg[34:1] <= din_vd_reg[33:0];
        // dout_vd <= din_vd_reg[1] || din_vd_reg[34];  // 1 时钟周期提前用于初始相位设置
        dout_vd <=  din_vd_reg[2];
    end
end



// ============================================================================
// 移位寄存器
// ============================================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 33; i = i + 1) begin
            din_sreg[i] <= 16'b0;
        end
    end
    else if (din_vd) begin
        for (i = 32; i > 0; i = i - 1) begin
            din_sreg[i] <= din_sreg[i-1];//移位
        end
        din_sreg[0] <= $signed(data_in);//数据赋值给寄存器
    end
end

// ============================================================================
// 折叠相加组合逻辑,1-clock added here, total delay is 1-clock
// ============================================================================
always @(*) begin
    // 前16个对称对
    for (i = 0; i < 16; i = i + 1) begin
        prodt_din[i] = {din_sreg[i][15], din_sreg[i]} + 
                      {din_sreg[32-i][15], din_sreg[32-i]};//{din_sreg[i][15], din_sreg[i]}是第i个移位寄存器的最高位（符号位）拼接移位寄存器的值
    end
    // 中间第16个
    prodt_din[16] = {din_sreg[16][15], din_sreg[16]};
end

// ============================================================================
// 系数乘法，输出 = 系数*折叠相加的值 ,1-clock processing/pipeline delay added here, total delay is 2-clck  
// ============================================================================
always @(posedge clk or posedge rst) begin  //(1,33,28)
    if (rst) begin
        for (i = 0; i < 17; i = i + 1) begin
            prodt_L[i] <= 33'b0;
        end
    end
    else if (din_vd_reg[0]) begin
        for (i = 0; i < 17; i = i + 1) begin
            prodt_L[i] <= prodt_din[i] * $signed(filt_coeff [i]);//系数*折叠相加的值 
        end
    end
end

// ============================================================================
// 乘积截位
// ============================================================================
generate
    for (genvar i = 0; i < 17; i = i + 1) begin : prod_cut
        assign prodt_dout[i] = {prodt_L[i][32], prodt_L[i][27:4]};//截掉溢出的保护位和低位
    end
endgenerate

// ============================================================================
// 多级加法树 
// ============================================================================

// 第1级加法
assign add_s1[8] = prodt_dout[16];
generate
    for (genvar i = 0; i < 8; i = i + 1) begin : stage1_add
        assign add_s1[i] = prodt_dout[i*2] + prodt_dout[i*2+1];//两两相加16->9
    end
endgenerate
//多行的组合逻辑，用generate包含，genvar等价于for

// 第2级加法
assign add_s2[4] = add_s1[8];
generate
    for (genvar i = 0; i < 4; i = i + 1) begin : stage2_add
        assign add_s2[i] = add_s1[2*i] + add_s1[2*i+1];//9->5
    end
endgenerate

// 第3级加法（带流水线）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (j = 0; j < 3; j = j + 1) begin
            add_s3[j] <= 25'b0;
        end
    end
    else if (din_vd_reg[1]) begin
        add_s3[2] <= add_s2[4];
        for (j = 0; j < 2; j = j + 1) begin
            add_s3[j] <= add_s2[2*j] + add_s2[2*j+1];//5->3
        end
    end
end

// 第4级加法
assign add_s4[1] = add_s3[2];
assign add_s4[0] = add_s3[0] + add_s3[1];//3->2

// 最终加法
assign dout_L = add_s4[0] + add_s4[1];//2->1

// assign data_out = dout_L[24:1];

// 有符号转无符号补偿
// assign comp_dout_L = dout_L + 25'sd16777216;  // 有符号数范围：-2^24 到 2^24-1,无符号数范围：0 到 2^25-1,加上2^24可以将有符号数映射为无符号数

// ============================================================================
// data_out
// ============================================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= 24'b0;
    end
    else begin
        if (din_vd_reg[1] && !din_vd_reg[2]) begin
            // 第一个时刻输出使用初始相位
            data_out <= init_phs_in;
        end
        else if (din_vd_reg[2]) begin
            // 正常输出滤波结果
            // if (dout_L[24] == 1'b0) begin
            //     data_out <= dout_L[23:0];//正数或0，直接去掉最高位
            // end
            // else begin
            //     data_out <= comp_dout_L[23:0];//负数，comp_dout_L低24位的值与dout_L直接去掉符号一样
            // end
            data_out = dout_L[24:1];
        end
        else begin
            data_out <= 24'b0;
        end
    end
end

endmodule