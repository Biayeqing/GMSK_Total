`timescale 1ns / 1ps

module top_GMSK(
    // ʱ���븴λ
    input               clk_100M,     // 100MHz ��ʱ��
    input               rst,          // ͬ����λ������Ч
    input               rst_dds,      // DDS ģ�鸴λ�ź�
    
    // ��������ӿ�
    input               data_in,      // ���������
    input               bit_valid,    // ������Ч�ź�
    
    // ��������
    input [23:0]        init_phs_in,  // ��ʼ��λֵ
    
    // ϵͳ���
    output wire signed [15:0] softOut,    // ���о����
    output wire calc_done,                // ������ɱ�־
    output wire llr_calc_done,            // LLR ������ɱ�־
    output wire signed [15:0] softOut_legacy,
    output wire calc_done_legacy,
    output wire llr_calc_done_legacy,
    output wire signed [15:0] softOut_fir,
    output wire calc_done_fir,
    output wire llr_calc_done_fir,
    output [15:0] dout_I,                 // ������I·ֱ������������ã�
    output [15:0] dout_Q,                 // ������Q·ֱ������������ã�
    output dout_vd                        // �����������Ч�ź�
);

    // �ڲ��ź�����
    wire gmsk_dout_vd;                 // GMSK�����������Ч
    wire signed [15:0] gmsk_dout_I;    // GMSK������I·���
    wire signed [15:0] gmsk_dout_Q;    // GMSK������Q·���
    
    wire [15:0] rx_lowpass_out_I;      // I·��ͨ�˲����
    wire [15:0] rx_lowpass_out_Q;      // Q·��ͨ�˲����
    wire rx_lowpass_out_vd_I;          // I·�˲������Ч
    wire rx_lowpass_out_vd_Q;          // Q·�˲������Ч
    
    wire [15:0] downsample_out_I;      // I·10���²������
    wire downsample_out_vd_I;          // I·�²��������Ч
    wire [15:0] downsample_out_Q;      // Q·10���²������
    wire downsample_out_vd_Q;          // Q·�²��������Ч
    wire signed [15:0] fir_downsample_out_I;
    wire signed [15:0] fir_downsample_out_Q;
    wire               fir_downsample_out_vd_I;
    wire               fir_downsample_out_vd_Q;
    wire signed [15:0] polyfir_I;
    wire signed [15:0] polyfir_Q;
    wire               polyfir_vld;
    wire [15:0] map_out_1;
    wire        map_valid_1;
    wire [23:0] inst_phs_out_1;
    wire        inst_phs_vd_1;
    wire [23:0] data_sample_100M_1;
    wire        data_sample_vld_100M_1;
    wire [23:0] data_lp_out_1;
    wire        data_lp_vld_1;

    // synthesis translate_off
    integer data_lp_out_1_file;
    initial begin
        data_lp_out_1_file = $fopen("data_lp_out_1.txt", "w");
        if (data_lp_out_1_file == 0) begin
            $display("ERROR: failed to open data_lp_out_1.txt");
        end
    end

    always @(posedge clk_100M) begin
        if (!rst && data_lp_vld_1 && data_lp_out_1_file != 0) begin
            $fwrite(data_lp_out_1_file, "%d\n", $signed(data_lp_out_1));
        end
    end
    // synthesis translate_on
    // --------------------------------------------------------------------
    // GMSK������ʵ��
    // --------------------------------------------------------------------
    gmsk_modulator_top u_gmsk_modulator (
        .clk_100M     (clk_100M),     // 100MHzʱ��
        .rst          (rst),          // ͬ����λ
        .rst_dds      (rst_dds),      // DDS��λ
        
        .data_in      (data_in),      // ���������
        .bit_valid    (bit_valid),    // ������Ч�ź�
        
        .init_phs_in  (24'h2093E0),  // ��ʼ��λ
        
        .dout_vd      (gmsk_dout_vd), // ���������Ч
        .dout_I       (gmsk_dout_I),  // I·�������
        .dout_Q       (gmsk_dout_Q),   // Q·�������
        // �������
        .map_out_1(map_out_1),    // ����ӳ��ģ�����
        .map_valid_1(map_valid_1), // ����ӳ����Ч��־
        .inst_phs_out_1(inst_phs_out_1), // ���ո�˹�˲������
        .inst_phs_vd_1(inst_phs_vd_1),   // ���ո�˹�˲�����Ч��־
        .data_sample_100M_1(data_sample_100M_1), // �����ϲ������
        .data_sample_vld_100M_1(data_sample_vld_100M_1), // �����ϲ�����Ч��־
        .data_lp_out_1(data_lp_out_1),   // ���յ�ͨ�˲������
        .data_lp_vld_1(data_lp_vld_1)    // ���յ�ͨ�˲�����Ч��־
    );

    // --------------------------------------------------------------------
    //-------------------------------------------------------------------------filter-1
    // --------------------------------------------------------------------
    rx_lowpass_filter u_rx_lowpass_filter_I (
        .clk      (clk_100M),            // 100MHzʱ��
        .rst      (rst),                 // ��λ
        .data_in  (gmsk_dout_I),
        .din_vd   (gmsk_dout_vd),
        .data_out (rx_lowpass_out_I),    // �˲������
        .dout_vd  (rx_lowpass_out_vd_I)  // �����Ч�ź�
    );

    // --------------------------------------------------------------------
    // Q·��ͨ�˲��������ն��˲���
    // --------------------------------------------------------------------
    rx_lowpass_filter u_rx_lowpass_filter_Q (
        .clk      (clk_100M),            // 100MHzʱ��
        .rst      (rst),                 // ��λ
        .data_in  (gmsk_dout_Q),
        .din_vd   (gmsk_dout_vd),
        .data_out (rx_lowpass_out_Q),    // �˲������
        .dout_vd  (rx_lowpass_out_vd_Q)  // �����Ч�ź�
    );

    // --------------------------------------------------------------------
    // I·10���²���ģ��
    // --------------------------------------------------------------------
    downsample_10x u_downsample_10x_I (
        .clk             (clk_100M),              // ����ʱ��
        .rst_n           (~rst),                  // ����Ч�첽��λ
        .data_in         (rx_lowpass_out_I),      // ����16λ����
        .data_valid      (rx_lowpass_out_vd_I),   // ����������Ч��־
        .data_out        (downsample_out_I),      // ����²�������
        .data_out_valid  (downsample_out_vd_I)    // ���������Ч��־
    );

    // --------------------------------------------------------------------
    // Q·10���²���ģ��
    // --------------------------------------------------------------------
    downsample_10x u_downsample_10x_Q (
        .clk             (clk_100M),              // ����ʱ��
        .rst_n           (~rst),                  // ����Ч�첽��λ
        .data_in         (rx_lowpass_out_Q),      // ����16λ����
        .data_valid      (rx_lowpass_out_vd_Q),   // ����������Ч��־
        .data_out        (downsample_out_Q),      // ����²�������
        .data_out_valid  (downsample_out_vd_Q)    // ���������Ч��־
    );

    //-------------------------------------------------------------------------filter-2
    //FIR低通滤波，下采样十倍
        fir_ds10_polyphase u_fir_ds10_polyphase_I (
            .sys_clk        (clk_100M),
            .reset_x        (~rst),
            .sys_clk_en     (gmsk_dout_vd   ),
            .i_adc_data     (gmsk_dout_I >>> 4   ),
            .ce_out         (fir_downsample_out_vd_I),
            .o_fir_data     (fir_downsample_out_I)
        );

        fir_ds10_polyphase u_fir_ds10_polyphase_Q (
            .sys_clk        (clk_100M),
            .reset_x        (~rst),
            .sys_clk_en     (gmsk_dout_vd ),
            .i_adc_data     (gmsk_dout_Q  >>> 4 ),
            .ce_out         (fir_downsample_out_vd_Q),
            .o_fir_data     (fir_downsample_out_Q)
        );

    // //第二级FIR滤波器
    //     fir_ds10_onephase u_fir_ds10_onephase_I (
    //         .sys_clk        (clk_100M),
    //         .reset_x        (~rst),
    //         .sys_clk_en     (gmsk_dout_vd),
    //         .i_data         (polyfir_I),
    //         .i_data_vld     (polyfir_vld),
    //         .ce_out         (),
    //         .o_data         (fir_downsample_out_I),
    //         .o_data_vld     (fir_downsample_out_vd_I)
    //     );

    //     fir_ds10_onephase u_fir_ds10_onephase_Q (
    //         .sys_clk        (clk_100M),
    //         .reset_x        (~rst),
    //         .sys_clk_en     (gmsk_dout_vd),
    //         .i_data         (polyfir_Q),
    //         .i_data_vld     (polyfir_vld),
    //         .ce_out         (),
    //         .o_data         (fir_downsample_out_Q),
    //         .o_data_vld     (fir_downsample_out_vd_Q)
    //     );


    // --------------------------------------------------------------------
    // Legacy rx_lowpass_filter + downsample_10x LLR system
    // --------------------------------------------------------------------
    top_integrated_system u_top_llr_legacy (
        .clk             (clk_100M),              // ϵͳʱ��
        .rst_n           (~rst),                  // ����Ч�첽��λ
        
        .vld             (downsample_out_vd_I),
        .data_real       (downsample_out_I),
        .data_imag       (downsample_out_Q),
        .Lc              (16'd2),                 // �ŵ�Lcֵ���̶�Ϊ2
        
        .softOut         (softOut_legacy),        // ���о����
        .calc_done       (calc_done_legacy),      // ������ɱ�־
        .llr_calc_done   (llr_calc_done_legacy)   // LLR������ɱ�־
    );

    // --------------------------------------------------------------------
    // New fir_ds10_polyphase + fir_ds10_onephase LLR system
    // --------------------------------------------------------------------
    top_integrated_system u_top_llr_fir (
        .clk             (clk_100M),
        .rst_n           (~rst),
        
        .vld             (fir_downsample_out_vd_I),
        .data_real       (fir_downsample_out_I),
        .data_imag       (fir_downsample_out_Q),
        .Lc              (16'd2),
        
        .softOut         (softOut_fir),
        .calc_done       (calc_done_fir),
        .llr_calc_done   (llr_calc_done_fir)
    );

    // --------------------------------------------------------------------
    // ֱ��������ӣ����ڵ��Ի��ⲿ��⣩
    // --------------------------------------------------------------------
    assign dout_vd = gmsk_dout_vd;     // ֱ���������������Ч�ź�
    assign dout_I  = gmsk_dout_I;      // ֱ�������������I·����
    assign dout_Q  = gmsk_dout_Q;      // ֱ�������������Q·����
    assign softOut = softOut_legacy;
    assign calc_done = calc_done_legacy;
    assign llr_calc_done = llr_calc_done_legacy;

endmodule
