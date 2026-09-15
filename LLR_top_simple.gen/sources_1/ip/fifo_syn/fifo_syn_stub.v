// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
// Date        : Wed Mar  4 19:30:53 2026
// Host        : WIN-RNAR2N3EUVH running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top fifo_syn -prefix
//               fifo_syn_ fifo_syn_stub.v
// Design      : fifo_syn
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_8,Vivado 2023.1" *)
module fifo_syn(clk, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="din[23:0],wr_en,rd_en,dout[23:0],full,empty" */
/* synthesis syn_force_seq_prim="clk" */;
  input clk /* synthesis syn_isclock = 1 */;
  input [23:0]din;
  input wr_en;
  input rd_en;
  output [23:0]dout;
  output full;
  output empty;
endmodule
