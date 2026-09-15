onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TX source}
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/clk_100M
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/rst
add wave -noupdate -radix unsigned /tb_top_GMSK_with_data_gen_ber/tx_count
add wave -noupdate -radix binary /tb_top_GMSK_with_data_gen_ber/uut/data_in_wire
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/bit_valid_wire
add wave -noupdate -divider {GMSK modulator output}
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/gmsk_dout_vd
add wave -noupdate -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/gmsk_dout_I
add wave -noupdate -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/gmsk_dout_Q
add wave -noupdate -divider {Legacy filter: rx_lowpass + downsample_10x}
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/rx_lowpass_out_vd_I
add wave -noupdate -format Analog-Step -height 74 -max 16560.0 -min -16571.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/rx_lowpass_out_I
add wave -noupdate -format Analog-Step -height 74 -max 16560.0 -min -16571.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/rx_lowpass_out_Q
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/downsample_out_vd_I
add wave -noupdate -format Analog-Step -height 74 -max 16558.999999999996 -min -16570.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/downsample_out_I
add wave -noupdate -format Analog-Step -height 74 -max 16558.999999999996 -min -16570.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/downsample_out_Q
add wave -noupdate -divider {New filter: fir_ds10_polyphase + fir_ds10_onephase}
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/polyfir_vld
add wave -noupdate -format Analog-Step -height 74 -max 18720.000000000004 -min -18729.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/polyfir_I
add wave -noupdate -format Analog-Step -height 74 -max 18720.000000000004 -min -18729.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/polyfir_Q
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/fir_downsample_out_vd_I
add wave -noupdate -format Analog-Step -height 74 -max 22016.0 -min -22031.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/fir_downsample_out_I
add wave -noupdate -format Analog-Step -height 74 -max 22019.0 -min -22028.0 -radix decimal /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/fir_downsample_out_Q
add wave -noupdate -divider {Legacy LLR}
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/llr_calc_done_legacy
add wave -noupdate -radix decimal /tb_top_GMSK_with_data_gen_ber/softOut_legacy
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/u_top_llr_legacy/start_llr_cal
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/u_top_llr_legacy/fifo_data_ready
add wave -noupdate -divider {New FIR LLR}
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/llr_calc_done_fir
add wave -noupdate -radix decimal /tb_top_GMSK_with_data_gen_ber/softOut_fir
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/u_top_llr_fir/start_llr_cal
add wave -noupdate /tb_top_GMSK_with_data_gen_ber/uut/u_top_gmsk/u_top_llr_fir/fifo_data_ready
add wave -noupdate -divider {BER counters}
add wave -noupdate -radix unsigned /tb_top_GMSK_with_data_gen_ber/rx_count_legacy
add wave -noupdate -radix unsigned /tb_top_GMSK_with_data_gen_ber/rx_count_fir
add wave -noupdate -radix unsigned /tb_top_GMSK_with_data_gen_ber/error_count_legacy
add wave -noupdate -radix unsigned /tb_top_GMSK_with_data_gen_ber/error_count_fir
add wave -noupdate -radix decimal /tb_top_GMSK_with_data_gen_ber/first_error_index_legacy
add wave -noupdate -radix decimal /tb_top_GMSK_with_data_gen_ber/first_error_index_fir
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2355000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 240
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {7730656 ps}
