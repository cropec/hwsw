library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;	   
use IEEE.std_logic_signed.all;


entity block_memory is
	generic (
	ADDR_WIDTH 	: integer := 5;
	DATA_WIDTH 	: integer := 32;
	CAPACITY   	: integer := 32);
	port ( 
	clk 		: in 	std_logic;
	rst 		: in 	std_logic;
	read_en  	: in 	std_logic;
	write_en 	: in 	std_logic;
	read_addr  	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	write_addr 	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	read_data  	: out 	std_logic_vector(DATA_WIDTH-1 downto 0);
	write_data 	: in 	std_logic_vector(DATA_WIDTH-1 downto 0));
end entity block_memory;
									
architecture behavior_mem of block_memory is

subtype word_t is std_logic_vector(DATA_WIDTH-1 downto 0);
type memory_t is array(CAPACITY-1 downto 0) of word_t; 

signal memory : memory_t;							 
signal data_output : word_t;
begin
	
	
	
	WRITE_PROC: process (clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				for i in 0 to CAPACITY-1 loop
					memory(i) <= (others=>'0');
				end loop;  
		    elsif write_en = '1' then
				memory(to_integer(unsigned(write_addr))) <= write_data;
			end if;
		end if;
	end process WRITE_PROC;
	
	READ_PROC: process (clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				read_data <= (others=>'0');
			elsif read_en = '1' then
				read_data <= data_output;
			end if;
		end if;
	end process READ_PROC;
	
	data_output <= write_data when (read_addr = write_addr) and (read_en = write_en) else memory(to_integer(unsigned(read_addr))); 
	
end architecture behavior_mem;
	