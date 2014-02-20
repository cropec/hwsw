library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;	   
use IEEE.std_logic_signed.all;


entity reg_file is
	generic (
	ADDR_WIDTH 	: integer := 5;
	DATA_WIDTH 	: integer := 32;
	CAPACITY   	: integer := 32);
	port ( 
	clk 		: in 	std_logic;
	rst 		: in 	std_logic;
	write_en	: in 	std_logic;
	write_addr  : in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	read_addr 	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	write_data  : in 	std_logic_vector(DATA_WIDTH-1 downto 0);
	read_data 	: out 	std_logic_vector(DATA_WIDTH-1 downto 0));
end entity reg_file;

architecture behavior_reg_file of reg_file is

subtype word_t is std_logic_vector(DATA_WIDTH-1 downto 0);
type memory_t is array(CAPACITY-1 downto 0) of word_t; 

signal memory : memory_t;

--signal test :integer;
begin
	
	
	WRITE_PROC: process (clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				for i in 0 to CAPACITY-1 loop
					memory(i) <= (others=>'0');
				end loop;  
		    elsif write_en = '1' then
				memory(to_integer(unsigned(('0'&write_addr)))) <= write_data;
			end if;
		end if;
	end process WRITE_PROC;
	

	--test <= conv_integer('0'&read_addr);									  	
	read_data <= memory(to_integer(unsigned('0'&read_addr)));	
	
end architecture behavior_reg_file;
	