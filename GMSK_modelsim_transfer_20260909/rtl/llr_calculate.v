module llr_calculate #(
    parameter DATA_WIDTH     = 16,
    parameter NUM_STATES     = 8,
    parameter LOG_MIN        = -32768
)(
    input wire clk,
    input wire rst_n,
    input wire start_calc,
    
    // 输入信号
    input wire signed [127:0] alpha_llr,           // 8 * 16=128
    input wire signed [255:0] gamma_llr,     // 当前输出的分支度量
    input wire signed [127:0] beta_last,        // 8 * 16=128
    
    // 输出信号
    output reg signed [DATA_WIDTH-1:0] softOut,
    output reg calc_done
);
    
    // 并行比较树
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [DATA_WIDTH-1:0] prob0_paths [0:NUM_STATES-1];
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire signed [DATA_WIDTH-1:0] prob1_paths [0:NUM_STATES-1];
    reg signed [DATA_WIDTH-1:0] prob0_max_comb;
    reg signed [DATA_WIDTH-1:0] prob1_max_comb;
    
    // 流水线寄存器
    reg signed [DATA_WIDTH-1:0] prob0_max_reg;
    reg signed [DATA_WIDTH-1:0] prob1_max_reg;
    
    // 状态寄存器
    localparam [2:0] IDLE              = 3'b000;
    localparam [2:0] BEFORE            = 3'b001;
    localparam [2:0] INIT              = 3'b010;
    localparam [2:0] CORRELATION       = 3'b011;
    localparam [2:0] ACCUMULATE        = 3'b100;
    localparam [2:0] Comparison        = 3'b101;
    localparam [2:0] DONE              = 3'b110;
    localparam [2:0] DONE_2            = 3'b111;
    
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
            IDLE: next_state = start_calc ? BEFORE : IDLE;
            BEFORE: next_state = INIT;
            INIT: next_state = CORRELATION;
            CORRELATION: next_state = ACCUMULATE;
            ACCUMULATE: next_state = Comparison;
            Comparison: next_state = DONE;
            DONE: next_state = DONE_2;
            DONE_2: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    // 替代原来的 localparam 数组
    function automatic [2:0] getNextState;
        input [3:0] idx; // 输入索引 0～15
        begin
            case (idx)
                0: getNextState = 3'd6;   // 7-1 = 6
                1: getNextState = 3'd7;   // 8-1 = 7
                2: getNextState = 3'd2;   // 3-1 = 2
                3: getNextState = 3'd3;   // 4-1 = 3
                4: getNextState = 3'd0;   // 1-1 = 0
                5: getNextState = 3'd1;   // 2-1 = 1
                6: getNextState = 3'd4;   // 5-1 = 4
                7: getNextState = 3'd5;   // 6-1 = 5
                8: getNextState = 3'd2;   // 3-1 = 2
                9: getNextState = 3'd3;   // 4-1 = 3
                10: getNextState = 3'd6;  // 7-1 = 6
                11: getNextState = 3'd7;  // 8-1 = 7
                12: getNextState = 3'd4;  // 5-1 = 4
                13: getNextState = 3'd5;  // 6-1 = 5
                14: getNextState = 3'd0;  // 1-1 = 0
                15: getNextState = 3'd1;  // 2-1 = 1
                default: getNextState = 3'd0;
            endcase
        end
    endfunction
    
    // 生成并行计算逻辑
    // 状态 0
    reg signed [DATA_WIDTH-1:0] alpha_val_0 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_0;
    reg signed [DATA_WIDTH-1:0] gamma1_int_0;
    reg signed [DATA_WIDTH-1:0] beta0_val_0 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_0 ;
    //状态 1
    reg signed [DATA_WIDTH-1:0] alpha_val_1 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_1;
    reg signed [DATA_WIDTH-1:0] gamma1_int_1;
    reg signed [DATA_WIDTH-1:0] beta0_val_1 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_1 ;
    //状态 2
    reg signed [DATA_WIDTH-1:0] alpha_val_2 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_2;
    reg signed [DATA_WIDTH-1:0] gamma1_int_2;
    reg signed [DATA_WIDTH-1:0] beta0_val_2 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_2 ;
    //状态 3
    reg signed [DATA_WIDTH-1:0] alpha_val_3 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_3;
    reg signed [DATA_WIDTH-1:0] gamma1_int_3;
    reg signed [DATA_WIDTH-1:0] beta0_val_3 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_3 ;
    //状态 4
    reg signed [DATA_WIDTH-1:0] alpha_val_4 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_4;
    reg signed [DATA_WIDTH-1:0] gamma1_int_4;
    reg signed [DATA_WIDTH-1:0] beta0_val_4 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_4 ;
    //状态 5
    reg signed [DATA_WIDTH-1:0] alpha_val_5 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_5;
    reg signed [DATA_WIDTH-1:0] gamma1_int_5;
    reg signed [DATA_WIDTH-1:0] beta0_val_5 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_5 ;
    //状态 6
    reg signed [DATA_WIDTH-1:0] alpha_val_6 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_6;
    reg signed [DATA_WIDTH-1:0] gamma1_int_6;
    reg signed [DATA_WIDTH-1:0] beta0_val_6 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_6 ;
    //状态 7
    reg signed [DATA_WIDTH-1:0] alpha_val_7 ;
    reg signed [DATA_WIDTH-1:0] gamma0_int_7;
    reg signed [DATA_WIDTH-1:0] gamma1_int_7;
    reg signed [DATA_WIDTH-1:0] beta0_val_7 ;
    reg signed [DATA_WIDTH-1:0] beta1_val_7 ;
    
        // 生成并行计算逻辑
    genvar i;
    generate
        for (i = 0; i < NUM_STATES; i = i + 1) begin : PARALLEL_CALC
            // 提取相关值
            wire signed [DATA_WIDTH-1:0] alpha_val = alpha_llr[i*DATA_WIDTH +: DATA_WIDTH];  // 当前alpha位整数格式
            wire signed [DATA_WIDTH-1:0] gamma0_val = gamma_llr[i*2*DATA_WIDTH +: DATA_WIDTH];  // gamma格式为Q11.4结构
            wire signed [DATA_WIDTH-1:0] gamma1_val = gamma_llr[(i*2+1)*DATA_WIDTH +: DATA_WIDTH];
            
            // 提取gamma的整数部分（扩展10个符号位）
            wire signed [DATA_WIDTH-1:0] gamma0_int = $signed(gamma0_val) >>> 4;  // 只取整数部分
            wire signed [DATA_WIDTH-1:0] gamma1_int = $signed(gamma1_val) >>> 4;  // 只取整数部分
            // 提取alpha的整数部分（扩展10个符号位）
            wire signed [DATA_WIDTH-1:0] alpha_int = $signed(alpha_val) >>> 4;  // 只取整数部分
            
            wire signed [DATA_WIDTH-1:0] beta0_val = beta_last[getNextState(i*2)*DATA_WIDTH +: DATA_WIDTH];  // 当前beta为整数
            wire signed [DATA_WIDTH-1:0] beta1_val = beta_last[getNextState(i*2+1)*DATA_WIDTH +: DATA_WIDTH];
            
            // 计算每条路径的度量 - 有符号加法
            assign prob0_paths[i] = $signed(alpha_int) + $signed(gamma0_int) + $signed(beta0_val);  // bit=0
            assign prob1_paths[i] = $signed(alpha_int) + $signed(gamma1_int) + $signed(beta1_val);  // bit=1
        end
    endgenerate

    // 组合逻辑比较树：查找bit=0的最大值
    reg signed [DATA_WIDTH-1:0] level1_0_max [0:3];
    reg signed [DATA_WIDTH-1:0] level2_0_max [0:1];
    // 组合逻辑比较树：查找bit=1的最大值
    reg signed [DATA_WIDTH-1:0] level1_1_max [0:3];
    reg signed [DATA_WIDTH-1:0] level2_1_max [0:1];
    always @(posedge clk) begin
        if (!rst_n) begin
            level1_0_max[0] <= 16'b0;
            level1_0_max[1] <= 16'b0;        
            level1_0_max[2] <= 16'b0;     
            level1_0_max[3] <= 16'b0;

            level1_1_max[0] <= 16'b0;
            level1_1_max[1] <= 16'b0;        
            level1_1_max[2] <= 16'b0;     
            level1_1_max[3] <= 16'b0;
        end else if (current_state == CORRELATION) begin
            // 第一级比较
            level1_0_max[0] <= ($signed(prob0_paths[0]) > $signed(prob0_paths[1])) ? 
                            $signed(prob0_paths[0]) : $signed(prob0_paths[1]);
            level1_0_max[1] <= ($signed(prob0_paths[2]) > $signed(prob0_paths[3])) ? 
                            $signed(prob0_paths[2]) : $signed(prob0_paths[3]);
            level1_0_max[2] <= ($signed(prob0_paths[4]) > $signed(prob0_paths[5])) ? 
                            $signed(prob0_paths[4]) : $signed(prob0_paths[5]);
            level1_0_max[3] <= ($signed(prob0_paths[6]) > $signed(prob0_paths[7])) ? 
                            $signed(prob0_paths[6]) : $signed(prob0_paths[7]);

            level1_1_max[0] <= ($signed(prob1_paths[0]) > $signed(prob1_paths[1])) ? 
                             $signed(prob1_paths[0]) : $signed(prob1_paths[1]);
            level1_1_max[1] <= ($signed(prob1_paths[2]) > $signed(prob1_paths[3])) ? 
                             $signed(prob1_paths[2]) : $signed(prob1_paths[3]);
            level1_1_max[2] <= ($signed(prob1_paths[4]) > $signed(prob1_paths[5])) ? 
                             $signed(prob1_paths[4]) : $signed(prob1_paths[5]);
            level1_1_max[3] <= ($signed(prob1_paths[6]) > $signed(prob1_paths[7])) ? 
                            $signed(prob1_paths[6]) : $signed(prob1_paths[7]);
        end
    end
    always @(posedge clk) begin
        if (!rst_n) begin
            level2_0_max[0] <= 16'b0;
            level2_0_max[1] <= 16'b0;  

            level2_1_max[0] <= 16'b0;
            level2_1_max[1] <= 16'b0;      
        end else if (current_state == ACCUMULATE) begin
            // 第二级比较
            level2_0_max[0] <= ($signed(level1_0_max[0]) > $signed(level1_0_max[1])) ? 
                            $signed(level1_0_max[0]) : $signed(level1_0_max[1]);
            level2_0_max[1] <= ($signed(level1_0_max[2]) > $signed(level1_0_max[3])) ? 
                            $signed(level1_0_max[2]) : $signed(level1_0_max[3]);

            level2_1_max[0] <= ($signed(level1_1_max[0]) > $signed(level1_1_max[1])) ? 
                             $signed(level1_1_max[0]) : $signed(level1_1_max[1]);
            level2_1_max[1] <= ($signed(level1_1_max[2]) > $signed(level1_1_max[3])) ? 
                            $signed(level1_1_max[2]) : $signed(level1_1_max[3]);
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            prob0_max_comb <= 16'b0;     
            prob1_max_comb <= 16'b0; 
        end else if (current_state == Comparison) begin
            // 第三级比较
            prob0_max_comb <= ($signed(level2_0_max[0]) > $signed(level2_0_max[1])) ? 
                           $signed(level2_0_max[0]) : $signed(level2_0_max[1]);
            prob1_max_comb <= ($signed(level2_1_max[0]) > $signed(level2_1_max[1])) ? 
                           $signed(level2_1_max[0]) : $signed(level2_1_max[1]);
        end
    end
    
    // 状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            prob0_max_reg <= 16'b0;
            prob1_max_reg <= 16'b0;
        end
        else if (current_state == DONE) begin
                prob0_max_reg <= prob0_max_comb;
                prob1_max_reg <= prob1_max_comb;
            end
    end
    always @(posedge clk) begin
        if (!rst_n) begin
            // 异步复位
            softOut <= 16'b0;
            calc_done <= 1'b0;
        end
        else if (current_state == DONE_2) begin
            softOut <= 2*($signed(prob0_max_reg) - $signed(prob1_max_reg));
            calc_done <= 1'b1;
        end
        else begin
            calc_done <= 1'b0;
        end
    end

    
endmodule