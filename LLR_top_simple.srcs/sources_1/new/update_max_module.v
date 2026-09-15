`timescale 1ns / 1ps
// 更新最大值模块
module update_max_module (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [1023:0] P_1_beta_reg, 
    input wire signed [1023:0] P_0_beta_reg,
    input wire SWITCH_MATRIX,  // 改为输入端口
    output reg signed [15:0] max0,
    output reg signed [15:0] max1,
    output reg signed [15:0] max2,
    output reg signed [15:0] max3,
    output reg signed [15:0] max4,
    output reg signed [15:0] max5,
    output reg signed [15:0] max6,
    output reg signed [15:0] max7,
    output reg done_update_max
);
    
    // 从1024位向量中提取各个16位元素
    reg signed [15:0] P1[0:7];
    reg signed [15:0] P2[0:7];
    reg signed [15:0] P3[0:7];
    reg signed [15:0] P4[0:7];
    reg signed [15:0] P5[0:7];
    reg signed [15:0] P6[0:7];
    reg signed [15:0] P7[0:7];
    reg signed [15:0] P8[0:7];
    
    // 组合计算结果
    reg signed [15:0] max0_comb;
    reg signed [15:0] max1_comb;
    reg signed [15:0] max2_comb;
    reg signed [15:0] max3_comb;
    reg signed [15:0] max4_comb;
    reg signed [15:0] max5_comb;
    reg signed [15:0] max6_comb;
    reg signed [15:0] max7_comb;
    
    // 为每个位置定义中间比较结果
    reg signed [15:0] stage1_max0_0, stage1_max0_1, stage1_max0_2, stage1_max0_3;
    reg signed [15:0] stage1_max1_0, stage1_max1_1, stage1_max1_2, stage1_max1_3;
    reg signed [15:0] stage1_max2_0, stage1_max2_1, stage1_max2_2, stage1_max2_3;
    reg signed [15:0] stage1_max3_0, stage1_max3_1, stage1_max3_2, stage1_max3_3;
    reg signed [15:0] stage1_max4_0, stage1_max4_1, stage1_max4_2, stage1_max4_3;
    reg signed [15:0] stage1_max5_0, stage1_max5_1, stage1_max5_2, stage1_max5_3;
    reg signed [15:0] stage1_max6_0, stage1_max6_1, stage1_max6_2, stage1_max6_3;
    reg signed [15:0] stage1_max7_0, stage1_max7_1, stage1_max7_2, stage1_max7_3;

    reg signed [15:0] stage2_max0_0, stage2_max0_1;
    reg signed [15:0] stage2_max1_0, stage2_max1_1;
    reg signed [15:0] stage2_max2_0, stage2_max2_1;
    reg signed [15:0] stage2_max3_0, stage2_max3_1;
    reg signed [15:0] stage2_max4_0, stage2_max4_1;
    reg signed [15:0] stage2_max5_0, stage2_max5_1;
    reg signed [15:0] stage2_max6_0, stage2_max6_1;
    reg signed [15:0] stage2_max7_0, stage2_max7_1;
    

    localparam [2:0] IDLE              = 3'b000;
    localparam [2:0] INIT              = 3'b001;
    localparam [2:0] CORRELATION       = 3'b010;
    localparam [2:0] ACCUMULATE        = 3'b011;
    localparam [2:0] Comparison        = 3'b100;
    localparam [2:0] DONE              = 3'b101;

    reg [2:0] current_state, next_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        case (current_state)
            IDLE: next_state = enable ? INIT : IDLE;
            INIT: next_state = CORRELATION;
            CORRELATION: next_state = ACCUMULATE;
            ACCUMULATE: next_state = Comparison;
            Comparison: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    reg [3:0] i; 
    // 使用assign和条件运算符
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                P1[i] <= 16'd0;
                P2[i] <= 16'd0;
                P3[i] <= 16'd0;
                P4[i] <= 16'd0;
                P5[i] <= 16'd0;
                P6[i] <= 16'd0;
                P7[i] <= 16'd0;
                P8[i] <= 16'd0;
            end
        end else if (current_state == INIT) begin
            P1[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[0] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[0 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[0 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[1] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[1 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[1 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[2] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[2 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[2 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[3] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[3 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[3 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[4] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[4 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[4 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[5] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[5 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[5 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[6] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[6 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[6 * 16 * 8+7 * 16 +: 16]);  // 列7

            P1[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+0 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+0 * 16 +: 16]);  // 列0
            P2[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+1 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+1 * 16 +: 16]);  // 列1
            P3[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+2 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+2 * 16 +: 16]);  // 列2
            P4[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+3 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+3 * 16 +: 16]);  // 列3
            P5[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+4 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+4 * 16 +: 16]);  // 列4
            P6[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+5 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+5 * 16 +: 16]);  // 列5
            P7[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+6 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+6 * 16 +: 16]);  // 列6
            P8[7] <= (!SWITCH_MATRIX) ? $signed(P_1_beta_reg[7 * 16 * 8+7 * 16 +: 16]) : $signed(P_0_beta_reg[7 * 16 * 8+7 * 16 +: 16]);  // 列7
        end
    end

    // 第一级并行比较 - 两两比较（有符号比较）
    always @(posedge clk) begin
        if (!rst_n) begin
            // 计算 max0
            stage1_max0_0 <= 16'b0;
            stage1_max0_1 <= 16'b0;
            stage1_max0_2 <= 16'b0;
            stage1_max0_3 <= 16'b0;
            // max1< <= 16'b0;
            stage1_max1_0 <= 16'b0;
            stage1_max1_1 <= 16'b0;
            stage1_max1_2 <= 16'b0;
            stage1_max1_3 <= 16'b0;
            // max2< <= 16'b0;
            stage1_max2_0 <= 16'b0;
            stage1_max2_1 <= 16'b0;
            stage1_max2_2 <= 16'b0;
            stage1_max2_3 <= 16'b0;
            // max3< <= 16'b0;
            stage1_max3_0 <= 16'b0;
            stage1_max3_1 <= 16'b0;
            stage1_max3_2 <= 16'b0;
            stage1_max3_3 <= 16'b0;
            // max4< <= 16'b0;
            stage1_max4_0 <= 16'b0;
            stage1_max4_1 <= 16'b0;
            stage1_max4_2 <= 16'b0;
            stage1_max4_3 <= 16'b0;
            // max5< <= 16'b0;
            stage1_max5_0 <= 16'b0;
            stage1_max5_1 <= 16'b0;
            stage1_max5_2 <= 16'b0;
            stage1_max5_3 <= 16'b0;
            // max6< <= 16'b0;
            stage1_max6_0 <= 16'b0;
            stage1_max6_1 <= 16'b0;
            stage1_max6_2 <= 16'b0;
            stage1_max6_3 <= 16'b0;
            // max7< <= 16'b0;
            stage1_max7_0 <= 16'b0;
            stage1_max7_1 <= 16'b0;
            stage1_max7_2 <= 16'b0;
            stage1_max7_3 <= 16'b0;
        end else if (current_state == CORRELATION) begin
            // 计算 max0
            stage1_max0_0 <= ($signed(P1[0]) > $signed(P2[0])) ? $signed(P1[0]) : $signed(P2[0]);
            stage1_max0_1 <= ($signed(P3[0]) > $signed(P4[0])) ? $signed(P3[0]) : $signed(P4[0]);
            stage1_max0_2 <= ($signed(P5[0]) > $signed(P6[0])) ? $signed(P5[0]) : $signed(P6[0]);
            stage1_max0_3 <= ($signed(P7[0]) > $signed(P8[0])) ? $signed(P7[0]) : $signed(P8[0]);
            // max1<
            stage1_max1_0 <= ($signed(P1[1]) > $signed(P2[1])) ? $signed(P1[1]) : $signed(P2[1]);
            stage1_max1_1 <= ($signed(P3[1]) > $signed(P4[1])) ? $signed(P3[1]) : $signed(P4[1]);
            stage1_max1_2 <= ($signed(P5[1]) > $signed(P6[1])) ? $signed(P5[1]) : $signed(P6[1]);
            stage1_max1_3 <= ($signed(P7[1]) > $signed(P8[1])) ? $signed(P7[1]) : $signed(P8[1]);
            // max2<
            stage1_max2_0 <= ($signed(P1[2]) > $signed(P2[2])) ? $signed(P1[2]) : $signed(P2[2]);
            stage1_max2_1 <= ($signed(P3[2]) > $signed(P4[2])) ? $signed(P3[2]) : $signed(P4[2]);
            stage1_max2_2 <= ($signed(P5[2]) > $signed(P6[2])) ? $signed(P5[2]) : $signed(P6[2]);
            stage1_max2_3 <= ($signed(P7[2]) > $signed(P8[2])) ? $signed(P7[2]) : $signed(P8[2]);
            // max3<
            stage1_max3_0 <= ($signed(P1[3]) > $signed(P2[3])) ? $signed(P1[3]) : $signed(P2[3]);
            stage1_max3_1 <= ($signed(P3[3]) > $signed(P4[3])) ? $signed(P3[3]) : $signed(P4[3]);
            stage1_max3_2 <= ($signed(P5[3]) > $signed(P6[3])) ? $signed(P5[3]) : $signed(P6[3]);
            stage1_max3_3 <= ($signed(P7[3]) > $signed(P8[3])) ? $signed(P7[3]) : $signed(P8[3]);
            // max4<
            stage1_max4_0 <= ($signed(P1[4]) > $signed(P2[4])) ? $signed(P1[4]) : $signed(P2[4]);
            stage1_max4_1 <= ($signed(P3[4]) > $signed(P4[4])) ? $signed(P3[4]) : $signed(P4[4]);
            stage1_max4_2 <= ($signed(P5[4]) > $signed(P6[4])) ? $signed(P5[4]) : $signed(P6[4]);
            stage1_max4_3 <= ($signed(P7[4]) > $signed(P8[4])) ? $signed(P7[4]) : $signed(P8[4]);
            // max5<
            stage1_max5_0 <= ($signed(P1[5]) > $signed(P2[5])) ? $signed(P1[5]) : $signed(P2[5]);
            stage1_max5_1 <= ($signed(P3[5]) > $signed(P4[5])) ? $signed(P3[5]) : $signed(P4[5]);
            stage1_max5_2 <= ($signed(P5[5]) > $signed(P6[5])) ? $signed(P5[5]) : $signed(P6[5]);
            stage1_max5_3 <= ($signed(P7[5]) > $signed(P8[5])) ? $signed(P7[5]) : $signed(P8[5]);
            // max6<
            stage1_max6_0 <= ($signed(P1[6]) > $signed(P2[6])) ? $signed(P1[6]) : $signed(P2[6]);
            stage1_max6_1 <= ($signed(P3[6]) > $signed(P4[6])) ? $signed(P3[6]) : $signed(P4[6]);
            stage1_max6_2 <= ($signed(P5[6]) > $signed(P6[6])) ? $signed(P5[6]) : $signed(P6[6]);
            stage1_max6_3 <= ($signed(P7[6]) > $signed(P8[6])) ? $signed(P7[6]) : $signed(P8[6]);
            // max7<
            stage1_max7_0 <= ($signed(P1[7]) > $signed(P2[7])) ? $signed(P1[7]) : $signed(P2[7]);
            stage1_max7_1 <= ($signed(P3[7]) > $signed(P4[7])) ? $signed(P3[7]) : $signed(P4[7]);
            stage1_max7_2 <= ($signed(P5[7]) > $signed(P6[7])) ? $signed(P5[7]) : $signed(P6[7]);
            stage1_max7_3 <= ($signed(P7[7]) > $signed(P8[7])) ? $signed(P7[7]) : $signed(P8[7]);
            end
        end

    // 第二级并行比较
    always @(posedge clk) begin
        if (!rst_n) begin
            stage2_max0_0 <= 16'b0;
            stage2_max0_1 <= 16'b0;        
            stage2_max1_0 <= 16'b0;
            stage2_max1_1 <= 16'b0;        
            stage2_max2_0 <= 16'b0;
            stage2_max2_1 <= 16'b0;        
            stage2_max3_0 <= 16'b0;
            stage2_max3_1 <= 16'b0;         
            stage2_max4_0 <= 16'b0;
            stage2_max4_1 <= 16'b0;         
            stage2_max5_0 <= 16'b0;
            stage2_max5_1 <= 16'b0;         
            stage2_max6_0 <= 16'b0;
            stage2_max6_1 <= 16'b0;          
            stage2_max7_0 <= 16'b0;
            stage2_max7_1 <= 16'b0;
        end else if (current_state == ACCUMULATE) begin
            stage2_max0_0 <= ($signed(stage1_max0_0) > $signed(stage1_max0_1)) ? $signed(stage1_max0_0) : $signed(stage1_max0_1);
            stage2_max0_1 <= ($signed(stage1_max0_2) > $signed(stage1_max0_3)) ? $signed(stage1_max0_2) : $signed(stage1_max0_3);
            
            stage2_max1_0 <= ($signed(stage1_max1_0) > $signed(stage1_max1_1)) ? $signed(stage1_max1_0) : $signed(stage1_max1_1);
            stage2_max1_1 <= ($signed(stage1_max1_2) > $signed(stage1_max1_3)) ? $signed(stage1_max1_2) : $signed(stage1_max1_3);
            
            stage2_max2_0 <= ($signed(stage1_max2_0) > $signed(stage1_max2_1)) ? $signed(stage1_max2_0) : $signed(stage1_max2_1);
            stage2_max2_1 <= ($signed(stage1_max2_2) > $signed(stage1_max2_3)) ? $signed(stage1_max2_2) : $signed(stage1_max2_3);
            
            stage2_max3_0 <= ($signed(stage1_max3_0) > $signed(stage1_max3_1)) ? $signed(stage1_max3_0) : $signed(stage1_max3_1);
            stage2_max3_1 <= ($signed(stage1_max3_2) > $signed(stage1_max3_3)) ? $signed(stage1_max3_2) : $signed(stage1_max3_3);
            
            stage2_max4_0 <= ($signed(stage1_max4_0) > $signed(stage1_max4_1)) ? $signed(stage1_max4_0) : $signed(stage1_max4_1);
            stage2_max4_1 <= ($signed(stage1_max4_2) > $signed(stage1_max4_3)) ? $signed(stage1_max4_2) : $signed(stage1_max4_3);
            
            stage2_max5_0 <= ($signed(stage1_max5_0) > $signed(stage1_max5_1)) ? $signed(stage1_max5_0) : $signed(stage1_max5_1);
            stage2_max5_1 <= ($signed(stage1_max5_2) > $signed(stage1_max5_3)) ? $signed(stage1_max5_2) : $signed(stage1_max5_3);
            
            stage2_max6_0 <= ($signed(stage1_max6_0) > $signed(stage1_max6_1)) ? $signed(stage1_max6_0) : $signed(stage1_max6_1);
            stage2_max6_1 <= ($signed(stage1_max6_2) > $signed(stage1_max6_3)) ? $signed(stage1_max6_2) : $signed(stage1_max6_3);
            
            stage2_max7_0 <= ($signed(stage1_max7_0) > $signed(stage1_max7_1)) ? $signed(stage1_max7_0) : $signed(stage1_max7_1);
            stage2_max7_1 <= ($signed(stage1_max7_2) > $signed(stage1_max7_3)) ? $signed(stage1_max7_2) : $signed(stage1_max7_3);
        end
    end
    
    // 第三级并行比较得到最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max0_comb <= 16'b0;
            max1_comb <= 16'b0;
            max2_comb <= 16'b0;
            max3_comb <= 16'b0;
            max4_comb <= 16'b0;
            max5_comb <= 16'b0;
            max6_comb <= 16'b0;
            max7_comb <= 16'b0;
        end else if (current_state == Comparison) begin
            max0_comb <= ($signed(stage2_max0_0) > $signed(stage2_max0_1)) ? $signed(stage2_max0_0) : $signed(stage2_max0_1);
            max1_comb <= ($signed(stage2_max1_0) > $signed(stage2_max1_1)) ? $signed(stage2_max1_0) : $signed(stage2_max1_1);
            max2_comb <= ($signed(stage2_max2_0) > $signed(stage2_max2_1)) ? $signed(stage2_max2_0) : $signed(stage2_max2_1);
            max3_comb <= ($signed(stage2_max3_0) > $signed(stage2_max3_1)) ? $signed(stage2_max3_0) : $signed(stage2_max3_1);
            max4_comb <= ($signed(stage2_max4_0) > $signed(stage2_max4_1)) ? $signed(stage2_max4_0) : $signed(stage2_max4_1);
            max5_comb <= ($signed(stage2_max5_0) > $signed(stage2_max5_1)) ? $signed(stage2_max5_0) : $signed(stage2_max5_1);
            max6_comb <= ($signed(stage2_max6_0) > $signed(stage2_max6_1)) ? $signed(stage2_max6_0) : $signed(stage2_max6_1);
            max7_comb <= ($signed(stage2_max7_0) > $signed(stage2_max7_1)) ? $signed(stage2_max7_0) : $signed(stage2_max7_1);
       end
    end

    // 同步输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            max0 <= 16'b0;
            max1 <= 16'b0;
            max2 <= 16'b0;
            max3 <= 16'b0;
            max4 <= 16'b0;
            max5 <= 16'b0;
            max6 <= 16'b0;
            max7 <= 16'b0;
            done_update_max <= 0;
        end
        else if (current_state == DONE) begin
            // 组合逻辑已经计算完成，在时钟上升沿输出结果
            max0 <= $signed(max0_comb);
            max1 <= $signed(max1_comb);
            max2 <= $signed(max2_comb);
            max3 <= $signed(max3_comb);
            max4 <= $signed(max4_comb);
            max5 <= $signed(max5_comb);
            max6 <= $signed(max6_comb);
            max7 <= $signed(max7_comb);
            // 输出完成信号
            done_update_max <= 1;
            end
         else begin
            // 默认情况
            done_update_max <= 0;
         end
    end
    
endmodule