vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu  \
"../../../../GMSK.gen/sources_1/ip/fifo_syn/sim/fifo_syn.v" \


vlog -work xil_defaultlib \
"glbl.v"

