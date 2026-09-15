if {![info exists TRANSCRIPT_FILE]} {
    set TRANSCRIPT_FILE transcript_run.log
}
transcript file $TRANSCRIPT_FILE
transcript on

if {![info exists TOP_NAME]} {
    set TOP_NAME tb_top_GMSK_with_data_gen_ber
}
if {![info exists RUN_VALUE]} {
    set RUN_VALUE 2
}
if {![info exists RUN_UNIT]} {
    set RUN_UNIT ms
}
if {![info exists REPORT_AT_NS]} {
    set REPORT_AT_NS 2000000
}

foreach OUT_FILE {
    gmsk_ber_report.txt
    gmsk_ber_compare_report.txt
    gmsk_ber_legacy_report.txt
    gmsk_ber_fir_report.txt
    gmsk_softout_bits.csv
    gmsk_softout_compare.csv
} {
    if {[file exists $OUT_FILE]} {
        if {[catch {file delete -force $OUT_FILE} CLEAN_MSG]} {
            puts "WARNING: Could not delete $OUT_FILE: $CLEAN_MSG"
        }
    }
}

do compile.do

vsim -voptargs=+acc -onfinish stop -L fifo_generator_v13_2_8 +REPORT_AT_NS=$REPORT_AT_NS work.$TOP_NAME

proc add_wave_safe {args} {
    if {[catch {eval add wave -noupdate $args} MSG]} {
        puts "WARNING: add wave failed: $MSG"
    }
}

add wave -divider {TX source}
add wave -noupdate sim:/$TOP_NAME/clk_100M
add wave -noupdate sim:/$TOP_NAME/rst
add wave -noupdate -radix unsigned sim:/$TOP_NAME/tx_count
add wave -noupdate -radix decimal sim:/$TOP_NAME/last_tx_index
add wave -noupdate -radix binary sim:/$TOP_NAME/last_tx_bit
add wave -noupdate -radix binary sim:/$TOP_NAME/uut/data_in_wire
add wave -noupdate sim:/$TOP_NAME/uut/bit_valid_wire

add wave -divider {GMSK modulator output}
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/gmsk_dout_vd
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/gmsk_dout_I
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/gmsk_dout_Q
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/map_out_1
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/map_valid_1
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/inst_phs_out_1
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/inst_phs_vd_1
add_wave_safe -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/data_lp_out_1
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/data_lp_vld_1

add wave -divider {Legacy filter: rx_lowpass + downsample_10x}
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/rx_lowpass_out_vd_I
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/rx_lowpass_out_I
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/rx_lowpass_out_Q
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/downsample_out_vd_I
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/downsample_out_I
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/downsample_out_Q
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_downsample_10x_I/counter
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_downsample_10x_Q/counter

add wave -divider {New filter: fir_ds10_polyphase}
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/fir_downsample_out_vd_I
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/fir_downsample_out_vd_Q
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/fir_downsample_out_I
add wave -noupdate -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/fir_downsample_out_Q
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_fir_ds10_polyphase_I/ce_out
add_wave_safe -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/u_fir_ds10_polyphase_I/o_fir_data
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_fir_ds10_polyphase_Q/ce_out
add_wave_safe -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/u_fir_ds10_polyphase_Q/o_fir_data

add wave -divider {Legacy LLR}
add wave -noupdate sim:/$TOP_NAME/llr_calc_done_legacy
add wave -noupdate -radix decimal sim:/$TOP_NAME/softOut_legacy
add wave -noupdate -radix binary sim:/$TOP_NAME/softout_bit_legacy
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/start_llr_cal
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/fifo_data_ready
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/first_complete
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/fifo_rd_en
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/llr_warmup_count
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/llr_calc_done_raw
add_wave_safe -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/softOut_raw
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/fifo_module/data_counter
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/fifo_module/state
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/llr_module/state
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/llr_module/fifo_read_state
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_legacy/llr_module/gInd

add wave -divider {New FIR LLR}
add wave -noupdate sim:/$TOP_NAME/llr_calc_done_fir
add wave -noupdate -radix decimal sim:/$TOP_NAME/softOut_fir
add wave -noupdate -radix binary sim:/$TOP_NAME/softout_bit_fir
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/start_llr_cal
add wave -noupdate sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/fifo_data_ready
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/first_complete
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/fifo_rd_en
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/llr_warmup_count
add_wave_safe sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/llr_calc_done_raw
add_wave_safe -radix decimal sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/softOut_raw
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/fifo_module/data_counter
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/fifo_module/state
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/llr_module/state
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/llr_module/fifo_read_state
add_wave_safe -radix unsigned sim:/$TOP_NAME/uut/u_top_gmsk/u_top_llr_fir/llr_module/gInd

add wave -divider {BER bit compare debug}
add wave -noupdate -radix decimal sim:/$TOP_NAME/last_rx_index_legacy
add wave -noupdate -radix binary sim:/$TOP_NAME/last_rx_bit_legacy
add wave -noupdate -radix binary sim:/$TOP_NAME/last_ref_bit_legacy
add wave -noupdate -radix binary sim:/$TOP_NAME/legacy_match
add wave -noupdate -radix binary sim:/$TOP_NAME/legacy_mismatch_pulse
add wave -noupdate -radix decimal sim:/$TOP_NAME/last_rx_index_fir
add wave -noupdate -radix binary sim:/$TOP_NAME/last_rx_bit_fir
add wave -noupdate -radix binary sim:/$TOP_NAME/last_ref_bit_fir
add wave -noupdate -radix binary sim:/$TOP_NAME/fir_match
add wave -noupdate -radix binary sim:/$TOP_NAME/fir_mismatch_pulse
add wave -noupdate -radix binary sim:/$TOP_NAME/rx_bit_diff_pulse
add wave -noupdate -radix binary sim:/$TOP_NAME/softout_sign_diff
add wave -noupdate -radix decimal sim:/$TOP_NAME/softout_diff
add wave -noupdate -radix decimal sim:/$TOP_NAME/rx_count_delta

add wave -divider {BER counters}
add wave -noupdate -radix unsigned sim:/$TOP_NAME/rx_count_legacy
add wave -noupdate -radix unsigned sim:/$TOP_NAME/rx_count_fir
add wave -noupdate -radix unsigned sim:/$TOP_NAME/compared_legacy
add wave -noupdate -radix unsigned sim:/$TOP_NAME/compared_fir
add wave -noupdate -radix unsigned sim:/$TOP_NAME/error_count_legacy
add wave -noupdate -radix unsigned sim:/$TOP_NAME/error_count_fir
add wave -noupdate -radix decimal sim:/$TOP_NAME/first_error_index_legacy
add wave -noupdate -radix decimal sim:/$TOP_NAME/first_error_index_fir
add wave -noupdate -radix binary sim:/$TOP_NAME/report_done
configure wave -namecolwidth 240
update

run $RUN_VALUE $RUN_UNIT

if {[file exists gmsk_ber_compare_report.txt]} {
    set fp [open gmsk_ber_compare_report.txt r]
    puts "==== gmsk_ber_compare_report.txt ===="
    puts [read $fp]
    close $fp
} else {
    puts "WARNING: gmsk_ber_compare_report.txt was not generated."
}
