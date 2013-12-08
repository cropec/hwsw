library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;


entity multiplexer2_1 is										 
	generic ( DATA_WIDTH 	: integer := 32;
			  SELX 			: integer := 0);
	port ( 	input1	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
			input2	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		  	sel		: in 	std_logic;
		   	output	: out 	std_logic_vector(DATA_WIDTH-1 downto 0));
end entity;


architecture mux_behavior of multiplexer2_1 is
begin
	output <= input2 when (sel='1') else input1;
end architecture;  



