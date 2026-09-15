`timescale 1ns/1ps

module tb_framer_gmsk_top();

// 时钟和复位
reg clk_100M = 0;
reg rst_n = 0;
reg rst_dds = 1;
reg framer_en = 0;
reg data_men[5560:0];
reg [12:0] i=0;

// 组帧输入
wire [15:0] i_businfo_i;
reg  [15:0] i_businfo_q = 16'd0;
reg i_businfo_vld = 1'b0;
// reg [47:0] i_prng_key = 48'd0;
reg [4:0] i_hoprate_data = 5'd0;
reg i_hoprate_vld = 1'b0;
reg [1:0] i_businfo_rate = 2'd0;
reg i_businfo_rate_vld = 1'b0;
reg [1:0] i_businfo_modu = 2'd0;
reg i_businfo_modu_vld = 1'b0;

// GMSK输入
// reg [23:0] init_phs_in = 24'h5A2F6C;
reg [23:0] init_phs_in = 'h0;
reg bit_in=0;
// reg data_valid;
wire              dout_vd;       // 输出数据有效
wire [15:0]       dout_I;         // I路输出
wire [15:0]       dout_Q;         // Q路输出
wire [23:0]       t_inst_phs;      // 瞬时相位输出
wire              o_businfo_req;
wire              framer_out; 
wire              framer_vld;         


// 时钟生成
 // 1MHz时钟（周期1000ns）
    // always #100 clk_1M = ~clk_1M;
//   // 10MHz时钟（周期100ns）
//     always #10 clk_10M = ~clk_10M;
 //100MHZ
    always #1 clk_100M = ~clk_100M;

// 文件操作变量
integer input_file;
integer dout_I_file,dout_Q_file,phs_file,framer_out_file;
integer bit_count = 0;
// integer cycle_count = 0;

initial begin
    $readmemb("E:/Project/4.GMSK_Modulator_Cosim/gmsk_original.txt",data_men);
end

always @(posedge clk_100M) begin
    if(~rst_n) begin
        i_businfo_vld <= 1'b0;
    end
    else begin
        i_businfo_vld <= o_businfo_req;
    end
end

always@(posedge clk_100M)begin
    if(i_businfo_vld)begin
        if(i < 5560)begin
            i <= i + 1;
        end
        else begin
            i <= 5560;
        end
    end
    else begin
        i <= i;
    end
end


assign i_businfo_i = {15'b0, data_men[i]}; 

initial begin
    #1000 rst_n = 1;
    #30 framer_en = 1;
        rst_dds=0;
        i_hoprate_vld=1;
        i_businfo_rate_vld=1;
        i_businfo_modu_vld=1;
        framer_en = 1;
end



initial begin
       dout_I_file = $fopen("E:/Project/4.GMSK_Modulator_Cosim/gmsk_dout_I.txt", "w");
       dout_Q_file = $fopen("E:/Project/4.GMSK_Modulator_Cosim/gmsk_dout_Q.txt", "w");
       phs_file = $fopen("E:/Project/4.GMSK_Modulator_Cosim/gmsk_phs.txt", "w");
       framer_out_file = $fopen("E:/Project/4.GMSK_Modulator_Cosim/framer_out.txt", "w");
end


always@(posedge clk_100M)begin
    if(framer_vld)begin
        // $fwrite(dout_I_file,"%d\n",dout_I);
        // $fwrite(dout_Q_file,"%d\n",dout_Q);
        // $fwrite(phs_file,"%d\n",t_inst_phs);
        $fwrite(framer_out_file,"%d\n",framer_out);
    end 
end



// 文件写入任务
// task write_output;
//     input [15:0] data_I,data_Q;
//     input [23:0] phs;
//     input valid;
//     if (valid) begin
//         $fwrite(dout_I_file, "%h\n", data_I);
//         $fwrite(dout_Q_file, "%h\n", data_Q);
//         $fwrite(phs_file, "%h\n", phs);

//     end
// endtask

//  always @(posedge clk_100M) begin
//         if (dout_vd) begin
//             write_output(dout_I, dout_Q,t_inst_phs,dout_vd);
//         end
//     end


// 实例化被测试模块
top_GMSK u_top_GMSK (
        .clk_100M            (clk_100M),
        .rst_n               (rst_n),
        .rst_dds             (rst_dds),
        
        // 组帧输入
        .i_businfo_i         (i_businfo_i),
        .i_businfo_q         (i_businfo_q),
        .i_businfo_vld       (i_businfo_vld),
        .framer_en           (framer_en),
        // .i_prng_key          (i_prng_key),
        .i_hoprate_data      (i_hoprate_data),
        .i_hoprate_vld       (i_hoprate_vld),
        .i_businfo_rate      (i_businfo_rate),
        .i_businfo_rate_vld  (i_businfo_rate_vld),
        .i_businfo_modu      (i_businfo_modu),
        .i_businfo_modu_vld  (i_businfo_modu_vld),

        // gmsk输入
        .init_phs_in         (init_phs_in),
        
        // 输出
        .dout_vd             (dout_vd),
        .dout_I              (dout_I),
        .dout_Q              (dout_Q),
        .t_inst_phs          (t_inst_phs),
        .o_businfo_req       (o_businfo_req),
        .framer_out          (framer_out),
        .framer_vld          (framer_vld)
    );

endmodule