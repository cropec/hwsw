library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;


entity bit_extension is										 
	generic(INPUT_DATA_WIDTH 	: integer := 16;
			OUTPUT_DATA_WIDHT 	: integer := 32);
	port(input	: in 	std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
		 output	: out 	std_logic_vector(OUTPUT_DATA_WIDHT-1 downto 0));
end entity;

architecture bit_ext_behavior of bit_extension is
	 signal added_bits : std_logic_vector( OUTPUT_DATA_WIDHT - INPUT_DATA_WIDTH -1 downto 0);
begin
	added_bits <= (others=>'0');
	output <= added_bits & input;
end architecture bit_ext_behavior;