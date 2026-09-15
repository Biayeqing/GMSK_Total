transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vmap -link {C:/Users/Administrator/Documents/xwechat_files/wxid_36h2qv5q47rz22_7d14/msg/file/2026-03/GMSK_Total_20260306/GMSK_Total_20260306/GMSK/GMSK.cache/compile_simlib/riviera}
vlib riviera/xpm
vlib riviera/xbip_utils_v3_0_10
vlib riviera/axi_utils_v2_0_6
vlib riviera/xbip_pipe_v3_0_6
vlib riviera/xbip_bram18k_v3_0_6
vlib riviera/mult_gen_v12_0_18
vlib riviera/xbip_dsp48_wrapper_v3_0_4
vlib riviera/xbip_dsp48_addsub_v3_0_6
vlib riviera/xbip_dsp48_multadd_v3_0_6
vlib riviera/dds_compiler_v6_0_22
vlib riviera/xil_defaultlib

vlog -work xpm  -incr -l xpm -l xbip_utils_v3_0_10 -l axi_utils_v2_0_6 -l xbip_pipe_v3_0_6 -l xbip_bram18k_v3_0_6 -l mult_gen_v12_0_18 -l xbip_dsp48_wrapper_v3_0_4 -l xbip_dsp48_addsub_v3_0_6 -l xbip_dsp48_multadd_v3_0_6 -l dds_compiler_v6_0_22 -l xil_defaultlib \
"E:/Vivado/Vivado/2023.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"E:/Vivado/Vivado/2023.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"E:/Vivado/Vivado/2023.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xbip_utils_v3_0_10 -93  -incr \
"../../../ipstatic/hdl/xbip_utils_v3_0_vh_rfs.vhd" \

vcom -work axi_utils_v2_0_6 -93  -incr \
"../../../ipstatic/hdl/axi_utils_v2_0_vh_rfs.vhd" \

vcom -work xbip_pipe_v3_0_6 -93  -incr \
"../../../ipstatic/hdl/xbip_pipe_v3_0_vh_rfs.vhd" \

vcom -work xbip_bram18k_v3_0_6 -93  -incr \
"../../../ipstatic/hdl/xbip_bram18k_v3_0_vh_rfs.vhd" \

vcom -work mult_gen_v12_0_18 -93  -incr \
"../../../ipstatic/hdl/mult_gen_v12_0_vh_rfs.vhd" \

vcom -work xbip_dsp48_wrapper_v3_0_4 -93  -incr \
"../../../ipstatic/hdl/xbip_dsp48_wrapper_v3_0_vh_rfs.vhd" \

vcom -work xbip_dsp48_addsub_v3_0_6 -93  -incr \
"../../../ipstatic/hdl/xbip_dsp48_addsub_v3_0_vh_rfs.vhd" \

vcom -work xbip_dsp48_multadd_v3_0_6 -93  -incr \
"../../../ipstatic/hdl/xbip_dsp48_multadd_v3_0_vh_rfs.vhd" \

vcom -work dds_compiler_v6_0_22 -93  -incr \
"../../../ipstatic/hdl/dds_compiler_v6_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../../GMSK.gen/sources_1/ip/dds_ip/sim/dds_ip.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

