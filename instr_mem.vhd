					 library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;	   
use IEEE.std_logic_signed.all;


entity instr_memory is
	generic (
	ADDR_WIDTH 	: integer := 12;
	DATA_WIDTH 	: integer := 32;
	CAPACITY   	: integer := 2048);
	port ( 
	clk 		: in 	std_logic;
	rst 		: in 	std_logic;
	write_en	: in 	std_logic;
	write_addr  : in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	read_addr 	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	write_data  : in 	std_logic_vector(DATA_WIDTH-1 downto 0);
	read_data 	: out 	std_logic_vector(DATA_WIDTH-1 downto 0));
end entity instr_memory;

architecture behavior_mem of instr_memory is

subtype word_t is std_logic_vector(DATA_WIDTH-1 downto 0);
type memory_t is array(CAPACITY downto 0) of word_t; 

signal memory : memory_t;

begin
	
	WRITE_PROC: process (clk) is
	begin
		if rising_edge(clk) then
			if rst = '0' and write_en = '1' then
				memory(to_integer(unsigned(('0'&write_addr)))) <= write_data;
			end if;
		end if;
	end process WRITE_PROC;	 	

	read_data <= memory(conv_integer('0'&read_addr)); 
	
end architecture behavior_mem;
	