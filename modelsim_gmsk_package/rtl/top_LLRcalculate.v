`timescale 1ns / 1ps

// LLR���㶥��ģ�飨��FIFO�������룩
module top_LLRcalculate_with_FIFO #(
    parameter DATA_WIDTH     = 16,
    parameter NUM_STATES     = 8,
    parameter tbDepth        = 2,
    parameter LOG_MIN        = -32768
)(
    input wire clk,
    input wire rst_n,
    input wire start_llr_cal,
    
    // ��FIFOģ����������
    (* KEEP = "{TRUE|FALSE |SOFT}"*) input wire [159:0] real_fifo_out,
    (* KEEP = "{TRUE|FALSE |SOFT}"*) input wire [159:0] imag_fifo_out,
    input wire fifo_data_ready,
    
    // �����ź�
    input wire signed [15:0] Lc, 
    
    // ����ź�
    output wire signed [DATA_WIDTH-1:0] softOut,
    output reg calc_done,
    output wire llr_calc_done,
    
    // FIFO�����ź�
    output reg fifo_rd_en
);

    // �ڲ�����
    localparam M = 2;                    // ���������
    localparam SPS = 10;                // ÿ���Ų�������
    localparam NUM_SAMPLES = 160;       // �ܲ�������
    
    // �ڲ��Ĵ���
    reg signed [127:0] alpha [0:tbDepth+1];
    reg signed [255:0] gamma [0:tbDepth+1];
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [255:0] gamma_0;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [255:0] gamma_1;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [255:0] gamma_2;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [255:0] gamma_3;
    
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [127:0] beta_reg;          // betaֵ
    reg signed [31:0] symbInd = -1;
    reg [1:0] gInd;
    reg signed [127:0] temp_alpha;
   (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg signed [159:0] y_re_reg;          // �洢��ǰ���ŵ�ʵ������
   (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg signed [159:0] y_im_reg;          // �洢��ǰ���ŵ��鲿����
    reg [2:0] fifo_read_state;           // FIFO��ȡ״̬
    // �����ź�
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg start_gamma_calc = 0;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg start_beta_calc = 0;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg start_llr_calc = 0;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg data_latched;               // ���������־
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg wait_for_fifo = 0;              // �ȴ�FIFO���ݱ�־
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg calculation_in_progress = 0;    // ��������б�־
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire [1:0] gamma_llr_input;
    // ģ��������ź�
    wire signed [127:0] new_alpha;      // ��alphaֵ
    wire signed [255:0] new_gamma;      // ��gammaֵ
    wire signed [127:0] beta_out;       // �µ�beta���
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire Alpha_cal_done;                // Alpha�������
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire beta_calc_done;                // Beta�������
   (* KEEP = "{TRUE|FALSE |SOFT}"*)  reg signed [159:0] middle_top_llr_re, middle_top_llr_im;
    // FIFO��ȡ״̬����
    localparam [2:0] 
        FIFO_BEFORE    = 3'd0,
        FIFO_IDLE      = 3'd1,
        FIFO_WAIT      = 3'd2,  // �ȴ�FIFO����׼����
        FIFO_REQUEST   = 3'd3,  // �����ȡFIFO
        FIFO_READ      = 3'd4,  // ��ȡFIFO����
        FIFO_LATCH     = 3'd5;  // ����FIFO����
    
    // ״̬��
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [3:0] state = 0;
    localparam [3:0] 
        IDLE            = 4'd0,
        CHECK_FIFO      = 4'd1,  // ���FIFO״̬
        LATCH_DATA      = 4'd2,  // ��������
        CALC_GAMMA      = 4'd3,
        WAIT_GAMMA      = 4'd4,
        CALC_BETA       = 4'd5,
        WAIT_BETA       = 4'd6,
        CALC_LLR        = 4'd7,
        WAIT_LLR        = 4'd8,
        UPDATE          = 4'd9;
    always@(posedge clk) begin
        if (!rst_n) begin
            gamma_0 <= 256'd0;
            gamma_1 <= 256'd0;
            gamma_2 <= 256'd0;
            gamma_3 <= gamma[3];
        end
        else begin
            gamma_0 <= gamma[0];
            gamma_1 <= gamma[1];
            gamma_2 <= gamma[2];
            gamma_3 <= 256'd0;
        end
    end
    // FIFO��ȡ�����߼�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_rd_en <= 1'b0;
            fifo_read_state <= FIFO_IDLE;
            y_re_reg <= 160'd0;
            y_im_reg <= 160'd0;
            data_latched <= 1'b0;
            calculation_in_progress <= 1'b0;
        end else begin
            case (fifo_read_state)
                FIFO_BEFORE:begin
//                    middle_top_llr_re <= real_fifo_out;
//                    middle_top_llr_im <= imag_fifo_out;
                    data_latched <= 1'b0;
                    if(calculation_in_progress) begin
                        if(state == UPDATE) begin
                            // ������ɽ׶ξ������������б�־�������ȡ��һ������
                            calculation_in_progress <= 1'b0;
                            fifo_read_state <= FIFO_IDLE;
                        end
                    end
                    else begin
                        fifo_read_state <= FIFO_IDLE;// ֻ���ڼ���û�н���ʱ�������ȡFIFO
                    end
                end
                
                FIFO_IDLE: begin
                    if (state == CHECK_FIFO && !calculation_in_progress) begin
                        // ֻ���ڼ���û�н���ʱ�������ȡFIFO
                        fifo_read_state <= FIFO_WAIT;
                        fifo_rd_en <= 1'b0;
                        
                    end
                end
                
                FIFO_WAIT: begin
                    if (fifo_data_ready) begin
                        fifo_read_state <= FIFO_REQUEST;
                        fifo_rd_en <= 1'b1;  // ����������
                    end
                end
                
                FIFO_REQUEST: begin
                    // ����һ�����ڵĶ�ʹ��
                    fifo_rd_en <= 1'b0;
                    fifo_read_state <= FIFO_READ;
                end
                
                FIFO_READ: begin
                    // FIFO����һ��ʱ�������������
                    fifo_read_state <= FIFO_LATCH;
                end
                
                FIFO_LATCH: begin
                    // ����FIFO���������
                    y_re_reg <= $signed(real_fifo_out);
                    y_im_reg <= $signed(imag_fifo_out);
                    data_latched <= 1'b1;
                    calculation_in_progress <= 1'b1;  // ���ü�������б�־
                    fifo_read_state <= FIFO_BEFORE;
                end
                
                default: begin
                    fifo_read_state <= FIFO_BEFORE;
                    fifo_rd_en <= 1'b0;
                end
            endcase
        end
    end
    
    integer i,j;
    
    // ״̬ת���߼�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            gInd <= 0;
            symbInd <= -1;
            start_gamma_calc <= 0;
            start_llr_calc <= 0;
            start_beta_calc <= 0;
            wait_for_fifo <= 0;

            // ��ʼ��alpha����
            for (i = 0; i <= tbDepth+1; i = i + 1) begin
                alpha[i] <= 128'd0;
            end
            
            // ��ʼ��gamma����
            for (j = 0; j <= tbDepth+1; j = j + 1) begin
                gamma[j] <= 256'd0;
            end

            calc_done <= 0;
            temp_alpha <= 128'b0;
        end else begin
            calc_done <= 1'b0;
            case (state)
                IDLE: begin
                    if (start_llr_cal && !calculation_in_progress) begin
                        symbInd <= symbInd + 1;
                        state <= CHECK_FIFO;
                        calc_done <= 0;
                    end
                end
                
                CHECK_FIFO: begin
                    // �ȴ�FIFO��ȡ�����߼�������ݶ�ȡ
                    if (data_latched) begin
                        state <= LATCH_DATA;
                    end
                end
                
                LATCH_DATA: begin
                    state <= CALC_GAMMA;
                    start_gamma_calc <= 1;
                end
                
                CALC_GAMMA: begin
                    start_gamma_calc <= 0;
                    state <= WAIT_GAMMA;
                end
                
                WAIT_GAMMA: begin
                    if (Alpha_cal_done) begin
                        // ����gamma����       
                        gamma[gInd] <= new_gamma;
                        temp_alpha <= alpha[tbDepth+1];
                        
                        if (symbInd > 0) begin
                            state <= CALC_BETA;
                            start_beta_calc <= 1;
                        end else begin
                            state <= CALC_LLR;
                        end
                    end
                end
                
                CALC_BETA: begin
                    start_beta_calc <= 0;
                    state <= WAIT_BETA;
                end
                
                WAIT_BETA: begin
                    if (beta_calc_done) begin
                        // ����beta_last
                        beta_reg <= beta_out;
                        state <= CALC_LLR;
                    end
                end
                
                CALC_LLR: begin
                    if (symbInd >= tbDepth) begin
                        start_llr_calc <= 1;
                        state <= WAIT_LLR;
                    end else begin
                        state <= UPDATE;
                    end
                end
                
                WAIT_LLR: begin
                    start_llr_calc <= 0;
                    if (llr_calc_done) begin
                        state <= UPDATE;
                    end
                end
                
                UPDATE: begin
                    // ��������
                    gInd <= gInd + 1'b1;
                    state <= IDLE;
                    calc_done <= 1;

                    
                    // ����alpha����
                    if (symbInd >= 0) begin
                        alpha[0] <= alpha[1];
                        alpha[1] <= alpha[2];
                        alpha[2] <= temp_alpha;
                        alpha[tbDepth+1] <= new_alpha;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Gamma�����Alpha����ģ��ʵ����
    gamma_alpha_calculate_top #(
        .DATA_WIDTH    (DATA_WIDTH),
        .M             (M),
        .NUM_STATES    (NUM_STATES),
        .SPS           (SPS),
        .NUM_SAMPLES   (NUM_SAMPLES)
    ) gamma_alpha_calc (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_calc     (start_gamma_calc),
        
        // �����źţ�ʹ����������ݣ�
        .y_re           (y_re_reg),
        .y_im           (y_im_reg),
        .Lc             (Lc),
        .alpha          (alpha[tbDepth+1]),
        
        // ������
        .gamma          (new_gamma),      // �洢�����Ҳ���Ϊ������
        .new_data       (new_alpha),      // �洢�����Ҳ���Ϊ������
        .max_done       (Alpha_cal_done)
    );
    
    // Beta����ģ��ʵ����
    beta_calculator_top beta_calc (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable           (start_beta_calc),
        .tbDepth          (tbDepth[1:0]),     // �������
        .symbInd          (symbInd[15:0]),
        
        // Gamma����
        .gamma_new_input  (gamma[gInd]),
        // Beta���
        .beta_out         (beta_out),
        // ������ɱ�־
        .calculation_beta_done (beta_calc_done)
    );
    (* KEEP = "{TRUE|FALSE |SOFT}"*) wire [255:0] temp_gamma_llr;
    assign gamma_llr_input = ((gInd + 1) == 4) ? 0 : (gInd + 1);
//    assign temp_gamma_llr = gamma[gamma_llr_input][255:0];
    // LLR����ģ��ʵ����
    llr_calculate #(
        .DATA_WIDTH    (DATA_WIDTH),
        .NUM_STATES    (NUM_STATES),
        .LOG_MIN       (LOG_MIN)
    ) llr_calc (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_calc     (start_llr_calc),
        
        // �����ź�
        .alpha_llr      (alpha[0]),        // ʹ�õ�һ��alpha
        .gamma_llr      (gamma[gamma_llr_input][255:0]),  // ѡ��ǰgInd��Ӧ��gamma
        .beta_last      (beta_reg),        // ��beta����ģ����
        
        // ����ź�
        .softOut        (softOut),         // ��ʱ����
        .calc_done      (llr_calc_done)
    );

endmodule
