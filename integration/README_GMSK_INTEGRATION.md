# GMSK demodulator integration

Files:

- `top_dmod.v`: updated top-level BPSK/GMSK selection.
- `gmsk_dmod.v`: receive-only GMSK wrapper.

The GMSK wrapper reuses these RTL modules from
`LLR_top_simple.srcs/sources_1/new`:

- `Rx_lowpass_filter.v`
- `downsample_10x.v`
- `top_integrated_system.v`
- `FIFO_Q15_Q5_10.v`
- `top_LLRcalculate.v`
- `llr_calculate.v`
- `gamma_alpha_calculate_top.v`
- `gamma_calculate.v`
- `alpha_calculate.v`
- `beta_calculator_top.v`
- `renew_single_matrix_module.v`
- `renew_both_matrix_module.v`
- `update_max_module.v`
- `update_max_matrix_module.v`

Add the wrapper and all dependencies to the destination Vivado project.

Interface assumptions:

- `DATA_WIDTH` is 16 and IQ samples use Q1.15.
- `i_sample_vld` marks every sample of the oversampled GMSK stream.
- The existing chain expects 100 input samples per information bit:
  the wrapper decimates by 10, then the LLR FIFO groups 10 samples.
- `i_strobe_vld` is intentionally unused by the GMSK MLSE path.
- `lr_greg == 0` selects BPSK and `lr_greg == 1` selects GMSK.
- `softOut < 0` is decoded as bit 1; otherwise it is bit 0.

If the upstream receiver already performs matched filtering or 10x
decimation, remove the corresponding duplicate stage from `gmsk_dmod.v`.
