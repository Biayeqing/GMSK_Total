`timescale 1ns / 1ps

module tb_top_GMSK_with_data_gen_ber;
    localparam integer PAYLOAD_LEN = 100000;
    localparam integer TIMEOUT_NS  = 120000000;

    reg        clk_100M;
    reg        rst;
    reg        rst_dds;
    reg [23:0] init_phs_in;

    wire signed [15:0] softOut;
    wire               calc_done;
    wire               llr_calc_done;
    wire        [15:0] dout_I;
    wire        [15:0] dout_Q;
    wire               dout_vd;

    integer tx_count;
    integer rx_count;
    integer compared;
    integer error_count;
    integer first_error_index;
    integer idx;
    integer fp_ber;
    integer fp_soft;

    reg tx_bits [0:PAYLOAD_LEN-1];
    reg rx_bits [0:PAYLOAD_LEN-1];

    always #5 clk_100M = ~clk_100M;

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

    // Save payload only. The four zero tail bits flush the traceback window
    // and must not be included in the BER denominator.
    always @(posedge clk_100M) begin
        if (rst) begin
            tx_count = 0;
        end else if (uut.bit_valid_wire && tx_count < PAYLOAD_LEN) begin
            tx_bits[tx_count] = uut.data_in_wire;
            tx_count = tx_count + 1;
        end
    end

    // A new soft decision exists only when llr_calc_done is asserted.
    // softOut = metric(bit=0)-metric(bit=1), so a negative value is bit 1.
    always @(posedge clk_100M) begin
        if (rst) begin
            rx_count = 0;
        end else if (llr_calc_done && rx_count < PAYLOAD_LEN) begin
            rx_bits[rx_count] = ($signed(softOut) < 0);
            if (fp_soft != 0) begin
                $fwrite(
                    fp_soft,
                    "%0d,%0t,%0d,%0d,%0d\n",
                    rx_count,
                    $time,
                    $signed(softOut),
                    ($signed(softOut) < 0),
                    tx_bits[rx_count]
                );
            end
            rx_count = rx_count + 1;
        end
    end

    initial begin
        clk_100M          = 1'b0;
        rst               = 1'b1;
        rst_dds           = 1'b0;
        init_phs_in       = 24'd0;
        tx_count          = 0;
        rx_count          = 0;
        compared          = 0;
        error_count       = 0;
        first_error_index = -1;

        fp_soft = $fopen("gmsk_softout_bits.csv", "w");
        if (fp_soft != 0)
            $fwrite(fp_soft, "rx_index,time_ns,softOut,rx_bit,tx_bit\n");

        #100;
        rst = 1'b0;
        #100;
        rst_dds = 1'b1;
        #20;
        rst_dds = 1'b0;
        init_phs_in = 24'h2093E0;

        #TIMEOUT_NS;

        compared = (tx_count < rx_count) ? tx_count : rx_count;
        for (idx = 0; idx < compared; idx = idx + 1) begin
            if (rx_bits[idx] !== tx_bits[idx]) begin
                error_count = error_count + 1;
                if (first_error_index < 0)
                    first_error_index = idx;
            end
        end

        fp_ber = $fopen("gmsk_ber_report.txt", "w");
        if (fp_ber != 0) begin
            $fwrite(fp_ber, "payload_len=%0d\n", PAYLOAD_LEN);
            $fwrite(fp_ber, "tx_count=%0d\n", tx_count);
            $fwrite(fp_ber, "rx_count=%0d\n", rx_count);
            $fwrite(fp_ber, "compared=%0d\n", compared);
            $fwrite(fp_ber, "error_count=%0d\n", error_count);
            $fwrite(fp_ber, "first_error_index=%0d\n", first_error_index);
            if (compared != 0)
                $fwrite(fp_ber, "ber=%f\n", error_count * 1.0 / compared);
            else
                $fwrite(fp_ber, "ber=NaN\n");
            $fclose(fp_ber);
        end

        if (fp_soft != 0)
            $fclose(fp_soft);

        if ((tx_count == PAYLOAD_LEN) &&
            (rx_count == PAYLOAD_LEN) &&
            (error_count == 0)) begin
            $display(
                "GMSK BER PASS: tx=%0d rx=%0d errors=%0d/%0d BER=0",
                tx_count, rx_count, error_count, compared
            );
        end else begin
            $display(
                "GMSK BER FAIL: tx=%0d rx=%0d errors=%0d/%0d first_error=%0d",
                tx_count, rx_count, error_count, compared, first_error_index
            );
        end

        $finish;
    end
endmodule
