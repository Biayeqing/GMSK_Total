`timescale 1ns / 1ps
// 更新最大矩阵模块
module update_max_matrix_module (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [15:0] max0,
    input wire signed [15:0] max1,
    input wire signed [15:0] max2,
    input wire signed [15:0] max3,
    input wire signed [15:0] max4,
    input wire signed [15:0] max5,
    input wire signed [15:0] max6,
    input wire signed [15:0] max7,
    output reg signed [15:0] sub0,
    output reg signed [15:0] sub1,
    output reg signed [15:0] sub2,
    output reg signed [15:0] sub3,
    output reg signed [15:0] sub4,
    output reg signed [15:0] sub5,
    output reg signed [15:0] sub6,
    output reg signed [15:0] sub7,
    output reg done_update_max_matrix
);
    
    // 组合逻辑计算最大值
    reg signed [15:0] max_value_comb;
    reg signed [15:0] sub0_comb, sub1_comb, sub2_comb, sub3_comb;
    reg signed [15:0] sub4_comb, sub5_comb, sub6_comb, sub7_comb;
    
    // 使用更高效的比较树找最大值
    // 第一级比较
    reg signed [15:0] stage1_max_01, stage1_max_23, stage1_max_45, stage1_max_67;
    reg signed [15:0] stage2_max_0123, stage2_max_4567;
    
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

    always @(posedge clk) begin
        if (!rst_n) begin
            stage1_max_01 <= 16'b0;
            stage1_max_23 <= 16'b0;
            stage1_max_45 <= 16'b0;
            stage1_max_67 <= 16'b0;
        end else if (current_state == INIT) begin
            // 第一级：两两比较（有符号比较）
            stage1_max_01 <= ($signed(max0) >= $signed(max1)) ? $signed(max0) : $signed(max1);
            stage1_max_23 <= ($signed(max2) >= $signed(max3)) ? $signed(max2) : $signed(max3);
            stage1_max_45 <= ($signed(max4) >= $signed(max5)) ? $signed(max4) : $signed(max5);
            stage1_max_67 <= ($signed(max6) >= $signed(max7)) ? $signed(max6) : $signed(max7);
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            stage2_max_0123 <= 16'b0;
            stage2_max_4567 <= 16'b0;
        end else if (current_state == CORRELATION) begin
            // 第一级：两两比较（有符号比较）
             stage2_max_0123 <= ($signed(stage1_max_01) >= $signed(stage1_max_23)) ? $signed(stage1_max_01) : $signed(stage1_max_23);
             stage2_max_4567 <= ($signed(stage1_max_45) >= $signed(stage1_max_67)) ? $signed(stage1_max_45) : $signed(stage1_max_67);
        end
    end   

    always @(posedge clk) begin
        if (!rst_n) begin
            max_value_comb <= 16'b0;
        end else if (current_state == ACCUMULATE) begin
            // 第三级：最终比较得到最大值（有符号比较）
            max_value_comb <= ($signed(stage2_max_0123) >= $signed(stage2_max_4567)) ? $signed(stage2_max_0123) : $signed(stage2_max_4567);
        end
    end
 
    // 并行减法运算（有符号运算）
    always @(posedge clk) begin
        if (!rst_n) begin
            sub0_comb <= 16'b0;
            sub1_comb <= 16'b0;
            sub2_comb <= 16'b0;
            sub3_comb <= 16'b0;
            sub4_comb <= 16'b0;
            sub5_comb <= 16'b0;
            sub6_comb <= 16'b0;
            sub7_comb <= 16'b0;
        end else if (current_state == Comparison) begin
            // 第三级：最终比较得到最大值（有符号比较）
            sub0_comb <= $signed(max0) - $signed(max_value_comb);
            sub1_comb <= $signed(max1) - $signed(max_value_comb);
            sub2_comb <= $signed(max2) - $signed(max_value_comb);
            sub3_comb <= $signed(max3) - $signed(max_value_comb);
            sub4_comb <= $signed(max4) - $signed(max_value_comb);
            sub5_comb <= $signed(max5) - $signed(max_value_comb);
            sub6_comb <= $signed(max6) - $signed(max_value_comb);
            sub7_comb <= $signed(max7) - $signed(max_value_comb);
        end
    end
    
    // 同步输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            sub0 <= 16'b0;  // 有符号零
            sub1 <= 16'b0;
            sub2 <= 16'b0;
            sub3 <= 16'b0;
            sub4 <= 16'b0;
            sub5 <= 16'b0;
            sub6 <= 16'b0;
            sub7 <= 16'b0;
            done_update_max_matrix <= 0;
        end
        else if(current_state == DONE)begin
            // 每个时钟周期更新输出结果
            sub0 <= $signed(sub0_comb);
            sub1 <= $signed(sub1_comb);
            sub2 <= $signed(sub2_comb);
            sub3 <= $signed(sub3_comb);
            sub4 <= $signed(sub4_comb);
            sub5 <= $signed(sub5_comb);
            sub6 <= $signed(sub6_comb);
            sub7 <= $signed(sub7_comb);
            
            done_update_max_matrix <= 1;
        end
        else begin
            // 默认情况
            done_update_max_matrix <= 0;
        end
    end
    
endmodule