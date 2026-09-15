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
    wire signed [15:0] softOut_legacy;
    wire               calc_done_legacy;
    wire               llr_calc_done_legacy;
    wire signed [15:0] softOut_fir;
    wire               calc_done_fir;
    wire               llr_calc_done_fir;
    wire        [15:0] dout_I;
    wire        [15:0] dout_Q;
    wire               dout_vd;

    integer tx_count;
    integer rx_count_legacy;
    integer rx_count_fir;
    integer compared_legacy;
    integer compared_fir;
    integer error_count_legacy;
    integer error_count_fir;
    integer first_error_index_legacy;
    integer first_error_index_fir;
    integer idx;
    integer fp_ber_compare;
    integer fp_soft_compare;
    integer report_at_ns;
    reg     report_done;

    reg tx_bits [0:PAYLOAD_LEN-1];
    reg rx_bits_legacy [0:PAYLOAD_LEN-1];
    reg rx_bits_fir [0:PAYLOAD_LEN-1];

    integer last_tx_index;
    integer last_rx_index_legacy;
    integer last_rx_index_fir;
    reg     last_tx_bit;
    reg     last_rx_bit_legacy;
    reg     last_rx_bit_fir;
    reg     last_ref_bit_legacy;
    reg     last_ref_bit_fir;
    reg     legacy_match;
    reg     fir_match;
    reg     legacy_mismatch_pulse;
    reg     fir_mismatch_pulse;
    reg     rx_bit_diff_pulse;
    wire    softout_bit_legacy;
    wire    softout_bit_fir;
    wire    softout_sign_diff;
    wire signed [16:0] softout_diff;
    wire signed [31:0] rx_count_delta;

    assign softout_bit_legacy = ($signed(softOut_legacy) < 0);
    assign softout_bit_fir    = ($signed(softOut_fir) < 0);
    assign softout_sign_diff  = softout_bit_legacy ^ softout_bit_fir;
    assign softout_diff       = $signed({softOut_legacy[15], softOut_legacy}) -
                                $signed({softOut_fir[15], softOut_fir});
    assign rx_count_delta     = rx_count_legacy - rx_count_fir;

    always #5 clk_100M = ~clk_100M;

    top_GMSK_with_data_gen uut (
        .clk_100M             (clk_100M),
        .rst                  (rst),
        .rst_dds              (rst_dds),
        .init_phs_in          (init_phs_in),
        .softOut              (softOut),
        .calc_done            (calc_done),
        .llr_calc_done        (llr_calc_done),
        .softOut_legacy       (softOut_legacy),
        .calc_done_legacy     (calc_done_legacy),
        .llr_calc_done_legacy (llr_calc_done_legacy),
        .softOut_fir          (softOut_fir),
        .calc_done_fir        (calc_done_fir),
        .llr_calc_done_fir    (llr_calc_done_fir),
        .dout_I               (dout_I),
        .dout_Q               (dout_Q),
        .dout_vd              (dout_vd)
    );

    task write_one_report;
        input [1023:0] path;
        input [1023:0] label_name;
        input integer rx_count;
        input integer compared;
        input integer error_count;
        input integer first_error_index;
        integer fp;
    begin
        fp = $fopen(path, "w");
        if (fp != 0) begin
            $fwrite(fp, "filter=%0s\n", label_name);
            $fwrite(fp, "payload_len=%0d\n", PAYLOAD_LEN);
            $fwrite(fp, "sim_time_ps=%0t\n", $time);
            $fwrite(fp, "tx_count=%0d\n", tx_count);
            $fwrite(fp, "rx_count=%0d\n", rx_count);
            $fwrite(fp, "compared=%0d\n", compared);
            $fwrite(fp, "error_count=%0d\n", error_count);
            $fwrite(fp, "first_error_index=%0d\n", first_error_index);
            if (compared != 0)
                $fwrite(fp, "ber=%f\n", error_count * 1.0 / compared);
            else
                $fwrite(fp, "ber=NaN\n");
            $fclose(fp);
        end
    end
    endtask

    task write_ber_report;
    begin
        if (!report_done) begin
            report_done              = 1'b1;
            compared_legacy          = (tx_count < rx_count_legacy) ? tx_count : rx_count_legacy;
            compared_fir             = (tx_count < rx_count_fir) ? tx_count : rx_count_fir;
            error_count_legacy       = 0;
            error_count_fir          = 0;
            first_error_index_legacy = -1;
            first_error_index_fir    = -1;

            for (idx = 0; idx < compared_legacy; idx = idx + 1) begin
                if (rx_bits_legacy[idx] !== tx_bits[idx]) begin
                    error_count_legacy = error_count_legacy + 1;
                    if (first_error_index_legacy < 0)
                        first_error_index_legacy = idx;
                end
            end

            for (idx = 0; idx < compared_fir; idx = idx + 1) begin
                if (rx_bits_fir[idx] !== tx_bits[idx]) begin
                    error_count_fir = error_count_fir + 1;
                    if (first_error_index_fir < 0)
                        first_error_index_fir = idx;
                end
            end

            write_one_report(
                "gmsk_ber_legacy_report.txt",
                "legacy_rx_lowpass_downsample",
                rx_count_legacy,
                compared_legacy,
                error_count_legacy,
                first_error_index_legacy
            );

            write_one_report(
                "gmsk_ber_fir_report.txt",
                "fir_ds10_polyphase_onephase",
                rx_count_fir,
                compared_fir,
                error_count_fir,
                first_error_index_fir
            );

            fp_ber_compare = $fopen("gmsk_ber_compare_report.txt", "w");
            if (fp_ber_compare != 0) begin
                $fwrite(fp_ber_compare, "payload_len=%0d\n", PAYLOAD_LEN);
                $fwrite(fp_ber_compare, "sim_time_ps=%0t\n", $time);
                $fwrite(fp_ber_compare, "\n[legacy_rx_lowpass_downsample]\n");
                $fwrite(fp_ber_compare, "tx_count=%0d\n", tx_count);
                $fwrite(fp_ber_compare, "rx_count=%0d\n", rx_count_legacy);
                $fwrite(fp_ber_compare, "compared=%0d\n", compared_legacy);
                $fwrite(fp_ber_compare, "error_count=%0d\n", error_count_legacy);
                $fwrite(fp_ber_compare, "first_error_index=%0d\n", first_error_index_legacy);
                if (compared_legacy != 0)
                    $fwrite(fp_ber_compare, "ber=%f\n", error_count_legacy * 1.0 / compared_legacy);
                else
                    $fwrite(fp_ber_compare, "ber=NaN\n");

                $fwrite(fp_ber_compare, "\n[fir_ds10_polyphase_onephase]\n");
                $fwrite(fp_ber_compare, "tx_count=%0d\n", tx_count);
                $fwrite(fp_ber_compare, "rx_count=%0d\n", rx_count_fir);
                $fwrite(fp_ber_compare, "compared=%0d\n", compared_fir);
                $fwrite(fp_ber_compare, "error_count=%0d\n", error_count_fir);
                $fwrite(fp_ber_compare, "first_error_index=%0d\n", first_error_index_fir);
                if (compared_fir != 0)
                    $fwrite(fp_ber_compare, "ber=%f\n", error_count_fir * 1.0 / compared_fir);
                else
                    $fwrite(fp_ber_compare, "ber=NaN\n");
                $fclose(fp_ber_compare);
            end

            fp_ber_compare = $fopen("gmsk_ber_report.txt", "w");
            if (fp_ber_compare != 0) begin
                $fwrite(fp_ber_compare, "See gmsk_ber_compare_report.txt for the two-filter BER comparison.\n");
                $fclose(fp_ber_compare);
            end

            if (fp_soft_compare != 0)
                $fclose(fp_soft_compare);

            if (compared_legacy != 0)
                $display(
                    "GMSK BER LEGACY: time=%0t tx=%0d rx=%0d errors=%0d/%0d BER=%f first_error=%0d",
                    $time,
                    tx_count,
                    rx_count_legacy,
                    error_count_legacy,
                    compared_legacy,
                    error_count_legacy * 1.0 / compared_legacy,
                    first_error_index_legacy
                );
            else
                $display("GMSK BER LEGACY: time=%0t tx=%0d rx=%0d compared=0 BER=NaN", $time, tx_count, rx_count_legacy);

            if (compared_fir != 0)
                $display(
                    "GMSK BER FIR: time=%0t tx=%0d rx=%0d errors=%0d/%0d BER=%f first_error=%0d",
                    $time,
                    tx_count,
                    rx_count_fir,
                    error_count_fir,
                    compared_fir,
                    error_count_fir * 1.0 / compared_fir,
                    first_error_index_fir
                );
            else
                $display("GMSK BER FIR: time=%0t tx=%0d rx=%0d compared=0 BER=NaN", $time, tx_count, rx_count_fir);
        end
    end
    endtask

    task finish_ber_simulation;
    begin
        write_ber_report;
        $finish;
    end
    endtask

    always @(posedge clk_100M) begin
        if (rst) begin
            tx_count = 0;
        end else if (uut.bit_valid_wire && tx_count < PAYLOAD_LEN) begin
            tx_bits[tx_count] = uut.data_in_wire;
            last_tx_index = tx_count;
            last_tx_bit   = uut.data_in_wire;
            tx_count = tx_count + 1;
        end
    end

    always @(posedge clk_100M) begin
        if (rst) begin
            rx_count_legacy        = 0;
            last_rx_index_legacy   = -1;
            last_rx_bit_legacy     = 1'b0;
            last_ref_bit_legacy    = 1'b0;
            legacy_match           = 1'b1;
            legacy_mismatch_pulse  = 1'b0;
        end else if (llr_calc_done_legacy && rx_count_legacy < PAYLOAD_LEN) begin
            rx_bits_legacy[rx_count_legacy] = ($signed(softOut_legacy) < 0);
            last_rx_index_legacy = rx_count_legacy;
            last_rx_bit_legacy   = ($signed(softOut_legacy) < 0);
            last_ref_bit_legacy  = tx_bits[rx_count_legacy];
            legacy_match         = (($signed(softOut_legacy) < 0) === tx_bits[rx_count_legacy]);
            legacy_mismatch_pulse = !(($signed(softOut_legacy) < 0) === tx_bits[rx_count_legacy]);
            if (fp_soft_compare != 0) begin
                $fwrite(
                    fp_soft_compare,
                    "legacy,%0d,%0t,%0d,%0d,%0d\n",
                    rx_count_legacy,
                    $time,
                    $signed(softOut_legacy),
                    ($signed(softOut_legacy) < 0),
                    tx_bits[rx_count_legacy]
                );
            end
            rx_count_legacy = rx_count_legacy + 1;
        end else begin
            legacy_mismatch_pulse = 1'b0;
        end
    end

    always @(posedge clk_100M) begin
        if (rst) begin
            rx_count_fir       = 0;
            last_rx_index_fir  = -1;
            last_rx_bit_fir    = 1'b0;
            last_ref_bit_fir   = 1'b0;
            fir_match          = 1'b1;
            fir_mismatch_pulse = 1'b0;
            rx_bit_diff_pulse  = 1'b0;
        end else if (llr_calc_done_fir && rx_count_fir < PAYLOAD_LEN) begin
            rx_bits_fir[rx_count_fir] = ($signed(softOut_fir) < 0);
            last_rx_index_fir = rx_count_fir;
            last_rx_bit_fir   = ($signed(softOut_fir) < 0);
            last_ref_bit_fir  = tx_bits[rx_count_fir];
            fir_match         = (($signed(softOut_fir) < 0) === tx_bits[rx_count_fir]);
            fir_mismatch_pulse = !(($signed(softOut_fir) < 0) === tx_bits[rx_count_fir]);
            rx_bit_diff_pulse  = (llr_calc_done_legacy && (rx_count_legacy == rx_count_fir)) ?
                                 ((($signed(softOut_legacy) < 0) !== ($signed(softOut_fir) < 0))) :
                                 1'b0;
            if (fp_soft_compare != 0) begin
                $fwrite(
                    fp_soft_compare,
                    "fir,%0d,%0t,%0d,%0d,%0d\n",
                    rx_count_fir,
                    $time,
                    $signed(softOut_fir),
                    ($signed(softOut_fir) < 0),
                    tx_bits[rx_count_fir]
                );
            end
            rx_count_fir = rx_count_fir + 1;
        end else begin
            fir_mismatch_pulse = 1'b0;
            rx_bit_diff_pulse  = 1'b0;
        end
    end

    initial begin
        clk_100M                 = 1'b0;
        rst                      = 1'b1;
        rst_dds                  = 1'b0;
        init_phs_in              = 24'd0;
        tx_count                 = 0;
        rx_count_legacy          = 0;
        rx_count_fir             = 0;
        compared_legacy          = 0;
        compared_fir             = 0;
        error_count_legacy       = 0;
        error_count_fir          = 0;
        first_error_index_legacy = -1;
        first_error_index_fir    = -1;
        report_done              = 1'b0;
        last_tx_index            = -1;
        last_rx_index_legacy     = -1;
        last_rx_index_fir        = -1;
        last_tx_bit              = 1'b0;
        last_rx_bit_legacy       = 1'b0;
        last_rx_bit_fir          = 1'b0;
        last_ref_bit_legacy      = 1'b0;
        last_ref_bit_fir         = 1'b0;
        legacy_match             = 1'b1;
        fir_match                = 1'b1;
        legacy_mismatch_pulse    = 1'b0;
        fir_mismatch_pulse       = 1'b0;
        rx_bit_diff_pulse        = 1'b0;

        fp_soft_compare = $fopen("gmsk_softout_compare.csv", "w");
        if (fp_soft_compare != 0)
            $fwrite(fp_soft_compare, "filter,rx_index,time_ps,softOut,rx_bit,tx_bit\n");

        #100;
        rst = 1'b0;
        #100;
        rst_dds = 1'b1;
        #20;
        rst_dds = 1'b0;
        init_phs_in = 24'h2093E0;

        #TIMEOUT_NS;
        finish_ber_simulation;
    end

    initial begin
        report_at_ns = 0;
        if ($value$plusargs("REPORT_AT_NS=%d", report_at_ns) && report_at_ns > 0) begin
            #(report_at_ns);
            write_ber_report;
        end
    end
endmodule
