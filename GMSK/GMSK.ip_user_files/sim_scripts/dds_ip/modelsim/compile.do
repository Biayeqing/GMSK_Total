vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vcom -work xil_defaultlib  -93  \
"../../../../GMSK.gen/sources_1/ip/dds_ip/sim/dds_ip.vhd" \


vlog -work xil_defaultlib \
"glbl.v"

