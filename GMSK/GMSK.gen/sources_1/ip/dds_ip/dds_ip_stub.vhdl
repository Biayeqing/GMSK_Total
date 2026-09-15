-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
-- Date        : Tue Mar 10 21:21:48 2026
-- Host        : WIN-BGQBGGCSMU9 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/Administrator/Documents/xwechat_files/wxid_36h2qv5q47rz22_7d14/msg/file/2026-03/GMSK_Total_20260306/GMSK_Total_20260306/GMSK/GMSK.gen/sources_1/ip/dds_ip/dds_ip_stub.vhdl
-- Design      : dds_ip
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx485tffg1157-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dds_ip is
  Port ( 
    aclk : in STD_LOGIC;
    aclken : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    s_axis_phase_tvalid : in STD_LOGIC;
    s_axis_phase_tdata : in STD_LOGIC_VECTOR ( 23 downto 0 );
    m_axis_data_tvalid : out STD_LOGIC;
    m_axis_data_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

end dds_ip;

architecture stub of dds_ip is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "aclk,aclken,aresetn,s_axis_phase_tvalid,s_axis_phase_tdata[23:0],m_axis_data_tvalid,m_axis_data_tdata[31:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "dds_compiler_v6_0_22,Vivado 2023.1";
begin
end;
