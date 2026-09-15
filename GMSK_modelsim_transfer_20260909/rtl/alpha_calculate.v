`timescale 1ns / 1ps
module alpha_calculate (
    input wire clk,
    input wire rst_n,
    input wire start_max_calc,  // 启动信号
    input wire signed [127:0] gamma_input_0,  // 添加有符号
    input wire signed [127:0] gamma_input_1,  // 添加有符号
    output reg signed [127:0] new_data,      // 添加有符号
    output reg done
);

    // 流水线寄存器
    reg signed [255:0] gamma_alpha;
    reg signed [255:0] gamma_alpha_reg1;  // 增加一级流水寄存器
    reg signed [255:0] gamma_alpha_reg2;  // 增加一级流水寄存器
    reg signed [15:0] max_of_gamma_alpha;  // 添加有符号
    reg [2:0] pipe_stage;
    reg [2:0] pipe_stage_next;  // 增加下一状态
    
    // 比较树中间信号 - 将声明移到使用位置之前
    wire signed [15:0] max_vals [7:0];  // 添加有符号
    wire signed [15:0] level1_max [3:0];  // 添加有符号
    wire signed [15:0] level2_max [1:0];  // 添加有符号
    wire signed [15:0] max_val_wire;  // 添加有符号
    
    // 状态定义
    localparam IDLE   = 3'b000;  // 空闲状态
    localparam STAGE1 = 3'b001;  // 阶段1：比较输入数据
    localparam STAGE2 = 3'b010;  // 阶段2：计算最大值
    localparam STAGE3 = 3'b100;  // 阶段3：减法计算
    localparam STAGE4 = 3'b101;  // 阶段3：减法计算

    function automatic signed [15:0] sat16;
        input signed [31:0] value;
        begin
            if (value > 32'sd32767)
                sat16 = 16'sh7FFF;
            else if (value < -32'sd32768)
                sat16 = -16'sd32768;
            else
                sat16 = value[15:0];
        end
    endfunction
    
// 从gamma_alpha中提取8个32位值
    assign max_vals[0] = gamma_alpha[31:0];
    assign max_vals[1] = gamma_alpha[63:32];
    assign max_vals[2] = gamma_alpha[95:64];
    assign max_vals[3] = gamma_alpha[127:96];
    assign max_vals[4] = gamma_alpha[159:128];
    assign max_vals[5] = gamma_alpha[191:160];
    assign max_vals[6] = gamma_alpha[223:192];
    assign max_vals[7] = gamma_alpha[255:224];
    
    // 比较树：查找最大值 - 使用有符号比较
    // 第一级比较
    assign level1_max[0] = ($signed(max_vals[0]) > $signed(max_vals[1])) ? 
                           $signed(max_vals[0]) : $signed(max_vals[1]);
    assign level1_max[1] = ($signed(max_vals[2]) > $signed(max_vals[3])) ? 
                           $signed(max_vals[2]) : $signed(max_vals[3]);
    assign level1_max[2] = ($signed(max_vals[4]) > $signed(max_vals[5])) ? 
                           $signed(max_vals[4]) : $signed(max_vals[5]);
    assign level1_max[3] = ($signed(max_vals[6]) > $signed(max_vals[7])) ? 
                           $signed(max_vals[6]) : $signed(max_vals[7]);
    
    // 第二级比较
    assign level2_max[0] = ($signed(level1_max[0]) > $signed(level1_max[1])) ? 
                           $signed(level1_max[0]) : $signed(level1_max[1]);
    assign level2_max[1] = ($signed(level1_max[2]) > $signed(level1_max[3])) ? 
                           $signed(level1_max[2]) : $signed(level1_max[3]);
    
    // 第三级比较（最终最大值）
    assign max_val_wire = ($signed(level2_max[0]) > $signed(level2_max[1])) ? 
                          $signed(level2_max[0]) : $signed(level2_max[1]);
    
    // 组合逻辑计算下一状态
    always @(*) begin
        if (!rst_n) begin
            pipe_stage_next = IDLE;
        end else begin
            case (pipe_stage)
                IDLE: begin
                    // 等待启动信号
                    if (start_max_calc) begin
                        pipe_stage_next = STAGE1;
                    end else begin
                        pipe_stage_next = IDLE;
                    end
                end
                STAGE1: pipe_stage_next = STAGE2;
                STAGE2: pipe_stage_next = STAGE3;
                STAGE3: pipe_stage_next = STAGE4;
                STAGE4: begin
                    // 计算完成后回到空闲状态
                    pipe_stage_next = IDLE;
                end
                default: pipe_stage_next = IDLE;
            endcase
        end
    end
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gamma_alpha <= 128'b0;
            gamma_alpha_reg1 <= 128'b0;
            max_of_gamma_alpha <= 16'b0;
            new_data <= 128'b0;
            done <= 1'b0;
            pipe_stage <= IDLE;
            gamma_alpha_reg2 <= 256'b0;
        end else begin
            // 状态寄存器更新
            pipe_stage <= pipe_stage_next;
            
            // 在空闲状态时复位done信号
            if (pipe_stage == IDLE) begin
                done <= 1'b0;
            end
            
            // 流水线第1级：比较gamma_input_0和gamma_input_1 - 使用有符号比较
            if (pipe_stage == STAGE1) begin
                // 并行比较所有8对数据，有符号扩展位数到32位防止溢出
                gamma_alpha[31:0]   <= ($signed(gamma_input_0[15:0])   > $signed(gamma_input_1[15:0]))   ? 
                                       $signed(gamma_input_0[15:0])   : $signed(gamma_input_1[15:0]);
                gamma_alpha[63:32]  <= ($signed(gamma_input_0[31:16])  > $signed(gamma_input_1[31:16]))  ? 
                                       $signed(gamma_input_0[31:16])  : $signed(gamma_input_1[31:16]);
                gamma_alpha[95:64]  <= ($signed(gamma_input_0[47:32])  > $signed(gamma_input_1[47:32]))  ? 
                                       $signed(gamma_input_0[47:32])  : $signed(gamma_input_1[47:32]);
                gamma_alpha[127:96]  <= ($signed(gamma_input_0[63:48])  > $signed(gamma_input_1[63:48]))  ? 
                                       $signed(gamma_input_0[63:48])  : $signed(gamma_input_1[63:48]);
                gamma_alpha[159:128]  <= ($signed(gamma_input_0[79:64])  > $signed(gamma_input_1[79:64]))  ? 
                                       $signed(gamma_input_0[79:64])  : $signed(gamma_input_1[79:64]);
                gamma_alpha[191:160]  <= ($signed(gamma_input_0[95:80])  > $signed(gamma_input_1[95:80]))  ? 
                                       $signed(gamma_input_0[95:80])  : $signed(gamma_input_1[95:80]);
                gamma_alpha[223:192] <= ($signed(gamma_input_0[111:96]) > $signed(gamma_input_1[111:96])) ? 
                                       $signed(gamma_input_0[111:96]) : $signed(gamma_input_1[111:96]);
                gamma_alpha[255:224]<= ($signed(gamma_input_0[127:112]) > $signed(gamma_input_1[127:112])) ? 
                                       $signed(gamma_input_0[127:112]) : $signed(gamma_input_1[127:112]);
            end
            
            // 流水线第2级：保存gamma_alpha并计算最大值
            if (pipe_stage == STAGE2) begin
                gamma_alpha_reg1 <= gamma_alpha;  // 保存当前gamma_alpha
                max_of_gamma_alpha <= $signed(max_val_wire);  // 从组合逻辑比较树获取最大值
            end
            
            // 流水线第3级：计算减法 - 使用有符号减法
            if (pipe_stage == STAGE3) begin
                // 使用保存的gamma_alpha_reg1进行计算
                gamma_alpha_reg2[31:0]   <= ($signed(gamma_alpha_reg1[31:0])   - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[63:32]  <= ($signed(gamma_alpha_reg1[63:32])  - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[95:64]  <= ($signed(gamma_alpha_reg1[95:64])  - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[127:96]  <= ($signed(gamma_alpha_reg1[127:96]) - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[159:128]  <= ($signed(gamma_alpha_reg1[159:128]) - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[191:160]  <= ($signed(gamma_alpha_reg1[191:160]) - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[223:192] <= ($signed(gamma_alpha_reg1[223:192]) - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
                gamma_alpha_reg2[255:224]<= ($signed(gamma_alpha_reg1[255:224]) - $signed({{16{max_of_gamma_alpha[15]}}, max_of_gamma_alpha}));
             end
             
             if (pipe_stage == STAGE4) begin//Q6,9只取整数部分
                new_data[15:0]   <= sat16($signed(gamma_alpha_reg2[31:0]));
                new_data[31:16]  <= sat16($signed(gamma_alpha_reg2[63:32]));
                new_data[47:32]  <= sat16($signed(gamma_alpha_reg2[95:64]));
                new_data[63:48]  <= sat16($signed(gamma_alpha_reg2[127:96]));
                new_data[79:64]  <= sat16($signed(gamma_alpha_reg2[159:128]));
                new_data[95:80]  <= sat16($signed(gamma_alpha_reg2[191:160]));
                new_data[111:96] <= sat16($signed(gamma_alpha_reg2[223:192]));
                new_data[127:112]<= sat16($signed(gamma_alpha_reg2[255:224]));
                // 计算完成，设置done信号
                done <= 1'b1;
            end
        end
    end

endmodule
