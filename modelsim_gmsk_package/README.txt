# ModelSim GMSK package

1. Open ModelSim and change directory to this folder.
2. Run: `do compile.do`
3. Run: `vsim -L fifo_generator_v13_2_8 work.tb_top_GMSK_with_data_gen_ber`
4. Run: `run 120 ms`

The testbench reads `tb/random_100k.mem`, captures 100000 TX bits and 100000 RX decisions, and writes `gmsk_ber_report.txt` and `gmsk_softout_bits.csv` in the current ModelSim directory.

If `dds_ip.vhd` reports missing Xilinx libraries, compile with the Vivado ModelSim libraries available in your installation or run the generated IP compile scripts first.
