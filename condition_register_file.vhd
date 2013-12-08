library IEEE;
use IEEE.std_logic_1164.all; 	  
use ieee.std_logic_unsigned.all;  
use ieee.std_logic_arith.all;

entity condition_register_file is
	port( 	clk, rst, wr_en 					: in std_logic;  
			wr_addr_pos, wr_addr_neg, rd_addr	: in std_logic_vector(2 downto 0);
			wr_data_pos, wr_data_neg			: in std_logic;
			rd_data								: out std_logic);
end entity;

architecture behavior_cond_reg of condition_register_file is 

signal cr : std_logic_vector(7 downto 0) := "00000001";


begin
	
	COND_REG_WR_PROC: process (clk) is

	begin  
		if rising_edge(clk)then
			if rst = '1' then
				cr <= "00000001";
			else  
				if wr_addr_pos = wr_addr_neg then
					cr <= cr; 
				elsif wr_en = '1' then
					if(wr_addr_pos ="000")then
						cr(0) <= '1';
					else
			
						cr(conv_integer('0'&wr_addr_pos)) <= wr_data_pos;
					end if;	
					if(wr_addr_neg ="000")then
						cr(0) <= '1';
					else
						cr(conv_integer('0'&wr_addr_neg)) <= wr_data_neg;
					end if;
				end if;
			end if;	 
		end if;
	end process; 						 
	
	rd_data <= cr(conv_integer(rd_addr));

end architecture behavior_cond_reg;
	