# ModelSim GMSK package

1. Copy this whole folder to the target computer.
2. Open ModelSim and change directory to this folder.
3. Run: `do run.do`

`run.do` will compile the RTL/IP simulation models, load
`work.tb_top_GMSK_with_data_gen_ber`, add the useful waveform signals, and run
the 100000-bit BER simulation.

If you want to run the commands manually:

1. Run: `do compile.do`
2. Run: `vsim -voptargs=+acc -L fifo_generator_v13_2_8 work.tb_top_GMSK_with_data_gen_ber`
3. Run: `run 120 ms`

The testbench reads `tb/random_100k.mem`, captures 100000 TX bits and 100000 RX decisions, and writes `gmsk_ber_report.txt` and `gmsk_softout_bits.csv` in the current ModelSim directory.

If `dds_ip.vhd` reports missing Xilinx libraries, compile with the Vivado ModelSim libraries available in your installation or run the generated IP compile scripts first.
