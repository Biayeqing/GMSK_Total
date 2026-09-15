module beta_calculator_top (
    input clk,
    input rst_n,
    input enable,
    input [1:0] tbDepth,           // 回溯深度2
    input signed [15:0] symbInd,   // 符号索引
    input signed [255:0] gamma_new_input, // gamma_new_input,Q10,5
    output reg [127:0] beta_out,        // beta_out[0]
    output reg calculation_beta_done    // 新增：计算完成信号
);

    // 内部参数定义
    parameter NUM_STATES = 8;
    parameter DATA_WIDTH = 16;
    
    // 状态转移表
    parameter [3:0] a_new_0 = 4'd7, a_new_1 = 4'd3, a_new_2 = 4'd1, a_new_3 = 4'd5;
    parameter [3:0] a_new_4 = 4'd3, a_new_5 = 4'd7, a_new_6 = 4'd5, a_new_7 = 4'd1;
    
    parameter [3:0] b_new_0 = 4'd0, b_new_1 = 4'd4, b_new_2 = 4'd6, b_new_3 = 4'd2;
    parameter [3:0] b_new_4 = 4'd4, b_new_5 = 4'd0, b_new_6 = 4'd2, b_new_7 = 4'd6;
    
    // 矩阵存储
    wire [1023:0] P_1_beta_wire_double;
    wire [1023:0] P_0_beta_wire_double;
    wire [1023:0] P_1_beta_wire_single;
    
   (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg [1023:0] P_1_beta_reg;  
   (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg [1023:0] P_0_beta_reg;
    
    // 控制信号
    reg [31:0] count_time = 1;
    reg switch_matrix = 0;
    reg calculation_done = 0;
     (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [255:0] gamma_new_input_keep;
    // 最大值计算
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire [15:0] max0_wire, max1_wire, max2_wire, max3_wire;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire [15:0] max4_wire, max5_wire, max6_wire, max7_wire;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire [15:0] beta_out_col_0_wire, beta_out_col_1_wire, beta_out_col_2_wire, beta_out_col_3_wire;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire [15:0] beta_out_col_4_wire, beta_out_col_5_wire, beta_out_col_6_wire, beta_out_col_7_wire;
    
    // 无穷大表示
    parameter SIGNED_INF = 16'hC000; // -16384 in two's complement
    
    // 控制信号
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg enable_renew_single;
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg enable_renew_both;
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg enable_update_max;
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg enable_update_max_matrix;
    
    // 各模块完成信号
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  wire done_double_renew;           // renew_both_matrix模块完成信号
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  wire done_single_renew;    // renew_single_matrix模块完成信号
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  wire done_update_max;      // update_max模块完成信号
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  wire done_update_max_matrix; // update_max_matrix模块完成信号

    // 状态机状态
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg [3:0] state;
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg [3:0] next_state;
    (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg [3:0] next_state_keep;
    
    parameter IDLE              = 4'd0;
    parameter INIT              = 4'd1;  // 初始化和检查
    parameter CALC_MAT0         = 4'd2;  // 计算和更新矩阵0
    parameter CALC_MAT0_wait    = 4'd3;  // 计算和更新矩阵0
    parameter CALC_MAT1         = 4'd4;  // 计算和更新矩阵1
    parameter CALC_MAT1_wait    = 4'd5;  // 计算和更新矩阵1
    parameter CALC_BETA         = 4'd6;  // 计算beta值
    parameter DONE_STATE        = 4'd7;  // 完成

    // 子状态控制
    reg [1:0] substate_CALC_BETA = 0;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [127:0] beta_out_keep;
    reg renew_complete = 0;  // 矩阵更新完成标志
    always@(posedge clk) begin
        if (!rst_n) begin
            gamma_new_input_keep <= 256'd0;
            beta_out_keep <= 128'd0;
        end
        else begin
            gamma_new_input_keep <= gamma_new_input;
            beta_out_keep <= beta_out;
        end
    end
    
    parameter [1023:0] IDENTITY_MATRIX = {
        // 行7: 位[1023:896] = 128位
        16'h0000, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF,
        // 行6: 位[895:768] = 128位
        SIGNED_INF, 16'h0000, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF,
        // 行5: 位[767:640] = 128位
        SIGNED_INF, SIGNED_INF, 16'h0000, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF,
        // 行4: 位[639:512] = 128位
        SIGNED_INF, SIGNED_INF, SIGNED_INF, 16'h0000, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF,
        // 行3: 位[511:384] = 128位
        SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, 16'h0000, SIGNED_INF, SIGNED_INF, SIGNED_INF,
        // 行2: 位[383:256] = 128位
        SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, 16'h0000, SIGNED_INF, SIGNED_INF,
        // 行1: 位[255:128] = 128位
        SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, 16'h0000, SIGNED_INF,
        // 行0: 位[127:0] = 128位
        SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, SIGNED_INF, 16'h0000
    };
    
    // 主状态机时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            substate_CALC_BETA <= 2'b0;
            count_time <= 1;
            
            // 复位控制信号
            enable_renew_single <= 0;
            enable_renew_both <= 0;
            enable_update_max <= 0;
            enable_update_max_matrix <= 0;
            
            // 复位输出

            calculation_beta_done <= 0;
        end else begin
            state <= next_state;
            case (next_state) 
                IDLE: begin
                    calculation_beta_done <= 0;
                    substate_CALC_BETA <= 0;
                end
                
                INIT: begin

                end
                
                CALC_MAT0: begin
                    enable_renew_single <= 1;
                end
                CALC_MAT0_wait: begin
                    enable_renew_single <= 0;
                end
                
                CALC_MAT1: begin
                    enable_renew_both <= 1;
                end

                CALC_MAT1_wait: begin
                    enable_renew_both <= 0;
                end
                
                CALC_BETA: begin
                    case (substate_CALC_BETA)
                        2'd0: begin
                            enable_update_max <= 1;
                            substate_CALC_BETA <= 2'd1;
                        end
                        2'd1: begin
                            enable_update_max <= 0;
                            if (done_update_max) begin
                                substate_CALC_BETA <= 2'd2;
                            end
                        end
                        2'd2: begin
                            enable_update_max_matrix <= 1;
                            substate_CALC_BETA <= 2'd3;
                        end
                        2'd3: begin
                            enable_update_max_matrix <= 0;
                        end
                    endcase
                end
                
                DONE_STATE: begin
                    calculation_beta_done <= 1;
                    if(state == DONE_STATE)
                        count_time <= count_time + 1;
                end
            endcase
        end
    end
    
    // 下一状态逻辑 - 修正组合逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            next_state <= IDLE;
            next_state_keep <= IDLE;
        end else begin 
            next_state_keep <= state;      
            case (state)
                IDLE: begin
                    if (enable) begin
                        next_state <= INIT;
                    end
                end
                
                INIT: begin
                    // 根据count_time决定下一个状态
                    if (count_time == 1) begin
                        next_state <= CALC_MAT0;
                    end else begin
                        next_state <= CALC_MAT1;
                    end 
                end

                CALC_MAT0: begin
                    next_state <= CALC_MAT0_wait;
                end
                
                CALC_MAT0_wait: begin
                    if (done_single_renew) begin
                        next_state <= CALC_BETA;
                    end
                end

                CALC_MAT1: begin
                    next_state <= CALC_MAT1_wait;
                end

                CALC_MAT1_wait: begin
                    if (done_double_renew) begin
                        next_state <= CALC_BETA;
                    end
                end

                CALC_BETA: begin
                    case (substate_CALC_BETA)
                        2'd3: begin
                            if (done_update_max_matrix) begin
                                next_state <= DONE_STATE;
                            end
                        end
                    endcase
                end
                
                DONE_STATE: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end
    
    // 矩阵存储更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            P_0_beta_reg <= IDENTITY_MATRIX;
            P_1_beta_reg <= IDENTITY_MATRIX;
        end else begin
            // 初始化矩阵
            if(next_state == INIT) begin
                if (count_time == 1) begin
                    P_0_beta_reg <= IDENTITY_MATRIX;
                    P_1_beta_reg <= IDENTITY_MATRIX;
                end else if (count_time[0] == 1) begin
                    P_1_beta_reg <= IDENTITY_MATRIX;
                end else if (count_time[0] == 0) begin
                    P_0_beta_reg <= IDENTITY_MATRIX;
                end
            end
            else if (done_single_renew) begin
                P_1_beta_reg <= P_1_beta_wire_single;
            end 
            else if (done_double_renew) begin
                P_0_beta_reg <= P_0_beta_wire_double;
                P_1_beta_reg <= P_1_beta_wire_double;
            end
        end
    end
    
    // beta输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beta_out <= 128'b0;
        end else if (state == DONE_STATE) begin
            // 更新beta输出
            beta_out[15:0] <= beta_out_col_0_wire;
            beta_out[31:16] <= beta_out_col_1_wire;
            beta_out[47:32] <= beta_out_col_2_wire;
            beta_out[63:48] <= beta_out_col_3_wire;
            beta_out[79:64] <= beta_out_col_4_wire;
            beta_out[95:80] <= beta_out_col_5_wire;
            beta_out[111:96] <= beta_out_col_6_wire;
            beta_out[127:112] <= beta_out_col_7_wire;
        end
    end
    
    // 更新矩阵模块实例化
    renew_single_matrix_module renew_single_matrix_inst(
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_renew_single),
        .gamma_new_0(gamma_new_input[15:0]),
        .gamma_new_1(gamma_new_input[31:16]),
        .gamma_new_2(gamma_new_input[47:32]),
        .gamma_new_3(gamma_new_input[63:48]),
        .gamma_new_4(gamma_new_input[79:64]),
        .gamma_new_5(gamma_new_input[95:80]),
        .gamma_new_6(gamma_new_input[111:96]),
        .gamma_new_7(gamma_new_input[127:112]),
        .gamma_new_8(gamma_new_input[143:128]),
        .gamma_new_9(gamma_new_input[159:144]),
        .gamma_new_10(gamma_new_input[175:160]),
        .gamma_new_11(gamma_new_input[191:176]),
        .gamma_new_12(gamma_new_input[207:192]),
        .gamma_new_13(gamma_new_input[223:208]),
        .gamma_new_14(gamma_new_input[239:224]),
        .gamma_new_15(gamma_new_input[255:240]),
        .P_1_beta(P_1_beta_reg),
        .P_1_beta_updated(P_1_beta_wire_single),
        .done_renew(done_single_renew)
    );
    
    renew_both_matrix_module renew_both_matrix_inst(
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_renew_both),
        .gamma_new_0(gamma_new_input[15:0]),
        .gamma_new_1(gamma_new_input[31:16]),
        .gamma_new_2(gamma_new_input[47:32]),
        .gamma_new_3(gamma_new_input[63:48]),
        .gamma_new_4(gamma_new_input[79:64]),
        .gamma_new_5(gamma_new_input[95:80]),
        .gamma_new_6(gamma_new_input[111:96]),
        .gamma_new_7(gamma_new_input[127:112]),
        .gamma_new_8(gamma_new_input[143:128]),
        .gamma_new_9(gamma_new_input[159:144]),
        .gamma_new_10(gamma_new_input[175:160]),
        .gamma_new_11(gamma_new_input[191:176]),
        .gamma_new_12(gamma_new_input[207:192]),
        .gamma_new_13(gamma_new_input[223:208]),
        .gamma_new_14(gamma_new_input[239:224]),
        .gamma_new_15(gamma_new_input[255:240]),
        .P_0_beta(P_0_beta_reg),
        .P_1_beta(P_1_beta_reg),
        .P_0_beta_updated(P_0_beta_wire_double),
        .P_1_beta_updated(P_1_beta_wire_double),
        .done_renew(done_double_renew)
    );
    
    // 更新最大值模块实例化
    update_max_module update_max_inst(
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_update_max), 
        .P_1_beta_reg(P_1_beta_reg),
        .P_0_beta_reg(P_0_beta_reg),
        .SWITCH_MATRIX(count_time[0]),
        .max0(max0_wire),
        .max1(max1_wire),
        .max2(max2_wire),
        .max3(max3_wire),
        .max4(max4_wire),
        .max5(max5_wire),
        .max6(max6_wire),
        .max7(max7_wire),
        .done_update_max(done_update_max)
    );
    
    // 更新最大矩阵模块实例
    update_max_matrix_module update_max_matrix_inst(
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_update_max_matrix),
        .max0(max0_wire),
        .max1(max1_wire),
        .max2(max2_wire),
        .max3(max3_wire),
        .max4(max4_wire),
        .max5(max5_wire),
        .max6(max6_wire),
        .max7(max7_wire),
        .sub0(beta_out_col_0_wire),
        .sub1(beta_out_col_1_wire),
        .sub2(beta_out_col_2_wire),
        .sub3(beta_out_col_3_wire),
        .sub4(beta_out_col_4_wire),
        .sub5(beta_out_col_5_wire),
        .sub6(beta_out_col_6_wire),
        .sub7(beta_out_col_7_wire),
        .done_update_max_matrix(done_update_max_matrix)
    );
    
endmodule