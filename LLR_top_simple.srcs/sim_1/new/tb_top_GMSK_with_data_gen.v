`timescale 1ns / 1ps

module tb_top_GMSK_with_data_gen;

    // 时钟与复位信号
    reg         clk_100M;
    reg         rst;
    reg         rst_dds;
    reg [23:0]  init_phs_in;
    
    // 输出
    wire signed [15:0] softOut;
    wire               calc_done;
    wire               llr_calc_done;
    wire        [15:0] dout_I;
    wire        [15:0] dout_Q;
    wire               dout_vd;

    // 文件导出
    integer fp_internal;
    integer sample_cnt;
    
    // 生成时钟
    always #5 clk_100M = ~clk_100M;  // 100MHz时钟
    
    // 实例化被测模块
    top_GMSK_with_data_gen uut (
        .clk_100M      (clk_100M),
        .rst           (rst),
        .rst_dds       (rst_dds),
        .init_phs_in   (init_phs_in),
        .softOut       (softOut),
        .calc_done     (calc_done),
        .llr_calc_done (llr_calc_done),
        .dout_I        (dout_I),
        .dout_Q        (dout_Q),
        .dout_vd       (dout_vd)
    );

    // --------------------------------------------------------------------
    // 导出 u_top_gmsk 内部信号数据
    // --------------------------------------------------------------------
    initial begin
        sample_cnt = 0;

        fp_internal = $fopen("gmsk_internal_data.csv", "w");

        if (fp_internal == 0) begin
            $display("文件打开失败！");
            $stop;
        end

        // CSV表头
        $fwrite(fp_internal,
            "cnt,time_ns,"
        );

        $fwrite(fp_internal,
            "map_valid_1,map_out_1,map_out_1_hex,"
        );

        $fwrite(fp_internal,
            "data_lp_vld_1,data_lp_out_1,"
        );

        $fwrite(fp_internal,
            "data_sample_vld_100M_1,data_sample_100M_1,"
        );

        $fwrite(fp_internal,
            "inst_phs_vd_1,inst_phs_out_1,inst_phs_out_1_hex\n"
        );
    end

    always @(posedge clk_100M) begin
        if (!rst && fp_internal != 0) begin

            $fwrite(fp_internal,
                "%0d,%0t,%0d,%0d,%h,%0d,%0d,%0d,%0d,%0d,%0d,%h\n",
                sample_cnt,
                $time,

                // map_out_1 及对应有效信号
                uut.u_top_gmsk.map_valid_1,
                $signed(uut.u_top_gmsk.map_out_1),
                uut.u_top_gmsk.map_out_1,

                // data_lp_out_1 及对应有效信号
                uut.u_top_gmsk.data_lp_vld_1,
                $signed(uut.u_top_gmsk.data_lp_out_1),

                // data_sample_100M_1 及对应有效信号
                uut.u_top_gmsk.data_sample_vld_100M_1,
                $signed(uut.u_top_gmsk.data_sample_100M_1),

                // inst_phs_out_1 及对应有效信号
                uut.u_top_gmsk.inst_phs_vd_1,
                uut.u_top_gmsk.inst_phs_out_1,
                uut.u_top_gmsk.inst_phs_out_1
            );

            sample_cnt = sample_cnt + 1;
        end
    end
    
    // --------------------------------------------------------------------
    // 初始化
    // --------------------------------------------------------------------
    initial begin
        clk_100M    = 0;
        rst         = 1;
        rst_dds     = 0;
        init_phs_in = 24'h0;
        
        // 复位
        #100;
        rst = 0;

        #100;
        rst_dds = 1;

        #20;
        rst_dds = 0;
        
        // 设置初始相位
        init_phs_in = 24'h2093E0;

        // 运行足够长时间
        #1000000;  // 1ms

        $display("仿真完成");

        $fclose(fp_internal);

        $stop;
    end

endmodule