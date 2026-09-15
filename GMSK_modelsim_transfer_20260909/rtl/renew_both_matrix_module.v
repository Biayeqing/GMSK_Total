// 更新矩阵模块 - generate版本
module renew_both_matrix_module (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [15:0] gamma_new_0,
    input wire signed [15:0] gamma_new_1,
    input wire signed [15:0] gamma_new_2,
    input wire signed [15:0] gamma_new_3,
    input wire signed [15:0] gamma_new_4,
    input wire signed [15:0] gamma_new_5,
    input wire signed [15:0] gamma_new_6,
    input wire signed [15:0] gamma_new_7,
    input wire signed [15:0] gamma_new_8,
    input wire signed [15:0] gamma_new_9,
    input wire signed [15:0] gamma_new_10,
    input wire signed [15:0] gamma_new_11,
    input wire signed [15:0] gamma_new_12,
    input wire signed [15:0] gamma_new_13,
    input wire signed [15:0] gamma_new_14,
    input wire signed [15:0] gamma_new_15,
    input wire signed [1023:0] P_0_beta,
    input wire signed [1023:0] P_1_beta,
    
    output reg signed [1023:0] P_0_beta_updated,
    output reg signed [1023:0] P_1_beta_updated,
    
    output reg done_renew  
);
    
    // 使用位选择语法访问向量
    reg signed [15:0] p0_elem [0:7][0:7];
    reg signed [15:0] p1_elem [0:7][0:7];
    
    reg signed [1023:0] p_1_init_matrix_constructed;
    reg signed [1023:0] p_0_init_matrix_constructed;
    // 临时加法结果 - 扩展1位防止溢出
    reg signed [15:0] p0_sum [0:7][0:15];
    reg signed [15:0] p1_sum [0:7][0:15];
    
    // 比较结果 - 截断回16位
    localparam [2:0] IDLE              = 3'b000;
    localparam [2:0] INIT              = 3'b001;
    localparam [2:0] CORRELATION       = 3'b010;
    localparam [2:0] ACCUMULATE        = 3'b011;
    localparam [2:0] DONE              = 3'b100;
    
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
            ACCUMULATE: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    reg [3:0] i,j;
    // 从1024位向量中提取矩阵元素
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    p1_elem[i][j] <= 16'd0;
                    p0_elem[i][j] <= 16'd0;
                end
            end
        end else if (current_state == INIT) begin
            p1_elem[0][0] <= P_1_beta[(0 * 8+0)*16 +: 16]; // 索引: 0 * 16 = 0
            p1_elem[0][1] <= P_1_beta[(0 * 8+1)*16 +: 16]; // 索引: 1 * 16 = 16
            p1_elem[0][2] <= P_1_beta[(0 * 8+2)*16 +: 16]; // 索引: 2 * 16 = 32
            p1_elem[0][3] <= P_1_beta[(0 * 8+3)*16 +: 16]; // 索引: 3 * 16 = 48
            p1_elem[0][4] <= P_1_beta[(0 * 8+4)*16 +: 16]; // 索引: 4 * 16 = 64
            p1_elem[0][5] <= P_1_beta[(0 * 8+5)*16 +: 16]; // 索引: 5 * 16 = 80
            p1_elem[0][6] <= P_1_beta[(0 * 8+6)*16 +: 16]; // 索引: 6 * 16 = 96
            p1_elem[0][7] <= P_1_beta[(0 * 8+7)*16 +: 16]; // 索引: 7 * 16 = 112
        
            p1_elem[1][0] <= P_1_beta[(1 * 8+0)*16 +: 16]; // 索引: 8 * 16 = 128
            p1_elem[1][1] <= P_1_beta[(1 * 8+1)*16 +: 16]; // 索引: 9 * 16 = 144
            p1_elem[1][2] <= P_1_beta[(1 * 8+2)*16 +: 16]; // 索引: 10 * 16 = 160
            p1_elem[1][3] <= P_1_beta[(1 * 8+3)*16 +: 16]; // 索引: 11 * 16 = 176
            p1_elem[1][4] <= P_1_beta[(1 * 8+4)*16 +: 16]; // 索引: 12 * 16 = 192
            p1_elem[1][5] <= P_1_beta[(1 * 8+5)*16 +: 16]; // 索引: 13 * 16 = 208
            p1_elem[1][6] <= P_1_beta[(1 * 8+6)*16 +: 16]; // 索引: 14 * 16 = 224
            p1_elem[1][7] <= P_1_beta[(1 * 8+7)*16 +: 16]; // 索引: 15 * 16 = 240
        
            p1_elem[2][0] <= P_1_beta[(2 * 8+0)*16 +: 16]; // 索引: 16 * 16 = 256
            p1_elem[2][1] <= P_1_beta[(2 * 8+1)*16 +: 16]; // 索引: 17 * 16 = 272
            p1_elem[2][2] <= P_1_beta[(2 * 8+2)*16 +: 16]; // 索引: 18 * 16 = 288
            p1_elem[2][3] <= P_1_beta[(2 * 8+3)*16 +: 16]; // 索引: 19 * 16 = 304
            p1_elem[2][4] <= P_1_beta[(2 * 8+4)*16 +: 16]; // 索引: 20 * 16 = 320
            p1_elem[2][5] <= P_1_beta[(2 * 8+5)*16 +: 16]; // 索引: 21 * 16 = 336
            p1_elem[2][6] <= P_1_beta[(2 * 8+6)*16 +: 16]; // 索引: 22 * 16 = 352
            p1_elem[2][7] <= P_1_beta[(2 * 8+7)*16 +: 16]; // 索引: 23 * 16 = 368
        
            p1_elem[3][0] <= P_1_beta[(3 * 8+0)*16 +: 16]; // 索引: 24 * 16 = 384
            p1_elem[3][1] <= P_1_beta[(3 * 8+1)*16 +: 16]; // 索引: 25 * 16 = 400
            p1_elem[3][2] <= P_1_beta[(3 * 8+2)*16 +: 16]; // 索引: 26 * 16 = 416
            p1_elem[3][3] <= P_1_beta[(3 * 8+3)*16 +: 16]; // 索引: 27 * 16 = 432
            p1_elem[3][4] <= P_1_beta[(3 * 8+4)*16 +: 16]; // 索引: 28 * 16 = 448
            p1_elem[3][5] <= P_1_beta[(3 * 8+5)*16 +: 16]; // 索引: 29 * 16 = 464
            p1_elem[3][6] <= P_1_beta[(3 * 8+6)*16 +: 16]; // 索引: 30 * 16 = 480
            p1_elem[3][7] <= P_1_beta[(3 * 8+7)*16 +: 16]; // 索引: 31 * 16 = 496
        
            p1_elem[4][0] <= P_1_beta[(4 * 8+0)*16 +: 16]; // 索引: 32 * 16 = 512
            p1_elem[4][1] <= P_1_beta[(4 * 8+1)*16 +: 16]; // 索引: 33 * 16 = 528
            p1_elem[4][2] <= P_1_beta[(4 * 8+2)*16 +: 16]; // 索引: 34 * 16 = 544
            p1_elem[4][3] <= P_1_beta[(4 * 8+3)*16 +: 16]; // 索引: 35 * 16 = 560
            p1_elem[4][4] <= P_1_beta[(4 * 8+4)*16 +: 16]; // 索引: 36 * 16 = 576
            p1_elem[4][5] <= P_1_beta[(4 * 8+5)*16 +: 16]; // 索引: 37 * 16 = 592
            p1_elem[4][6] <= P_1_beta[(4 * 8+6)*16 +: 16]; // 索引: 38 * 16 = 608
            p1_elem[4][7] <= P_1_beta[(4 * 8+7)*16 +: 16]; // 索引: 39 * 16 = 624
        
            p1_elem[5][0] <= P_1_beta[(5 * 8+0)*16 +: 16]; // 索引: 40 * 16 = 640
            p1_elem[5][1] <= P_1_beta[(5 * 8+1)*16 +: 16]; // 索引: 41 * 16 = 656
            p1_elem[5][2] <= P_1_beta[(5 * 8+2)*16 +: 16]; // 索引: 42 * 16 = 672
            p1_elem[5][3] <= P_1_beta[(5 * 8+3)*16 +: 16]; // 索引: 43 * 16 = 688
            p1_elem[5][4] <= P_1_beta[(5 * 8+4)*16 +: 16]; // 索引: 44 * 16 = 704
            p1_elem[5][5] <= P_1_beta[(5 * 8+5)*16 +: 16]; // 索引: 45 * 16 = 720
            p1_elem[5][6] <= P_1_beta[(5 * 8+6)*16 +: 16]; // 索引: 46 * 16 = 736
            p1_elem[5][7] <= P_1_beta[(5 * 8+7)*16 +: 16]; // 索引: 47 * 16 = 752
        
            p1_elem[6][0] <= P_1_beta[(6 * 8+0)*16 +: 16]; // 索引: 48 * 16 = 768
            p1_elem[6][1] <= P_1_beta[(6 * 8+1)*16 +: 16]; // 索引: 49 * 16 = 784
            p1_elem[6][2] <= P_1_beta[(6 * 8+2)*16 +: 16]; // 索引: 50 * 16 = 800
            p1_elem[6][3] <= P_1_beta[(6 * 8+3)*16 +: 16]; // 索引: 51 * 16 = 816
            p1_elem[6][4] <= P_1_beta[(6 * 8+4)*16 +: 16]; // 索引: 52 * 16 = 832
            p1_elem[6][5] <= P_1_beta[(6 * 8+5)*16 +: 16]; // 索引: 53 * 16 = 848
            p1_elem[6][6] <= P_1_beta[(6 * 8+6)*16 +: 16]; // 索引: 54 * 16 = 864
            p1_elem[6][7] <= P_1_beta[(6 * 8+7)*16 +: 16]; // 索引: 55 * 16 = 880
        
            p1_elem[7][0] <= P_1_beta[(7 * 8+0)*16 +: 16]; // 索引: 56 * 16 = 896
            p1_elem[7][1] <= P_1_beta[(7 * 8+1)*16 +: 16]; // 索引: 57 * 16 = 912
            p1_elem[7][2] <= P_1_beta[(7 * 8+2)*16 +: 16]; // 索引: 58 * 16 = 928
            p1_elem[7][3] <= P_1_beta[(7 * 8+3)*16 +: 16]; // 索引: 59 * 16 = 944
            p1_elem[7][4] <= P_1_beta[(7 * 8+4)*16 +: 16]; // 索引: 60 * 16 = 960
            p1_elem[7][5] <= P_1_beta[(7 * 8+5)*16 +: 16]; // 索引: 61 * 16 = 976
            p1_elem[7][6] <= P_1_beta[(7 * 8+6)*16 +: 16]; // 索引: 62 * 16 = 992
            p1_elem[7][7] <= P_1_beta[(7 * 8+7)*16 +: 16]; // 索引: 63 * 16 = 1008

            p0_elem[0][0] <= P_0_beta[(0 * 8+0)*16 +: 16]; // 索引: 0 * 16 = 0
            p0_elem[0][1] <= P_0_beta[(0 * 8+1)*16 +: 16]; // 索引: 1 * 16 = 16
            p0_elem[0][2] <= P_0_beta[(0 * 8+2)*16 +: 16]; // 索引: 2 * 16 = 32
            p0_elem[0][3] <= P_0_beta[(0 * 8+3)*16 +: 16]; // 索引: 3 * 16 = 48
            p0_elem[0][4] <= P_0_beta[(0 * 8+4)*16 +: 16]; // 索引: 4 * 16 = 64
            p0_elem[0][5] <= P_0_beta[(0 * 8+5)*16 +: 16]; // 索引: 5 * 16 = 80
            p0_elem[0][6] <= P_0_beta[(0 * 8+6)*16 +: 16]; // 索引: 6 * 16 = 96
            p0_elem[0][7] <= P_0_beta[(0 * 8+7)*16 +: 16]; // 索引: 7 * 16 = 112
        
            p0_elem[1][0] <= P_0_beta[(1 * 8+0)*16 +: 16]; // 索引: 8 * 16 = 128
            p0_elem[1][1] <= P_0_beta[(1 * 8+1)*16 +: 16]; // 索引: 9 * 16 = 144
            p0_elem[1][2] <= P_0_beta[(1 * 8+2)*16 +: 16]; // 索引: 10 * 16 = 160
            p0_elem[1][3] <= P_0_beta[(1 * 8+3)*16 +: 16]; // 索引: 11 * 16 = 176
            p0_elem[1][4] <= P_0_beta[(1 * 8+4)*16 +: 16]; // 索引: 12 * 16 = 192
            p0_elem[1][5] <= P_0_beta[(1 * 8+5)*16 +: 16]; // 索引: 13 * 16 = 208
            p0_elem[1][6] <= P_0_beta[(1 * 8+6)*16 +: 16]; // 索引: 14 * 16 = 224
            p0_elem[1][7] <= P_0_beta[(1 * 8+7)*16 +: 16]; // 索引: 15 * 16 = 240
        
            p0_elem[2][0] <= P_0_beta[(2 * 8+0)*16 +: 16]; // 索引: 16 * 16 = 256
            p0_elem[2][1] <= P_0_beta[(2 * 8+1)*16 +: 16]; // 索引: 17 * 16 = 272
            p0_elem[2][2] <= P_0_beta[(2 * 8+2)*16 +: 16]; // 索引: 18 * 16 = 288
            p0_elem[2][3] <= P_0_beta[(2 * 8+3)*16 +: 16]; // 索引: 19 * 16 = 304
            p0_elem[2][4] <= P_0_beta[(2 * 8+4)*16 +: 16]; // 索引: 20 * 16 = 320
            p0_elem[2][5] <= P_0_beta[(2 * 8+5)*16 +: 16]; // 索引: 21 * 16 = 336
            p0_elem[2][6] <= P_0_beta[(2 * 8+6)*16 +: 16]; // 索引: 22 * 16 = 352
            p0_elem[2][7] <= P_0_beta[(2 * 8+7)*16 +: 16]; // 索引: 23 * 16 = 368
        
            p0_elem[3][0] <= P_0_beta[(3 * 8+0)*16 +: 16]; // 索引: 24 * 16 = 384
            p0_elem[3][1] <= P_0_beta[(3 * 8+1)*16 +: 16]; // 索引: 25 * 16 = 400
            p0_elem[3][2] <= P_0_beta[(3 * 8+2)*16 +: 16]; // 索引: 26 * 16 = 416
            p0_elem[3][3] <= P_0_beta[(3 * 8+3)*16 +: 16]; // 索引: 27 * 16 = 432
            p0_elem[3][4] <= P_0_beta[(3 * 8+4)*16 +: 16]; // 索引: 28 * 16 = 448
            p0_elem[3][5] <= P_0_beta[(3 * 8+5)*16 +: 16]; // 索引: 29 * 16 = 464
            p0_elem[3][6] <= P_0_beta[(3 * 8+6)*16 +: 16]; // 索引: 30 * 16 = 480
            p0_elem[3][7] <= P_0_beta[(3 * 8+7)*16 +: 16]; // 索引: 31 * 16 = 496
        
            p0_elem[4][0] <= P_0_beta[(4 * 8+0)*16 +: 16]; // 索引: 32 * 16 = 512
            p0_elem[4][1] <= P_0_beta[(4 * 8+1)*16 +: 16]; // 索引: 33 * 16 = 528
            p0_elem[4][2] <= P_0_beta[(4 * 8+2)*16 +: 16]; // 索引: 34 * 16 = 544
            p0_elem[4][3] <= P_0_beta[(4 * 8+3)*16 +: 16]; // 索引: 35 * 16 = 560
            p0_elem[4][4] <= P_0_beta[(4 * 8+4)*16 +: 16]; // 索引: 36 * 16 = 576
            p0_elem[4][5] <= P_0_beta[(4 * 8+5)*16 +: 16]; // 索引: 37 * 16 = 592
            p0_elem[4][6] <= P_0_beta[(4 * 8+6)*16 +: 16]; // 索引: 38 * 16 = 608
            p0_elem[4][7] <= P_0_beta[(4 * 8+7)*16 +: 16]; // 索引: 39 * 16 = 624
        
            p0_elem[5][0] <= P_0_beta[(5 * 8+0)*16 +: 16]; // 索引: 40 * 16 = 640
            p0_elem[5][1] <= P_0_beta[(5 * 8+1)*16 +: 16]; // 索引: 41 * 16 = 656
            p0_elem[5][2] <= P_0_beta[(5 * 8+2)*16 +: 16]; // 索引: 42 * 16 = 672
            p0_elem[5][3] <= P_0_beta[(5 * 8+3)*16 +: 16]; // 索引: 43 * 16 = 688
            p0_elem[5][4] <= P_0_beta[(5 * 8+4)*16 +: 16]; // 索引: 44 * 16 = 704
            p0_elem[5][5] <= P_0_beta[(5 * 8+5)*16 +: 16]; // 索引: 45 * 16 = 720
            p0_elem[5][6] <= P_0_beta[(5 * 8+6)*16 +: 16]; // 索引: 46 * 16 = 736
            p0_elem[5][7] <= P_0_beta[(5 * 8+7)*16 +: 16]; // 索引: 47 * 16 = 752
        
            p0_elem[6][0] <= P_0_beta[(6 * 8+0)*16 +: 16]; // 索引: 48 * 16 = 768
            p0_elem[6][1] <= P_0_beta[(6 * 8+1)*16 +: 16]; // 索引: 49 * 16 = 784
            p0_elem[6][2] <= P_0_beta[(6 * 8+2)*16 +: 16]; // 索引: 50 * 16 = 800
            p0_elem[6][3] <= P_0_beta[(6 * 8+3)*16 +: 16]; // 索引: 51 * 16 = 816
            p0_elem[6][4] <= P_0_beta[(6 * 8+4)*16 +: 16]; // 索引: 52 * 16 = 832
            p0_elem[6][5] <= P_0_beta[(6 * 8+5)*16 +: 16]; // 索引: 53 * 16 = 848
            p0_elem[6][6] <= P_0_beta[(6 * 8+6)*16 +: 16]; // 索引: 54 * 16 = 864
            p0_elem[6][7] <= P_0_beta[(6 * 8+7)*16 +: 16]; // 索引: 55 * 16 = 880
        
            p0_elem[7][0] <= P_0_beta[(7 * 8+0)*16 +: 16]; // 索引: 56 * 16 = 896
            p0_elem[7][1] <= P_0_beta[(7 * 8+1)*16 +: 16]; // 索引: 57 * 16 = 912
            p0_elem[7][2] <= P_0_beta[(7 * 8+2)*16 +: 16]; // 索引: 58 * 16 = 928
            p0_elem[7][3] <= P_0_beta[(7 * 8+3)*16 +: 16]; // 索引: 59 * 16 = 944
            p0_elem[7][4] <= P_0_beta[(7 * 8+4)*16 +: 16]; // 索引: 60 * 16 = 960
            p0_elem[7][5] <= P_0_beta[(7 * 8+5)*16 +: 16]; // 索引: 61 * 16 = 976
            p0_elem[7][6] <= P_0_beta[(7 * 8+6)*16 +: 16]; // 索引: 62 * 16 = 992
            p0_elem[7][7] <= P_0_beta[(7 * 8+7)*16 +: 16]; // 索引: 63 * 16 = 1008
        end
     end

    // 预先计算加法结果，使用17位防止溢出
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j+1) begin
                    p1_sum[i][j] <= 16'd0;
                    p0_sum[i][j] <= 16'd0;
                end
            end
        end else if (current_state == CORRELATION) begin
           // i = 0
            p1_sum[0][0] <= $signed(p1_elem[0][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[0][1] <= $signed(p1_elem[0][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[0][2] <= $signed(p1_elem[0][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[0][3] <= $signed(p1_elem[0][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[0][4] <= $signed(p1_elem[0][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[0][5] <= $signed(p1_elem[0][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[0][6] <= $signed(p1_elem[0][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[0][7] <= $signed(p1_elem[0][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[0][8] <= $signed(p1_elem[0][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[0][9] <= $signed(p1_elem[0][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[0][10] <= $signed(p1_elem[0][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[0][11] <= $signed(p1_elem[0][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[0][12] <= $signed(p1_elem[0][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[0][13] <= $signed(p1_elem[0][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[0][14] <= $signed(p1_elem[0][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[0][15] <= $signed(p1_elem[0][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //1
            p1_sum[1][0] <= $signed(p1_elem[1][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[1][1] <= $signed(p1_elem[1][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[1][2] <= $signed(p1_elem[1][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[1][3] <= $signed(p1_elem[1][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[1][4] <= $signed(p1_elem[1][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[1][5] <= $signed(p1_elem[1][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[1][6] <= $signed(p1_elem[1][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[1][7] <= $signed(p1_elem[1][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[1][8] <= $signed(p1_elem[1][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[1][9] <= $signed(p1_elem[1][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[1][10] <= $signed(p1_elem[1][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[1][11] <= $signed(p1_elem[1][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[1][12] <= $signed(p1_elem[1][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[1][13] <= $signed(p1_elem[1][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[1][14] <= $signed(p1_elem[1][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[1][15] <= $signed(p1_elem[1][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //2
            p1_sum[2][0] <= $signed(p1_elem[2][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[2][1] <= $signed(p1_elem[2][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[2][2] <= $signed(p1_elem[2][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[2][3] <= $signed(p1_elem[2][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[2][4] <= $signed(p1_elem[2][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[2][5] <= $signed(p1_elem[2][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[2][6] <= $signed(p1_elem[2][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[2][7] <= $signed(p1_elem[2][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[2][8] <= $signed(p1_elem[2][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[2][9] <= $signed(p1_elem[2][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[2][10] <= $signed(p1_elem[2][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[2][11] <= $signed(p1_elem[2][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[2][12] <= $signed(p1_elem[2][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[2][13] <= $signed(p1_elem[2][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[2][14] <= $signed(p1_elem[2][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[2][15] <= $signed(p1_elem[2][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //3
            p1_sum[3][0] <= $signed(p1_elem[3][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[3][1] <= $signed(p1_elem[3][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[3][2] <= $signed(p1_elem[3][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[3][3] <= $signed(p1_elem[3][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[3][4] <= $signed(p1_elem[3][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[3][5] <= $signed(p1_elem[3][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[3][6] <= $signed(p1_elem[3][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[3][7] <= $signed(p1_elem[3][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[3][8] <= $signed(p1_elem[3][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[3][9] <= $signed(p1_elem[3][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[3][10] <= $signed(p1_elem[3][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[3][11] <= $signed(p1_elem[3][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[3][12] <= $signed(p1_elem[3][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[3][13] <= $signed(p1_elem[3][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[3][14] <= $signed(p1_elem[3][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[3][15] <= $signed(p1_elem[3][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //4
            p1_sum[4][0] <= $signed(p1_elem[4][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[4][1] <= $signed(p1_elem[4][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[4][2] <= $signed(p1_elem[4][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[4][3] <= $signed(p1_elem[4][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[4][4] <= $signed(p1_elem[4][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[4][5] <= $signed(p1_elem[4][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[4][6] <= $signed(p1_elem[4][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[4][7] <= $signed(p1_elem[4][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[4][8] <= $signed(p1_elem[4][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[4][9] <= $signed(p1_elem[4][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[4][10] <= $signed(p1_elem[4][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[4][11] <= $signed(p1_elem[4][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[4][12] <= $signed(p1_elem[4][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[4][13] <= $signed(p1_elem[4][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[4][14] <= $signed(p1_elem[4][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[4][15] <= $signed(p1_elem[4][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //5
            p1_sum[5][0] <= $signed(p1_elem[5][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[5][1] <= $signed(p1_elem[5][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[5][2] <= $signed(p1_elem[5][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[5][3] <= $signed(p1_elem[5][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[5][4] <= $signed(p1_elem[5][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[5][5] <= $signed(p1_elem[5][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[5][6] <= $signed(p1_elem[5][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[5][7] <= $signed(p1_elem[5][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[5][8] <= $signed(p1_elem[5][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[5][9] <= $signed(p1_elem[5][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[5][10] <= $signed(p1_elem[5][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[5][11] <= $signed(p1_elem[5][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[5][12] <= $signed(p1_elem[5][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[5][13] <= $signed(p1_elem[5][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[5][14] <= $signed(p1_elem[5][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[5][15] <= $signed(p1_elem[5][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //6
            p1_sum[6][0] <= $signed(p1_elem[6][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[6][1] <= $signed(p1_elem[6][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[6][2] <= $signed(p1_elem[6][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[6][3] <= $signed(p1_elem[6][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[6][4] <= $signed(p1_elem[6][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[6][5] <= $signed(p1_elem[6][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[6][6] <= $signed(p1_elem[6][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[6][7] <= $signed(p1_elem[6][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[6][8] <= $signed(p1_elem[6][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[6][9] <= $signed(p1_elem[6][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[6][10] <= $signed(p1_elem[6][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[6][11] <= $signed(p1_elem[6][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[6][12] <= $signed(p1_elem[6][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[6][13] <= $signed(p1_elem[6][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[6][14] <= $signed(p1_elem[6][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[6][15] <= $signed(p1_elem[6][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //7
            p1_sum[7][0] <= $signed(p1_elem[7][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p1_sum[7][1] <= $signed(p1_elem[7][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p1_sum[7][2] <= $signed(p1_elem[7][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p1_sum[7][3] <= $signed(p1_elem[7][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p1_sum[7][4] <= $signed(p1_elem[7][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p1_sum[7][5] <= $signed(p1_elem[7][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p1_sum[7][6] <= $signed(p1_elem[7][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p1_sum[7][7] <= $signed(p1_elem[7][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p1_sum[7][8] <= $signed(p1_elem[7][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p1_sum[7][9] <= $signed(p1_elem[7][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p1_sum[7][10] <= $signed(p1_elem[7][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p1_sum[7][11] <= $signed(p1_elem[7][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p1_sum[7][12] <= $signed(p1_elem[7][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p1_sum[7][13] <= $signed(p1_elem[7][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p1_sum[7][14] <= $signed(p1_elem[7][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p1_sum[7][15] <= $signed(p1_elem[7][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //00
            p0_sum[0][0] <= $signed(p0_elem[0][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[0][1] <= $signed(p0_elem[0][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[0][2] <= $signed(p0_elem[0][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[0][3] <= $signed(p0_elem[0][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[0][4] <= $signed(p0_elem[0][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[0][5] <= $signed(p0_elem[0][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[0][6] <= $signed(p0_elem[0][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[0][7] <= $signed(p0_elem[0][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[0][8] <= $signed(p0_elem[0][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[0][9] <= $signed(p0_elem[0][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[0][10] <= $signed(p0_elem[0][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[0][11] <= $signed(p0_elem[0][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[0][12] <= $signed(p0_elem[0][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[0][13] <= $signed(p0_elem[0][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[0][14] <= $signed(p0_elem[0][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[0][15] <= $signed(p0_elem[0][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //01
            p0_sum[1][0] <= $signed(p0_elem[1][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[1][1] <= $signed(p0_elem[1][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[1][2] <= $signed(p0_elem[1][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[1][3] <= $signed(p0_elem[1][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[1][4] <= $signed(p0_elem[1][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[1][5] <= $signed(p0_elem[1][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[1][6] <= $signed(p0_elem[1][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[1][7] <= $signed(p0_elem[1][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[1][8] <= $signed(p0_elem[1][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[1][9] <= $signed(p0_elem[1][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[1][10] <= $signed(p0_elem[1][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[1][11] <= $signed(p0_elem[1][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[1][12] <= $signed(p0_elem[1][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[1][13] <= $signed(p0_elem[1][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[1][14] <= $signed(p0_elem[1][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[1][15] <= $signed(p0_elem[1][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //02
            p0_sum[2][0] <= $signed(p0_elem[2][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[2][1] <= $signed(p0_elem[2][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[2][2] <= $signed(p0_elem[2][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[2][3] <= $signed(p0_elem[2][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[2][4] <= $signed(p0_elem[2][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[2][5] <= $signed(p0_elem[2][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[2][6] <= $signed(p0_elem[2][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[2][7] <= $signed(p0_elem[2][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[2][8] <= $signed(p0_elem[2][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[2][9] <= $signed(p0_elem[2][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[2][10] <= $signed(p0_elem[2][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[2][11] <= $signed(p0_elem[2][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[2][12] <= $signed(p0_elem[2][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[2][13] <= $signed(p0_elem[2][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[2][14] <= $signed(p0_elem[2][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[2][15] <= $signed(p0_elem[2][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //03
            p0_sum[3][0] <= $signed(p0_elem[3][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[3][1] <= $signed(p0_elem[3][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[3][2] <= $signed(p0_elem[3][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[3][3] <= $signed(p0_elem[3][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[3][4] <= $signed(p0_elem[3][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[3][5] <= $signed(p0_elem[3][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[3][6] <= $signed(p0_elem[3][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[3][7] <= $signed(p0_elem[3][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[3][8] <= $signed(p0_elem[3][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[3][9] <= $signed(p0_elem[3][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[3][10] <= $signed(p0_elem[3][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[3][11] <= $signed(p0_elem[3][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[3][12] <= $signed(p0_elem[3][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[3][13] <= $signed(p0_elem[3][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[3][14] <= $signed(p0_elem[3][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[3][15] <= $signed(p0_elem[3][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //04
            p0_sum[4][0] <= $signed(p0_elem[4][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[4][1] <= $signed(p0_elem[4][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[4][2] <= $signed(p0_elem[4][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[4][3] <= $signed(p0_elem[4][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[4][4] <= $signed(p0_elem[4][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[4][5] <= $signed(p0_elem[4][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[4][6] <= $signed(p0_elem[4][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[4][7] <= $signed(p0_elem[4][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[4][8] <= $signed(p0_elem[4][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[4][9] <= $signed(p0_elem[4][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[4][10] <= $signed(p0_elem[4][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[4][11] <= $signed(p0_elem[4][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[4][12] <= $signed(p0_elem[4][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[4][13] <= $signed(p0_elem[4][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[4][14] <= $signed(p0_elem[4][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[4][15] <= $signed(p0_elem[4][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //05
            p0_sum[5][0] <= $signed(p0_elem[5][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[5][1] <= $signed(p0_elem[5][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[5][2] <= $signed(p0_elem[5][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[5][3] <= $signed(p0_elem[5][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[5][4] <= $signed(p0_elem[5][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[5][5] <= $signed(p0_elem[5][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[5][6] <= $signed(p0_elem[5][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[5][7] <= $signed(p0_elem[5][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[5][8] <= $signed(p0_elem[5][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[5][9] <= $signed(p0_elem[5][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[5][10] <= $signed(p0_elem[5][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[5][11] <= $signed(p0_elem[5][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[5][12] <= $signed(p0_elem[5][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[5][13] <= $signed(p0_elem[5][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[5][14] <= $signed(p0_elem[5][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[5][15] <= $signed(p0_elem[5][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //06
            p0_sum[6][0] <= $signed(p0_elem[6][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[6][1] <= $signed(p0_elem[6][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[6][2] <= $signed(p0_elem[6][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[6][3] <= $signed(p0_elem[6][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[6][4] <= $signed(p0_elem[6][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[6][5] <= $signed(p0_elem[6][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[6][6] <= $signed(p0_elem[6][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[6][7] <= $signed(p0_elem[6][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[6][8] <= $signed(p0_elem[6][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[6][9] <= $signed(p0_elem[6][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[6][10] <= $signed(p0_elem[6][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[6][11] <= $signed(p0_elem[6][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[6][12] <= $signed(p0_elem[6][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[6][13] <= $signed(p0_elem[6][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[6][14] <= $signed(p0_elem[6][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[6][15] <= $signed(p0_elem[6][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        
            //07
            p0_sum[7][0] <= $signed(p0_elem[7][0]) + $signed({{5{gamma_new_0[15]}}, gamma_new_0[14:4]});
            p0_sum[7][1] <= $signed(p0_elem[7][5]) + $signed({{5{gamma_new_10[15]}}, gamma_new_10[14:4]});
            p0_sum[7][2] <= $signed(p0_elem[7][0]) + $signed({{5{gamma_new_1[15]}}, gamma_new_1[14:4]});
            p0_sum[7][3] <= $signed(p0_elem[7][5]) + $signed({{5{gamma_new_11[15]}}, gamma_new_11[14:4]});
            p0_sum[7][4] <= $signed(p0_elem[7][1]) + $signed({{5{gamma_new_2[15]}}, gamma_new_2[14:4]});
            p0_sum[7][5] <= $signed(p0_elem[7][4]) + $signed({{5{gamma_new_8[15]}}, gamma_new_8[14:4]});
            p0_sum[7][6] <= $signed(p0_elem[7][1]) + $signed({{5{gamma_new_3[15]}}, gamma_new_3[14:4]});
            p0_sum[7][7] <= $signed(p0_elem[7][4]) + $signed({{5{gamma_new_9[15]}}, gamma_new_9[14:4]});
            p0_sum[7][8] <= $signed(p0_elem[7][2]) + $signed({{5{gamma_new_4[15]}}, gamma_new_4[14:4]});
            p0_sum[7][9] <= $signed(p0_elem[7][7]) + $signed({{5{gamma_new_14[15]}}, gamma_new_14[14:4]});
            p0_sum[7][10] <= $signed(p0_elem[7][2]) + $signed({{5{gamma_new_5[15]}}, gamma_new_5[14:4]});
            p0_sum[7][11] <= $signed(p0_elem[7][7]) + $signed({{5{gamma_new_15[15]}}, gamma_new_15[14:4]});
            p0_sum[7][12] <= $signed(p0_elem[7][3]) + $signed({{5{gamma_new_6[15]}}, gamma_new_6[14:4]});
            p0_sum[7][13] <= $signed(p0_elem[7][6]) + $signed({{5{gamma_new_12[15]}}, gamma_new_12[14:4]});
            p0_sum[7][14] <= $signed(p0_elem[7][3]) + $signed({{5{gamma_new_7[15]}}, gamma_new_7[14:4]});
            p0_sum[7][15] <= $signed(p0_elem[7][6]) + $signed({{5{gamma_new_13[15]}}, gamma_new_13[14:4]});
        end
    end
    
    // 并行计算所有行 - 使用generate
always @(posedge clk) begin
        if (!rst_n) begin
            p_1_init_matrix_constructed <= 1024'b0;
            p_0_init_matrix_constructed <= 1024'b0;
        end else if (current_state == ACCUMULATE) begin
 // i = 0
            p_1_init_matrix_constructed[0 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[0][8]) > $signed(p1_sum[0][9])) ? p1_sum[0][8] : p1_sum[0][9];
            p_1_init_matrix_constructed[0 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[0][10]) > $signed(p1_sum[0][11])) ? p1_sum[0][10] : p1_sum[0][11];
            p_1_init_matrix_constructed[0 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[0][4]) > $signed(p1_sum[0][5])) ? p1_sum[0][4] : p1_sum[0][5];
            p_1_init_matrix_constructed[0 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[0][6]) > $signed(p1_sum[0][7])) ? p1_sum[0][6] : p1_sum[0][7];
            p_1_init_matrix_constructed[0 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[0][12]) > $signed(p1_sum[0][13])) ? p1_sum[0][12] : p1_sum[0][13];
            p_1_init_matrix_constructed[0 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[0][14]) > $signed(p1_sum[0][15])) ? p1_sum[0][14] : p1_sum[0][15];
            p_1_init_matrix_constructed[0 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[0][0]) > $signed(p1_sum[0][1])) ? p1_sum[0][0] : p1_sum[0][1];
            p_1_init_matrix_constructed[0 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[0][2]) > $signed(p1_sum[0][3])) ? p1_sum[0][2] : p1_sum[0][3];
    
            // i = 1
            p_1_init_matrix_constructed[1 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[1][8]) > $signed(p1_sum[1][9])) ? p1_sum[1][8] : p1_sum[1][9];
            p_1_init_matrix_constructed[1 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[1][10]) > $signed(p1_sum[1][11])) ? p1_sum[1][10] : p1_sum[1][11];
            p_1_init_matrix_constructed[1 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[1][4]) > $signed(p1_sum[1][5])) ? p1_sum[1][4] : p1_sum[1][5];
            p_1_init_matrix_constructed[1 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[1][6]) > $signed(p1_sum[1][7])) ? p1_sum[1][6] : p1_sum[1][7];
            p_1_init_matrix_constructed[1 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[1][12]) > $signed(p1_sum[1][13])) ? p1_sum[1][12] : p1_sum[1][13];
            p_1_init_matrix_constructed[1 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[1][14]) > $signed(p1_sum[1][15])) ? p1_sum[1][14] : p1_sum[1][15];
            p_1_init_matrix_constructed[1 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[1][0]) > $signed(p1_sum[1][1])) ? p1_sum[1][0] : p1_sum[1][1];
            p_1_init_matrix_constructed[1 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[1][2]) > $signed(p1_sum[1][3])) ? p1_sum[1][2] : p1_sum[1][3];
    
            // i = 2
            p_1_init_matrix_constructed[2 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[2][8]) > $signed(p1_sum[2][9])) ? p1_sum[2][8] : p1_sum[2][9];
            p_1_init_matrix_constructed[2 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[2][10]) > $signed(p1_sum[2][11])) ? p1_sum[2][10] : p1_sum[2][11];
            p_1_init_matrix_constructed[2 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[2][4]) > $signed(p1_sum[2][5])) ? p1_sum[2][4] : p1_sum[2][5];
            p_1_init_matrix_constructed[2 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[2][6]) > $signed(p1_sum[2][7])) ? p1_sum[2][6] : p1_sum[2][7];
            p_1_init_matrix_constructed[2 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[2][12]) > $signed(p1_sum[2][13])) ? p1_sum[2][12] : p1_sum[2][13];
            p_1_init_matrix_constructed[2 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[2][14]) > $signed(p1_sum[2][15])) ? p1_sum[2][14] : p1_sum[2][15];
            p_1_init_matrix_constructed[2 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[2][0]) > $signed(p1_sum[2][1])) ? p1_sum[2][0] : p1_sum[2][1];
            p_1_init_matrix_constructed[2 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[2][2]) > $signed(p1_sum[2][3])) ? p1_sum[2][2] : p1_sum[2][3];
    
            // i = 3
            p_1_init_matrix_constructed[3 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[3][8]) > $signed(p1_sum[3][9])) ? p1_sum[3][8] : p1_sum[3][9];
            p_1_init_matrix_constructed[3 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[3][10]) > $signed(p1_sum[3][11])) ? p1_sum[3][10] : p1_sum[3][11];
            p_1_init_matrix_constructed[3 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[3][4]) > $signed(p1_sum[3][5])) ? p1_sum[3][4] : p1_sum[3][5];
            p_1_init_matrix_constructed[3 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[3][6]) > $signed(p1_sum[3][7])) ? p1_sum[3][6] : p1_sum[3][7];
            p_1_init_matrix_constructed[3 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[3][12]) > $signed(p1_sum[3][13])) ? p1_sum[3][12] : p1_sum[3][13];
            p_1_init_matrix_constructed[3 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[3][14]) > $signed(p1_sum[3][15])) ? p1_sum[3][14] : p1_sum[3][15];
            p_1_init_matrix_constructed[3 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[3][0]) > $signed(p1_sum[3][1])) ? p1_sum[3][0] : p1_sum[3][1];
            p_1_init_matrix_constructed[3 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[3][2]) > $signed(p1_sum[3][3])) ? p1_sum[3][2] : p1_sum[3][3];
    
            // i = 4
            p_1_init_matrix_constructed[4 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[4][8]) > $signed(p1_sum[4][9])) ? p1_sum[4][8] : p1_sum[4][9];
            p_1_init_matrix_constructed[4 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[4][10]) > $signed(p1_sum[4][11])) ? p1_sum[4][10] : p1_sum[4][11];
            p_1_init_matrix_constructed[4 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[4][4]) > $signed(p1_sum[4][5])) ? p1_sum[4][4] : p1_sum[4][5];
            p_1_init_matrix_constructed[4 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[4][6]) > $signed(p1_sum[4][7])) ? p1_sum[4][6] : p1_sum[4][7];
            p_1_init_matrix_constructed[4 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[4][12]) > $signed(p1_sum[4][13])) ? p1_sum[4][12] : p1_sum[4][13];
            p_1_init_matrix_constructed[4 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[4][14]) > $signed(p1_sum[4][15])) ? p1_sum[4][14] : p1_sum[4][15];
            p_1_init_matrix_constructed[4 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[4][0]) > $signed(p1_sum[4][1])) ? p1_sum[4][0] : p1_sum[4][1];
            p_1_init_matrix_constructed[4 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[4][2]) > $signed(p1_sum[4][3])) ? p1_sum[4][2] : p1_sum[4][3];
    
            // i = 5
            p_1_init_matrix_constructed[5 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[5][8]) > $signed(p1_sum[5][9])) ? p1_sum[5][8] : p1_sum[5][9];
            p_1_init_matrix_constructed[5 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[5][10]) > $signed(p1_sum[5][11])) ? p1_sum[5][10] : p1_sum[5][11];
            p_1_init_matrix_constructed[5 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[5][4]) > $signed(p1_sum[5][5])) ? p1_sum[5][4] : p1_sum[5][5];
            p_1_init_matrix_constructed[5 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[5][6]) > $signed(p1_sum[5][7])) ? p1_sum[5][6] : p1_sum[5][7];
            p_1_init_matrix_constructed[5 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[5][12]) > $signed(p1_sum[5][13])) ? p1_sum[5][12] : p1_sum[5][13];
            p_1_init_matrix_constructed[5 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[5][14]) > $signed(p1_sum[5][15])) ? p1_sum[5][14] : p1_sum[5][15];
            p_1_init_matrix_constructed[5 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[5][0]) > $signed(p1_sum[5][1])) ? p1_sum[5][0] : p1_sum[5][1];
            p_1_init_matrix_constructed[5 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[5][2]) > $signed(p1_sum[5][3])) ? p1_sum[5][2] : p1_sum[5][3];
    
            // i = 6
            p_1_init_matrix_constructed[6 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[6][8]) > $signed(p1_sum[6][9])) ? p1_sum[6][8] : p1_sum[6][9];
            p_1_init_matrix_constructed[6 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[6][10]) > $signed(p1_sum[6][11])) ? p1_sum[6][10] : p1_sum[6][11];
            p_1_init_matrix_constructed[6 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[6][4]) > $signed(p1_sum[6][5])) ? p1_sum[6][4] : p1_sum[6][5];
            p_1_init_matrix_constructed[6 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[6][6]) > $signed(p1_sum[6][7])) ? p1_sum[6][6] : p1_sum[6][7];
            p_1_init_matrix_constructed[6 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[6][12]) > $signed(p1_sum[6][13])) ? p1_sum[6][12] : p1_sum[6][13];
            p_1_init_matrix_constructed[6 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[6][14]) > $signed(p1_sum[6][15])) ? p1_sum[6][14] : p1_sum[6][15];
            p_1_init_matrix_constructed[6 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[6][0]) > $signed(p1_sum[6][1])) ? p1_sum[6][0] : p1_sum[6][1];
            p_1_init_matrix_constructed[6 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[6][2]) > $signed(p1_sum[6][3])) ? p1_sum[6][2] : p1_sum[6][3];
    
            // i = 7
            p_1_init_matrix_constructed[7 * 128 + 0 * 16 +: 16] <= ($signed(p1_sum[7][8]) > $signed(p1_sum[7][9])) ? p1_sum[7][8] : p1_sum[7][9];
            p_1_init_matrix_constructed[7 * 128 + 1 * 16 +: 16] <= ($signed(p1_sum[7][10]) > $signed(p1_sum[7][11])) ? p1_sum[7][10] : p1_sum[7][11];
            p_1_init_matrix_constructed[7 * 128 + 2 * 16 +: 16] <= ($signed(p1_sum[7][4]) > $signed(p1_sum[7][5])) ? p1_sum[7][4] : p1_sum[7][5];
            p_1_init_matrix_constructed[7 * 128 + 3 * 16 +: 16] <= ($signed(p1_sum[7][6]) > $signed(p1_sum[7][7])) ? p1_sum[7][6] : p1_sum[7][7];
            p_1_init_matrix_constructed[7 * 128 + 4 * 16 +: 16] <= ($signed(p1_sum[7][12]) > $signed(p1_sum[7][13])) ? p1_sum[7][12] : p1_sum[7][13];
            p_1_init_matrix_constructed[7 * 128 + 5 * 16 +: 16] <= ($signed(p1_sum[7][14]) > $signed(p1_sum[7][15])) ? p1_sum[7][14] : p1_sum[7][15];
            p_1_init_matrix_constructed[7 * 128 + 6 * 16 +: 16] <= ($signed(p1_sum[7][0]) > $signed(p1_sum[7][1])) ? p1_sum[7][0] : p1_sum[7][1];
            p_1_init_matrix_constructed[7 * 128 + 7 * 16 +: 16] <= ($signed(p1_sum[7][2]) > $signed(p1_sum[7][3])) ? p1_sum[7][2] : p1_sum[7][3];

            p_0_init_matrix_constructed[0 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[0][8]) > $signed(p0_sum[0][9])) ? p0_sum[0][8] : p0_sum[0][9];
            p_0_init_matrix_constructed[0 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[0][10]) > $signed(p0_sum[0][11])) ? p0_sum[0][10] : p0_sum[0][11];
            p_0_init_matrix_constructed[0 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[0][4]) > $signed(p0_sum[0][5])) ? p0_sum[0][4] : p0_sum[0][5];
            p_0_init_matrix_constructed[0 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[0][6]) > $signed(p0_sum[0][7])) ? p0_sum[0][6] : p0_sum[0][7];
            p_0_init_matrix_constructed[0 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[0][12]) > $signed(p0_sum[0][13])) ? p0_sum[0][12] : p0_sum[0][13];
            p_0_init_matrix_constructed[0 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[0][14]) > $signed(p0_sum[0][15])) ? p0_sum[0][14] : p0_sum[0][15];
            p_0_init_matrix_constructed[0 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[0][0]) > $signed(p0_sum[0][1])) ? p0_sum[0][0] : p0_sum[0][1];
            p_0_init_matrix_constructed[0 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[0][2]) > $signed(p0_sum[0][3])) ? p0_sum[0][2] : p0_sum[0][3];

            // i = 1
            p_0_init_matrix_constructed[1 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[1][8]) > $signed(p0_sum[1][9])) ? p0_sum[1][8] : p0_sum[1][9];
            p_0_init_matrix_constructed[1 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[1][10]) > $signed(p0_sum[1][11])) ? p0_sum[1][10] : p0_sum[1][11];
            p_0_init_matrix_constructed[1 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[1][4]) > $signed(p0_sum[1][5])) ? p0_sum[1][4] : p0_sum[1][5];
            p_0_init_matrix_constructed[1 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[1][6]) > $signed(p0_sum[1][7])) ? p0_sum[1][6] : p0_sum[1][7];
            p_0_init_matrix_constructed[1 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[1][12]) > $signed(p0_sum[1][13])) ? p0_sum[1][12] : p0_sum[1][13];
            p_0_init_matrix_constructed[1 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[1][14]) > $signed(p0_sum[1][15])) ? p0_sum[1][14] : p0_sum[1][15];
            p_0_init_matrix_constructed[1 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[1][0]) > $signed(p0_sum[1][1])) ? p0_sum[1][0] : p0_sum[1][1];
            p_0_init_matrix_constructed[1 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[1][2]) > $signed(p0_sum[1][3])) ? p0_sum[1][2] : p0_sum[1][3];

            // i = 2
            p_0_init_matrix_constructed[2 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[2][8]) > $signed(p0_sum[2][9])) ? p0_sum[2][8] : p0_sum[2][9];
            p_0_init_matrix_constructed[2 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[2][10]) > $signed(p0_sum[2][11])) ? p0_sum[2][10] : p0_sum[2][11];
            p_0_init_matrix_constructed[2 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[2][4]) > $signed(p0_sum[2][5])) ? p0_sum[2][4] : p0_sum[2][5];
            p_0_init_matrix_constructed[2 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[2][6]) > $signed(p0_sum[2][7])) ? p0_sum[2][6] : p0_sum[2][7];
            p_0_init_matrix_constructed[2 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[2][12]) > $signed(p0_sum[2][13])) ? p0_sum[2][12] : p0_sum[2][13];
            p_0_init_matrix_constructed[2 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[2][14]) > $signed(p0_sum[2][15])) ? p0_sum[2][14] : p0_sum[2][15];
            p_0_init_matrix_constructed[2 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[2][0]) > $signed(p0_sum[2][1])) ? p0_sum[2][0] : p0_sum[2][1];
            p_0_init_matrix_constructed[2 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[2][2]) > $signed(p0_sum[2][3])) ? p0_sum[2][2] : p0_sum[2][3];

            // i = 3
            p_0_init_matrix_constructed[3 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[3][8]) > $signed(p0_sum[3][9])) ? p0_sum[3][8] : p0_sum[3][9];
            p_0_init_matrix_constructed[3 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[3][10]) > $signed(p0_sum[3][11])) ? p0_sum[3][10] : p0_sum[3][11];
            p_0_init_matrix_constructed[3 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[3][4]) > $signed(p0_sum[3][5])) ? p0_sum[3][4] : p0_sum[3][5];
            p_0_init_matrix_constructed[3 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[3][6]) > $signed(p0_sum[3][7])) ? p0_sum[3][6] : p0_sum[3][7];
            p_0_init_matrix_constructed[3 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[3][12]) > $signed(p0_sum[3][13])) ? p0_sum[3][12] : p0_sum[3][13];
            p_0_init_matrix_constructed[3 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[3][14]) > $signed(p0_sum[3][15])) ? p0_sum[3][14] : p0_sum[3][15];
            p_0_init_matrix_constructed[3 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[3][0]) > $signed(p0_sum[3][1])) ? p0_sum[3][0] : p0_sum[3][1];
            p_0_init_matrix_constructed[3 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[3][2]) > $signed(p0_sum[3][3])) ? p0_sum[3][2] : p0_sum[3][3];

            // i = 4
            p_0_init_matrix_constructed[4 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[4][8]) > $signed(p0_sum[4][9])) ? p0_sum[4][8] : p0_sum[4][9];
            p_0_init_matrix_constructed[4 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[4][10]) > $signed(p0_sum[4][11])) ? p0_sum[4][10] : p0_sum[4][11];
            p_0_init_matrix_constructed[4 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[4][4]) > $signed(p0_sum[4][5])) ? p0_sum[4][4] : p0_sum[4][5];
            p_0_init_matrix_constructed[4 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[4][6]) > $signed(p0_sum[4][7])) ? p0_sum[4][6] : p0_sum[4][7];
            p_0_init_matrix_constructed[4 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[4][12]) > $signed(p0_sum[4][13])) ? p0_sum[4][12] : p0_sum[4][13];
            p_0_init_matrix_constructed[4 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[4][14]) > $signed(p0_sum[4][15])) ? p0_sum[4][14] : p0_sum[4][15];
            p_0_init_matrix_constructed[4 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[4][0]) > $signed(p0_sum[4][1])) ? p0_sum[4][0] : p0_sum[4][1];
            p_0_init_matrix_constructed[4 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[4][2]) > $signed(p0_sum[4][3])) ? p0_sum[4][2] : p0_sum[4][3];

            // i = 5
            p_0_init_matrix_constructed[5 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[5][8]) > $signed(p0_sum[5][9])) ? p0_sum[5][8] : p0_sum[5][9];
            p_0_init_matrix_constructed[5 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[5][10]) > $signed(p0_sum[5][11])) ? p0_sum[5][10] : p0_sum[5][11];
            p_0_init_matrix_constructed[5 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[5][4]) > $signed(p0_sum[5][5])) ? p0_sum[5][4] : p0_sum[5][5];
            p_0_init_matrix_constructed[5 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[5][6]) > $signed(p0_sum[5][7])) ? p0_sum[5][6] : p0_sum[5][7];
            p_0_init_matrix_constructed[5 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[5][12]) > $signed(p0_sum[5][13])) ? p0_sum[5][12] : p0_sum[5][13];
            p_0_init_matrix_constructed[5 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[5][14]) > $signed(p0_sum[5][15])) ? p0_sum[5][14] : p0_sum[5][15];
            p_0_init_matrix_constructed[5 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[5][0]) > $signed(p0_sum[5][1])) ? p0_sum[5][0] : p0_sum[5][1];
            p_0_init_matrix_constructed[5 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[5][2]) > $signed(p0_sum[5][3])) ? p0_sum[5][2] : p0_sum[5][3];

            // i = 6
            p_0_init_matrix_constructed[6 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[6][8]) > $signed(p0_sum[6][9])) ? p0_sum[6][8] : p0_sum[6][9];
            p_0_init_matrix_constructed[6 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[6][10]) > $signed(p0_sum[6][11])) ? p0_sum[6][10] : p0_sum[6][11];
            p_0_init_matrix_constructed[6 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[6][4]) > $signed(p0_sum[6][5])) ? p0_sum[6][4] : p0_sum[6][5];
            p_0_init_matrix_constructed[6 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[6][6]) > $signed(p0_sum[6][7])) ? p0_sum[6][6] : p0_sum[6][7];
            p_0_init_matrix_constructed[6 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[6][12]) > $signed(p0_sum[6][13])) ? p0_sum[6][12] : p0_sum[6][13];
            p_0_init_matrix_constructed[6 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[6][14]) > $signed(p0_sum[6][15])) ? p0_sum[6][14] : p0_sum[6][15];
            p_0_init_matrix_constructed[6 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[6][0]) > $signed(p0_sum[6][1])) ? p0_sum[6][0] : p0_sum[6][1];
            p_0_init_matrix_constructed[6 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[6][2]) > $signed(p0_sum[6][3])) ? p0_sum[6][2] : p0_sum[6][3];

            // i = 7
            p_0_init_matrix_constructed[7 * 128 + 0 * 16 +: 16] <= ($signed(p0_sum[7][8]) > $signed(p0_sum[7][9])) ? p0_sum[7][8] : p0_sum[7][9];
            p_0_init_matrix_constructed[7 * 128 + 1 * 16 +: 16] <= ($signed(p0_sum[7][10]) > $signed(p0_sum[7][11])) ? p0_sum[7][10] : p0_sum[7][11];
            p_0_init_matrix_constructed[7 * 128 + 2 * 16 +: 16] <= ($signed(p0_sum[7][4]) > $signed(p0_sum[7][5])) ? p0_sum[7][4] : p0_sum[7][5];
            p_0_init_matrix_constructed[7 * 128 + 3 * 16 +: 16] <= ($signed(p0_sum[7][6]) > $signed(p0_sum[7][7])) ? p0_sum[7][6] : p0_sum[7][7];
            p_0_init_matrix_constructed[7 * 128 + 4 * 16 +: 16] <= ($signed(p0_sum[7][12]) > $signed(p0_sum[7][13])) ? p0_sum[7][12] : p0_sum[7][13];
            p_0_init_matrix_constructed[7 * 128 + 5 * 16 +: 16] <= ($signed(p0_sum[7][14]) > $signed(p0_sum[7][15])) ? p0_sum[7][14] : p0_sum[7][15];
            p_0_init_matrix_constructed[7 * 128 + 6 * 16 +: 16] <= ($signed(p0_sum[7][0]) > $signed(p0_sum[7][1])) ? p0_sum[7][0] : p0_sum[7][1];
            p_0_init_matrix_constructed[7 * 128 + 7 * 16 +: 16] <= ($signed(p0_sum[7][2]) > $signed(p0_sum[7][3])) ? p0_sum[7][2] : p0_sum[7][3];
        end
    end
    
    // 简单的控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_renew <= 0;
            P_0_beta_updated <= 1024'b0;
            P_1_beta_updated <= 1024'b0;
        end else begin
            if (current_state == DONE) begin
                // 当enable有效时，在下一个时钟上升沿输出计算结果
                P_0_beta_updated <= p_0_init_matrix_constructed;
                P_1_beta_updated <= p_1_init_matrix_constructed;
                done_renew <= 1;  // 计算完成
            end else begin
                // enable无效时，done_renew为0
                done_renew <= 0;
            end
        end
    end
    
endmodule