transcript on

if {[file exists modelsim_lib]} { vdel -lib modelsim_lib/work -all }
file mkdir modelsim_lib
vlib modelsim_lib/work
vmap work modelsim_lib/work

vlib modelsim_lib/fifo_generator_v13_2_8
vmap fifo_generator_v13_2_8 modelsim_lib/fifo_generator_v13_2_8

vlib modelsim_lib/dds_compiler_v6_0_22
vmap dds_compiler_v6_0_22 modelsim_lib/dds_compiler_v6_0_22
vlib modelsim_lib/xbip_utils_v3_0_10
vmap xbip_utils_v3_0_10 modelsim_lib/xbip_utils_v3_0_10
vlib modelsim_lib/axi_utils_v2_0_6
vmap axi_utils_v2_0_6 modelsim_lib/axi_utils_v2_0_6
vlib modelsim_lib/xbip_pipe_v3_0_6
vmap xbip_pipe_v3_0_6 modelsim_lib/xbip_pipe_v3_0_6
vlib modelsim_lib/xbip_bram18k_v3_0_6
vmap xbip_bram18k_v3_0_6 modelsim_lib/xbip_bram18k_v3_0_6
vlib modelsim_lib/mult_gen_v12_0_18
vmap mult_gen_v12_0_18 modelsim_lib/mult_gen_v12_0_18
vlib modelsim_lib/xbip_dsp48_wrapper_v3_0_4
vmap xbip_dsp48_wrapper_v3_0_4 modelsim_lib/xbip_dsp48_wrapper_v3_0_4
vlib modelsim_lib/xbip_dsp48_addsub_v3_0_6
vmap xbip_dsp48_addsub_v3_0_6 modelsim_lib/xbip_dsp48_addsub_v3_0_6
vlib modelsim_lib/xbip_dsp48_multadd_v3_0_6
vmap xbip_dsp48_multadd_v3_0_6 modelsim_lib/xbip_dsp48_multadd_v3_0_6

vlog -work fifo_generator_v13_2_8 -incr ipstatic/simulation/fifo_generator_vlog_beh.v
vcom -work fifo_generator_v13_2_8 -93 ipstatic/hdl/fifo_generator_v13_2_rfs.vhd
vlog -work fifo_generator_v13_2_8 -incr ipstatic/hdl/fifo_generator_v13_2_rfs.v

vcom -work xbip_utils_v3_0_10 -93 ipstatic/hdl/xbip_utils_v3_0_vh_rfs.vhd
vcom -work axi_utils_v2_0_6 -93 ipstatic/hdl/axi_utils_v2_0_vh_rfs.vhd
vcom -work xbip_pipe_v3_0_6 -93 ipstatic/hdl/xbip_pipe_v3_0_vh_rfs.vhd
vcom -work xbip_bram18k_v3_0_6 -93 ipstatic/hdl/xbip_bram18k_v3_0_vh_rfs.vhd
vcom -work mult_gen_v12_0_18 -93 ipstatic/hdl/mult_gen_v12_0_vh_rfs.vhd
vcom -work xbip_dsp48_wrapper_v3_0_4 -93 ipstatic/hdl/xbip_dsp48_wrapper_v3_0_vh_rfs.vhd
vcom -work xbip_dsp48_addsub_v3_0_6 -93 ipstatic/hdl/xbip_dsp48_addsub_v3_0_vh_rfs.vhd
vcom -work xbip_dsp48_multadd_v3_0_6 -93 ipstatic/hdl/xbip_dsp48_multadd_v3_0_vh_rfs.vhd
vcom -work dds_compiler_v6_0_22 -93 ipstatic/hdl/dds_compiler_v6_0_vh_rfs.vhd

vlog -work work ip/fifo_syn/fifo_syn.v
vlog -work work ip/fifo_generator_0.v
vlog -work work ip/gmsk_modulator_top.v
vcom -work work -93 rtl/dds_rstn_gen.vhd
vcom -work work -93 ip/dds_ip/dds_ip.vhd

vlog -work work -incr \
    rtl/hdlsrc/fir_ds10_polyphase/FIR_Decimation.v \
    rtl/hdlsrc/fir_ds10_polyphase/fir_ds10_polyphase_tc.v \
    rtl/hdlsrc/fir_ds10_polyphase/fir_ds10_polyphase.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapPostAdd.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block1.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block2.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block3.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block4.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block5.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block6.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block7.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block8.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block9.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block10.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block11.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block12.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block13.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block14.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block15.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block16.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block17.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block18.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block19.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block20.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block21.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block22.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block23.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block24.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block25.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block26.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD_block27.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWMultOutCSD.v \
    rtl/hdlsrc/fir_ds10_onephase/FilterTapWvldIn.v \
    rtl/hdlsrc/fir_ds10_onephase/subFilter.v \
    rtl/hdlsrc/fir_ds10_onephase/Filter.v \
    rtl/hdlsrc/fir_ds10_onephase/Discrete_FIR_Filter.v \
    rtl/hdlsrc/fir_ds10_onephase/fir_ds10_onephase.v

vlog -work work -incr rtl/alpha_calculate.v rtl/beta_calculator_top.v rtl/downsample_10x.v rtl/FIFO_Q15_Q5_10.v rtl/gamma_alpha_calculate_top.v rtl/gamma_calculate.v rtl/llr_calculate.v rtl/low_pass_filter.v rtl/mapping.v rtl/renew_both_matrix_module.v rtl/renew_single_matrix_module.v rtl/Rx_lowpass_filter.v rtl/top_GMSK_with_data_gen.v rtl/top_GMSK.v rtl/top_integrated_system.v rtl/top_LLRcalculate.v rtl/tx_guass_filter.v rtl/update_max_matrix_module.v rtl/update_max_module.v rtl/upsample.v
vlog -work work -incr glbl.v
vlog -work work -incr tb/tb_top_GMSK_with_data_gen_ber.v

puts "Compilation complete. Run: vsim -L fifo_generator_v13_2_8 work.tb_top_GMSK_with_data_gen_ber"
