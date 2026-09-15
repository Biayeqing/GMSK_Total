`timescale 1ns / 1ps
module gamma_alpha_calculate_top #(
    parameter DATA_WIDTH     = 16,      // 数据位宽
    parameter M              = 2,       // 输入符号数
    parameter NUM_STATES     = 8,       // 状态数
    parameter SPS            = 10,      // 每符号采样点数
    parameter NUM_SAMPLES    = 160      // 总采样点数
)(
    input wire clk,
    input wire rst_n,
    input wire start_calc,
    
    // 输入信号
    input wire signed [159:0] y_re,    // sps=10，DATA_WIDTH=16
    input wire signed [159:0] y_im,    // sps=10，DATA_WIDTH=16
    input wire signed [15:0] Lc,       // DATA_WIDTH
    input wire signed [127:0] alpha, // NUM_STATES*DATA_WIDTH
    
    // 分支度量输出
    output wire signed [255:0] gamma,    
    // 最大值模块输出
    output wire signed [127:0] new_data,
    output wire max_done
);
    
    // ================================================
    // 内部连线
    // ================================================
    wire signed [127:0] gamma_input_0_int;
    wire signed [127:0] gamma_input_1_int;
    wire signed [255:0] gamma_int;
    wire branch_calc_done;
    
    reg branch_calc_done_d1;  // 延迟1拍，用于触发最大值计算
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg start_max_calc;       // 启动最大值计算标志
    reg signed [127:0] gamma_input_0_buf;  // 缓冲gamma_input_0
    reg signed [127:0] gamma_input_1_buf;  // 缓冲gamma_input_1
    
    // ================================================
    // 分支度量计算模块实例化
    // ================================================
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [159:0] y_re_keep;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [159:0] y_im_keep;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg start_calc_keep;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg max_done_keep;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [255:0] gamma_int_keep;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [127:0] new_data_keep;
    always@(posedge clk) begin
        if (!rst_n) begin
            y_re_keep <= 160'd0;
            y_im_keep <= 160'd0;
            start_calc_keep <= 0;
            max_done_keep <= 0;
            gamma_int_keep <= 256'd0;
            new_data_keep <= 128'd0;
        end
        else begin
            y_re_keep <= y_re;
            y_im_keep <= y_im;
            start_calc_keep <= start_calc;
            max_done_keep <= max_done;
            gamma_int_keep <= gamma_int;
            new_data_keep <= new_data;
        end
    end
    
    gamma_calculate #(
        .DATA_WIDTH   (DATA_WIDTH),
        .M            (M),
        .NUM_STATES   (NUM_STATES),
        .SPS          (SPS),
        .NUM_SAMPLES  (NUM_SAMPLES)
    ) u_gamma_calculate (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_calc     (start_calc),
        
        // 输入信号
        .y_re           (y_re),
        .y_im           (y_im),
        .Lc             (Lc),
        .alpha_2        (alpha),
        
        // 输出结果
        .gamma_input_0  (gamma_input_0_int),
        .gamma_input_1  (gamma_input_1_int),
        .gamma          (gamma_int),
        .calc_done      (branch_calc_done)
    );
    
    // ================================================
    // 控制逻辑：在分支度量计算完成后启动最大值计算
    // ================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_max_calc <= 1'b0;
            gamma_input_0_buf <= 128'b0;
            gamma_input_1_buf <= 128'b0;
        end else begin
            
            // 在branch_calc_done上升沿时捕获数据并启动最大值计算
            if (branch_calc_done) begin
                // 缓存gamma_input_0和gamma_input_1
                gamma_input_0_buf <= gamma_input_0_int;
                gamma_input_1_buf <= gamma_input_1_int;
                // 启动最大值计算
                start_max_calc <= 1'b1;
            end else if (start_max_calc) begin
                // 只启动一个周期
                start_max_calc <= 1'b0;
            end
        end
    end
    
    // ================================================
    // 最大值计算模块实例化
    // ================================================
    alpha_calculate u_alpha_calculate (
        .clk           (clk),
        .rst_n         (rst_n),
        .start_max_calc (start_max_calc),
        .gamma_input_0 (gamma_input_0_buf),  // 使用缓冲的数据
        .gamma_input_1 (gamma_input_1_buf),  // 使用缓冲的数据
        .new_data      (new_data),
        .done          (max_done)
    );
    
    // ================================================
    // 输出分配
    // ================================================
    assign gamma = gamma_int;
//    assign gamma_input_0 = gamma_input_0_int;
//    assign gamma_input_1 = gamma_input_1_int;
    
endmodule