-------------------------------------------------------------------------------------
-- Company   :  National Key Laboratory of Wireless Communications, UESTC
-- Engineer  :  Tingyong Wu
-- Version   :  1.0
-- Data      :  12.31.2025
-- Function  :
-- Comment01 :
-------------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

entity dds_rstn_gen is
Port (
	clk                : in  std_logic;
	rst                : in  std_logic;
	rst_dds            : in  std_logic;
	dds_aresetn        : out std_logic
	);
end dds_rstn_gen;

architecture Behavioral of dds_rstn_gen is


-- signals for reset and config controlling
signal rst_cnt_en  : std_logic;
signal rst_cnt     : unsigned(2 downto 0);

begin

---------------------------------------------------------------
-- generate counting enabel signal
---------------------------------------------------------------
proc_cnt_en_gen : process(clk,rst)
begin
    if ( rst = '1' ) then
		rst_cnt_en <= '0';
	elsif ( clk'event and clk = '1' ) then
		if ( rst_dds = '1') then
			rst_cnt_en <= '1';
		end if;
		if ( rst_cnt_en = '1' and rst_cnt = 7 ) then
			rst_cnt_en <= '0';
		end if;
	end if;
end process proc_cnt_en_gen;

---------------------------------------------------------------
-- reset counting
---------------------------------------------------------------
proc_reset_cnt : process(clk,rst)
begin
    if ( rst = '1' ) then
		rst_cnt <= (others=>'0');
	elsif ( clk'event and clk = '1' ) then
		if ( rst_cnt_en = '1') then
			rst_cnt <= rst_cnt + 1;
		else
			rst_cnt <= (others=>'0');
		end if;
	end if;
end process proc_reset_cnt;

---------------------------------------------------------------
-- generate resetn signal
---------------------------------------------------------------
proc_rstn_gen : process(clk,rst)
begin
    if ( rst = '1' ) then
		dds_aresetn <= '1';
	elsif ( clk'event and clk = '1' ) then
		if ( rst_cnt_en = '1' and rst_cnt > 3 ) then
			dds_aresetn <= '0';
		else
			dds_aresetn <= '1';
		end if;
	end if;
end process proc_rstn_gen;


end Behavioral;
