 module upsample (
    input               clk,            // 时钟
    input               rst,            // 复位
    
    // 原始二进制输入
    input      [23:0]   bit_in,         // 输入二进制比特
    input               bit_valid,      // 输入比特有效
    
    // 输出
    output reg [23:0]   map_out,        // map输出
    output              map_valid       // 输出有效
);

// 状态定义
parameter IDLE    = 2'b00;//等待数据
parameter ZEROS   = 2'b01;//输出9个0

(* KEEP = "{TRUE|FALSE |SOFT}"*) reg [1:0]   state;          // 当前状态
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg [1:0]   next_state;
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg [3:0]   zero_count;     // 零计数器
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg    map_valid_delay;
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg    map_valid_delay1;          // 当前状态
(* KEEP = "{TRUE|FALSE |SOFT}"*) reg    map_valid_delay2;  
// (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [3:0]   count;         //周期计数器
// (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [15:0]  symbol_value;   // 符号值缓存

// 符号映射值定义
// parameter SYMBOL_0 = 16'hE000;//-1
// parameter SYMBOL_1 = 16'h2000;//+1


always@(posedge clk or posedge rst) begin
    if(rst)
    begin
        map_valid_delay2<=0;
        // fifo_empty_delay2<=1;
    end
       
    else begin
        map_valid_delay2<=map_valid_delay1;
        // fifo_empty_delay2<=fifo_empty_delay;
    end   
end


// 第一段：状态寄存器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        next_state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

// 第二段：状态转移逻辑
always @(*) begin
    case (state)
        IDLE: begin
            if (bit_valid) begin
                next_state = ZEROS;
            end
            else begin
                next_state = IDLE;
            end
        end
        
        ZEROS: begin
            if (zero_count < 4'd8) begin
                next_state = ZEROS;
            end
            else begin
                next_state = IDLE;
            end
        end
        
        default: begin
            next_state = IDLE;
        end
    endcase
end

// 第三段：输出逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        zero_count <= 4'd0;
        map_out <= 24'b0;
        map_valid_delay1 <= 1'b0;
    end
    else begin
        case (state)
            IDLE: begin

                if (bit_valid) begin
                    map_out <= bit_in;
                    map_valid_delay1 <= 1'b1;
                    zero_count <= 4'd0;  // 清零计数器
                end
                else begin
                    map_valid_delay1 <= 1'b0;
                    map_out<=0;
                end
            end
            
            ZEROS: begin
                if (zero_count < 4'd9) begin
                    // 输出0
                    map_out <= 24'b0;
                    map_valid_delay1 <= 1'b1;
                    zero_count <= zero_count + 4'd1;
                end
                else begin
                    // 9个0输出完成
                    map_valid_delay1 <= 1'b0;
                end
            end
            
            default: begin
                map_valid_delay1 <= 1'b0;
            end
        endcase
    end
end

// always@(posedge clk or posedge rst) begin
//     if(rst)
//     begin
//         map_valid_delay<=0;
//         // fifo_empty_delay2<=1;
//     end
//     else begin
//         map_valid_delay <= map_valid_delay1||map_valid_delay2;
//         // fifo_empty_delay2<=fifo_empty_delay;
//     end   
// end

assign map_valid= map_valid_delay1||map_valid_delay2;

endmodule