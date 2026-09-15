`timescale 1ns/1ps

module tb_gmsk_top();

// 时钟和复�?

reg clk_100M = 0;
reg rst = 1;
reg rst_dds = 1;
reg bit_valid=0;
reg bit_valid_delay=0;
reg data_men [5560:0];
reg [12:0] i=0;
reg [6:0] cycle_counter = 0; 


// GMSK输入
// reg [23:0] init_phs_in = 24'h5A2F6C;
// reg [23:0] init_phs_in = 24'h0;
reg [23:0] init_phs_in = 24'h2093E0;

reg data_in=0;
// reg data_valid;
wire              dout_vd;       // 输出数据有效
wire [15:0]       dout_I;         // I路输�?
wire [15:0]       dout_Q;         // Q路输�?
wire signed [15:0] softOut;
wire calc_done;
wire llr_calc_done;


 //100MHZ
    always #1 clk_100M = ~clk_100M;

// 文件操作变量
integer bit_count = 0;
// integer cycle_count = 0;

//initial begin
//    // �����Ҫ���ļ���ȡ
//    // $readmemb("C:/Users/Administrator/Desktop/msk_original.txt", data_men);
//end 

//initial begin
//    data_men = {1'b1, 1390{4'b1010}};  // 1 + 1390��4 = 5561 λ��λ��ƥ��
//end
genvar k;
generate
    for (k = 0; k < 5561; k = k + 2) begin : init_data_men
        initial begin
            data_men[k] = 1'b1;  // ��ʼ��Ϊ0
            data_men[k+1] = 1'b1;  // ��ʼ��Ϊ0
            
        end
    end
endgenerate


// �?100拍产生一个bit_valid脉冲
always @(posedge clk_100M) begin
    if (rst) begin
        cycle_counter <= 0;
        bit_valid <= 0;
    end else begin
        if (cycle_counter == 7'd99) begin
            cycle_counter <= 0;
            bit_valid <= 1;  // �?100拍时拉高
        end else begin
            cycle_counter <= cycle_counter + 1;
            bit_valid <= 0;  // 其他拍为�?
        end
    end
end

// 在bit_valid有效时更新数�?
always @(posedge clk_100M) begin
    if (rst) begin
        i <= 0;
        data_in <= 0;
    end else begin
        if (bit_valid) begin
            if (i < 5560) begin
                data_in <= data_men[i];  // 读取当前数据
                i <= i + 1;
                
            end
        end
    end
end



initial begin
    #1000 rst = 0;
        #30 rst_dds=0;
        //  bit_valid=1;

          #2000000;  // 运行2ms
    
    $finish;
end

always@(posedge clk_100M or posedge rst) begin
    if(rst)
    begin
        bit_valid_delay<=0;
    end
    else begin
        bit_valid_delay<=bit_valid;
    end
end

// 实例化被测试模块
 top_GMSK u_top_GMSK (
    // 时钟和复�?
    .clk_100M      (clk_100M),      // 100MHz时钟
    .rst           (rst),           // 同步复位
    .rst_dds       (rst_dds),       // DDS复位
    
    // 数据输入
    .data_in       (data_in),       // 输入二进制比�?
    .bit_valid     (bit_valid_delay),     // 输入比特有效
    
    // 控制输入
    .init_phs_in   (init_phs_in),   // 初始相位(24�?)
    
    // 输出信号
    .softOut       (softOut),
    .calc_done     (calc_done),
    .llr_calc_done (llr_calc_done),
    .dout_vd       (dout_vd),       // 输出数据有效
    .dout_I        (dout_I),        // I路输�?(16位有符号)
    .dout_Q        (dout_Q)         // Q路输�?(16位有符号)
);

endmodule