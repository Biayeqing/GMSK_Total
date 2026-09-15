module FIFO_Q15_Q5_10(
    input wire clk,
    input wire rst_n,
    input wire vld,                      // ������Ч�ź�
    input wire [15:0] data_real,         // ʵ�����ݣ�Q1��14��ʽ
    input wire [15:0] data_imag,         // �鲿���ݣ�Q1��14��ʽ
    // ��������ź�
    output wire [159:0] real_fifo_out,   // ʵ��FIFO�����160λ
    output wire [159:0] imag_fifo_out,   // �鲿FIFO�����160λ
    output wire fifo_data_ready,         // FIFO����׼���ñ�־
    output reg first_complete,
    input wire test_rd_en               // ���Զ�ȡʹ��
    );

    // ״̬����
    parameter IDLE = 2'b00;
    parameter WRITE_FIFO = 2'b01;

    reg [1:0] state, next_state;
    reg [3:0] data_counter;                 // �������ݼ�������0-9
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [15:0] real_data_buffer [0:9];      // ʵ�����ݻ���
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [15:0] imag_data_buffer [0:9];      // �鲿���ݻ���
    reg buffer_full;                        // ����������־
    reg buffer_full_dly;                    // �ӳ�һ�Ļ�������־
    reg write_fifo_real;                    // ʵ��FIFOдʹ��
    reg write_fifo_imag;                    // �鲿FIFOдʹ��
    wire [159:0] real_fifo_in;              // ʵ��FIFO����
    wire [159:0] imag_fifo_in;              // �鲿FIFO����
    reg signed [159:0] real_fifo_in_buffer;
    reg signed [159:0] imag_fifo_in_buffer;
    reg signed [159:0] real_fifo_delay;
    reg signed [159:0] imag_fifo_delay;
    
    integer j;

    // ��������д���߼�
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_counter <= 4'd0;
            buffer_full <= 1'b0;
            buffer_full_dly <= 1'b0;
                        first_complete <= 1'b0;
// ��ʼ������
            for (j = 0; j < 10; j = j + 1) begin
                real_data_buffer[j] <= 16'd0;
                imag_data_buffer[j] <= 16'd0;
            end
        end
        else begin
            buffer_full_dly <= buffer_full;  // �ӳ�һ�Ļ�������־
            
            // Event pulse: one assertion for each newly assembled symbol.
            first_complete <= 1'b0;
            if(vld) begin
                if(data_counter < 4'd9) begin
                    // �洢Q15תQ5.10��ʽ����
//                    real_data_buffer[data_counter] <= {{5{data_real[15]}},data_real[14],data_real[13:4]};
//                    imag_data_buffer[data_counter] <= {{5{data_imag[15]}},data_imag[14],data_imag[13:4]};
                    real_data_buffer[data_counter] <= $signed(data_real) >>> 5;
                    imag_data_buffer[data_counter] <= $signed(data_imag) >>> 5;
//                    real_data_buffer[data_counter] <= $signed(data_real);
//                    imag_data_buffer[data_counter] <= $signed(data_imag);
                    data_counter <= data_counter + 4'd1;
                    buffer_full <= 1'b0;
                end
                else begin
                    // ��10�����ݵ���
                    real_data_buffer[data_counter] <= $signed(data_real) >>> 5;
                    imag_data_buffer[data_counter] <= $signed(data_imag) >>> 5;
//                    real_data_buffer[data_counter] <= $signed(data_real);
//                    imag_data_buffer[data_counter] <= $signed(data_imag);
                    data_counter <= 4'd0;
                    buffer_full <= 1'b1;         // ���û�������־
                    first_complete <= 1'b1;
                end
            end
            else begin
                buffer_full <= 1'b0;
            end
        end
    end

    // ƴ��160λ����
    assign real_fifo_in = {real_data_buffer[9], real_data_buffer[8], real_data_buffer[7], 
                          real_data_buffer[6], real_data_buffer[5], real_data_buffer[4],
                          real_data_buffer[3], real_data_buffer[2], real_data_buffer[1],
                          real_data_buffer[0]};
                          
    assign imag_fifo_in = {imag_data_buffer[9], imag_data_buffer[8], imag_data_buffer[7], 
                          imag_data_buffer[6], imag_data_buffer[5], imag_data_buffer[4],
                          imag_data_buffer[3], imag_data_buffer[2], imag_data_buffer[1], 
                          imag_data_buffer[0]};

    // FIFO����״̬��
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        if(!rst_n) begin
            imag_fifo_in_buffer <= 160'd0;
            real_fifo_in_buffer <= 160'd0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(buffer_full) begin
                        next_state <= WRITE_FIFO;
                        imag_fifo_in_buffer <= imag_fifo_in;
                        real_fifo_in_buffer <= real_fifo_in;
                    end
                    else begin
                        next_state <= IDLE;
                    end
                end
                WRITE_FIFO: begin
                    next_state <= IDLE;
                end
                default: next_state <= IDLE;
            endcase
        end
    end

    // дʹ������
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            write_fifo_real <= 1'b0;
            write_fifo_imag <= 1'b0;
        end
        else begin
            if(state == WRITE_FIFO) begin
                write_fifo_real <= 1'b1;
                write_fifo_imag <= 1'b1;
            end
            else begin
                write_fifo_real <= 1'b0;
                write_fifo_imag <= 1'b0;
            end
        end
    end

    // ���FIFO���Ƿ������ݣ���ӿ��źż�⣩
    wire fifo_real_empty;
    wire fifo_imag_empty;
    assign fifo_data_ready = !fifo_real_empty && !fifo_imag_empty;

    // ʵ��FIFO�����1024��λ��160
    fifo_generator_0 FIFO_REAL (
        .clk          (clk),                    // input wire clk
        .srst         (!rst_n),                 // input wire srst������Ч��λ
        .din          (real_fifo_in_buffer),           // input wire [159:0] din
        .wr_en        (write_fifo_real),        // input wire wr_en
        .rd_en        (test_rd_en),             // input wire rd_en����Ϊ�ɿ���
        .dout         (real_fifo_out),          // output wire [159:0] dout
        .full         (),                       // output wire full
        .empty        (fifo_real_empty)         // output wire empty
    );

    // �鲿FIFO�����1024��λ��160
    fifo_generator_0 FIFO_IMAG (
        .clk          (clk),                    // input wire clk
        .srst         (!rst_n),                 // input wire srst������Ч��λ
        .din          (imag_fifo_in_buffer),           // input wire [159:0] din
        .wr_en        (write_fifo_imag),        // input wire wr_en
        .rd_en        (test_rd_en),             // input wire rd_en����Ϊ�ɿ���
        .dout         (imag_fifo_out),          // output wire [159:0] dout
        .full         (),                       // output wire full
        .empty        (fifo_imag_empty)         // output wire empty
    );

endmodule
