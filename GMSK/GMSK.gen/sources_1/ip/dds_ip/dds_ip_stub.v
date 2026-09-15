// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
// Date        : Tue Mar 10 21:21:48 2026
// Host        : WIN-BGQBGGCSMU9 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/Administrator/Documents/xwechat_files/wxid_36h2qv5q47rz22_7d14/msg/file/2026-03/GMSK_Total_20260306/GMSK_Total_20260306/GMSK/GMSK.gen/sources_1/ip/dds_ip/dds_ip_stub.v
// Design      : dds_ip
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1157-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "dds_compiler_v6_0_22,Vivado 2023.1" *)
module dds_ip(aclk, aclken, aresetn, s_axis_phase_tvalid, 
  s_axis_phase_tdata, m_axis_data_tvalid, m_axis_data_tdata)
/* synthesis syn_black_box black_box_pad_pin="aclken,aresetn,s_axis_phase_tvalid,s_axis_phase_tdata[23:0],m_axis_data_tvalid,m_axis_data_tdata[31:0]" */
/* synthesis syn_force_seq_prim="aclk" */;
  input aclk /* synthesis syn_isclock = 1 */;
  input aclken;
  input aresetn;
  input s_axis_phase_tvalid;
  input [23:0]s_axis_phase_tdata;
  output m_axis_data_tvalid;
  output [31:0]m_axis_data_tdata;
endmodule
