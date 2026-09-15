// 40阶低通滤波器
module tx_lowpass_filter (
    input               clk,
    input               rst,
    input  signed [23:0]       data_in,        // (1,24,23) 有符号24位，23位小数
    input               din_vd,
    input  [23:0]       init_phs_in,    // (0,24,24) 初始相位
    output  reg [23:0]  data_out,       // (0,24,24) 输出
    output  reg         dout_vd
);

// 滤波器系数 - 对称结构，只需要一半的系数
// 系数格式：(1,16,15) 有符号16位，15位小数
reg signed [15:0] filt_coeff [0:20];

initial begin
    // 滤波器系数初始化
    filt_coeff[0]  = 16'hFF7C;
    filt_coeff[1]  = 16'h007F;
    filt_coeff[2]  = 16'h00B0;
    filt_coeff[3]  = 16'h00EC;
    filt_coeff[4]  = 16'h010B;
    filt_coeff[5]  = 16'h00EE;
    filt_coeff[6]  = 16'h007E;
    filt_coeff[7]  = 16'hFFBC;
    filt_coeff[8]  = 16'hFEC1;
    filt_coeff[9]  = 16'hFDC2;
    filt_coeff[10] = 16'hFD05;
    filt_coeff[11] = 16'hFCDB;//FCD3
    filt_coeff[12] = 16'hFD87;
    filt_coeff[13] = 16'hFF32;
    filt_coeff[14] = 16'h01DC;
    filt_coeff[15] = 16'h0553;
    filt_coeff[16] = 16'h0939;
    filt_coeff[17] = 16'h0D0F;  // 0.1020266
    filt_coeff[18] = 16'h104D;  // 0.1273239
    filt_coeff[19] = 16'h1276;  // 0.1442289
    filt_coeff[20] = 16'h1338;  // 0.1501702

end

// 移位寄存器 - 41阶滤波器
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg [23:0] din_sreg [0:40];  // 存储(1,24,23)格式数据

// 折叠相加结果 - 利用对称性减少乘法器
// 输入为无符号(0,24,24)，转换为有符号(1,25,24)进行运算
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [24:0] prodt_din [0:20];  // (1,25,24)

// 乘法器输出
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [40:0] prodt_L [0:20];  // (1,41,39)

// 截位后的乘积
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] prodt_dout [0:20];   // (1,25,24)

// 加法树中间结果
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] add_s1 [0:10];  // 第一级加法
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] add_s2 [0:5];   // 第二级加法
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [24:0] add_s3 [0:2];   // 第三级加法
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] add_s4 [0:1];   // 第四级加法
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] dout_L;          // 最终和
(* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [24:0] comp_dout_L;     // 补偿后的和

// 处理延迟
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg [42:0] din_vd_reg;  // 延迟寄存器，用于时序控制

// 临时变量
integer i, j;

// 输入有效信号延迟
always @(posedge clk or posedge rst) begin
    if (rst) begin
        din_vd_reg <= 42'd0;
        dout_vd <= 1'b0;
    end
    else begin
        din_vd_reg[0] <= din_vd;
        din_vd_reg[42:1] <= din_vd_reg[41:0];//移位
        dout_vd <= din_vd_reg[1];//|| din_vd_reg[42];
    end
end

// 移位寄存器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 41; i = i + 1) begin
            din_sreg[i] <= 24'd0;
        end
    end
    else if (din_vd) begin
        for (i = 40; i > 0; i = i - 1) begin
            din_sreg[i] <= din_sreg[i-1];
        end
        din_sreg[0] <= $signed(data_in);  // 有符号输入
    end
end

// 折叠相加，1-clock added here, total delay is 1-clock
//(1,24,23)->(1,25,24)

always @(*) begin
    // 处理20对对称系数
    for (i = 0; i < 20; i = i + 1) begin
        prodt_din[i] = {din_sreg[i][23], din_sreg[i]} + 
                      {din_sreg[40-i][23], din_sreg[40-i]};
    end
    // 中间系数（第20个，索引20）
    prodt_din[20] = {din_sreg[20][23], din_sreg[20]};
end

// 系数乘法
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 21; i = i + 1) begin
            prodt_L[i] <= 41'd0;
        end
    end
    else if (din_vd_reg[0]) begin
        for (i = 0; i < 21; i = i + 1) begin
            // (1,25,24) * (1,16,15) = (1,41,39)
            prodt_L[i] <= prodt_din[i] * $signed(filt_coeff[i]);
        end
    end
end

// 乘积截位到(1,25,24)格式
generate
    for (genvar i = 0; i < 21; i = i + 1) begin : prod_cut
        assign  prodt_dout[i] = {prodt_L[i][40], prodt_L[i][37:14]};//截掉溢出的保护位和低位
    end
endgenerate


// 加法树 - 第一级
assign add_s1[10] = prodt_dout[20]; 
generate
    for (genvar i = 0; i < 10; i = i + 1) begin : stage1_add
        assign add_s1[i] = prodt_dout[i*2] + prodt_dout[i*2+1];//两两相加20->11
    end
endgenerate

// 第2级加法
assign add_s2[5] = add_s1[10]; 
generate
    for (genvar i = 0; i < 5; i = i + 1) begin : stage2_add
        assign add_s2[i] = add_s1[2*i] + add_s1[2*i+1];//11->6
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
        // add_s3[2] <= add_s2[4] + add_s2[5];
        for (j = 0; j < 3; j = j + 1) begin
            add_s3[j] <= add_s2[2*j] + add_s2[2*j+1];//6->3
        end
    end
end


// 第4级加法
assign add_s4[1] = add_s3[2];
assign add_s4[0] = add_s3[0] + add_s3[1];


// 最终加法
assign dout_L = add_s4[0] + add_s4[1];

// 输出补偿计算
assign comp_dout_L = dout_L + 25'sd16777216; 


//data_out
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= 24'b0;
    end
    else begin
        if (din_vd_reg[1] && !din_vd_reg[2]) begin
            // 第一个时刻输出使用初始相位
            data_out <= init_phs_in;
        end
        else if (din_vd_reg[2] || din_vd_reg[42]) begin
            // 正常输出滤波结果
            if (dout_L[24] == 1'b0) begin
                data_out <= dout_L[23:0];//正数或0，直接去掉最高位
            end
            else begin
                data_out <= comp_dout_L[23:0];//负数，comp_dout_L低24位的值与dout_L直接去掉符号一样
            end
        end
        else begin
            data_out <= 24'b0;
        end
    end
end

endmodule