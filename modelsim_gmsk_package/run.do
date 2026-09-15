do compile.do
vsim -voptargs=+acc -L fifo_generator_v13_2_8 work.tb_top_GMSK_with_data_gen_ber
add wave -r sim:/tb_top_GMSK_with_data_gen_ber/uut/*
add wave -noupdate -radix decimal sim:/tb_top_GMSK_with_data_gen_ber/softOut
add wave -noupdate sim:/tb_top_GMSK_with_data_gen_ber/llr_calc_done
add wave -noupdate -radix binary sim:/tb_top_GMSK_with_data_gen_ber/uut/data_in_wire
add wave -noupdate sim:/tb_top_GMSK_with_data_gen_ber/uut/bit_valid_wire
configure wave -namecolwidth 240
update
run 120 ms
