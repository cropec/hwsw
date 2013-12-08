library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity adder is 
	generic( DATA_WIDTH : natural := 32 );
	port ( 
	input1 : in std_logic_vector(DATA_WIDTH-1 downto 0);
	input2 : in std_logic_vector(DATA_WIDTH-1 downto 0);
	output : out std_logic_vector(DATA_WIDTH-1 downto 0));
end entity adder;

architecture adder_behavior of adder is
begin
	
	output <= std_logic_vector(unsigned(input1)+unsigned(input2));
	
end architecture adder_behavior;