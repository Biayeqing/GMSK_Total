transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+fifo_syn  -L xpm -L fifo_generator_v13_2_8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.fifo_syn xil_defaultlib.glbl

do {fifo_syn.udo}

run 1000ns

endsim

quit -force
