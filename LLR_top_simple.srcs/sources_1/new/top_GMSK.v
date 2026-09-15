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
    // I·��ͨ�˲��������ն��˲���
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

    // --------------------------------------------------------------------
    // ���о���LLR��ϵͳ
    // --------------------------------------------------------------------
    top_integrated_system u_top_llr_system (
        .clk             (clk_100M),              // ϵͳʱ��
        .rst_n           (~rst),                  // ����Ч�첽��λ
        
        .vld             (downsample_out_vd_I),
        .data_real       (downsample_out_I),
        .data_imag       (downsample_out_Q),
        .Lc              (16'd2),                 // �ŵ�Lcֵ���̶�Ϊ2
        
        .softOut         (softOut),               // ���о����
        .calc_done       (calc_done),             // ������ɱ�־
        .llr_calc_done   (llr_calc_done)          // LLR������ɱ�־
    );

    // --------------------------------------------------------------------
    // ֱ��������ӣ����ڵ��Ի��ⲿ��⣩
    // --------------------------------------------------------------------
    assign dout_vd = gmsk_dout_vd;     // ֱ���������������Ч�ź�
    assign dout_I  = gmsk_dout_I;      // ֱ�������������I·����
    assign dout_Q  = gmsk_dout_Q;      // ֱ�������������Q·����

endmodule
