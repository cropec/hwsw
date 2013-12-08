library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;  
use ieee.std_logic_arith.all;
use interfaces.all;

entity testbench is
end entity;		   

architecture test_behavios of testbench is 

constant NO_OF_INSTR : natural := 7;
type instr_mem_type is array (0 to NO_OF_INSTR-1) of std_logic_vector(31 downto 0);
signal intruction_memory_content : instr_mem_type := (
"00001110000000001000000000011000", --IADD r1 = r0 +0x18
"00001110000000010000000000000111",	--IADD r2 = r0 +0x07
"00000010001000001000110000000000",	--ADD  r3 = r1 + r2
"00000110000000011000000000000001", --ST   r0[1] = r3
"00000100000000100000000000000001",	--LD   r4 = r0[1] 
"00001010001100100000001000001010",	--CMP  r3 = r4? c1=1 c2=0 
"00001010001100010000001000011100"	--CMP  r3 = r4? c1=1 c2=0
); 

signal intruction_memory_content2 : instr_mem_type := (
"00000110000000001000000000001010", --IADD r1 = r0 +0x0A
"00000110000000010000000000000011",	--IADD r2 = r0 +0x01
"00000000000000000000000000000000", --ST   r3[0] = r3
"00000000000000000000000000000000",	--ADD  r3 = r3 + r2
"00000000000100011000001011001010",	--CMP  r1 > r3? c1=1 c2=0 
"00000000000000000000000000000010",	--JMP  #2 IF c1	  
"00000000000000000000000000000000"
);

signal clock : std_logic := '0';
signal clk, reset: std_logic := '0' ;
signal exeu_en : std_logic := '0';

signal imem_wr_en  : std_logic := '0';	  
signal imem_wr_addr: std_logic_vector(11 downto 0);	
signal imem_wr_data: std_logic_vector(31 downto 0);		  
signal imem_rd_data: instr_mem_read_t;
signal imem_rd_addr: instr_mem_address_t;

signal dm_addr 	  : data_mem_address_t;
signal dm_data_wr : data_mem_data_wr_t;
signal dm_data_rd : data_mem_data_rd_t;
signal dm_control : data_mem_control_t;

component block_memory is
	generic (
	ADDR_WIDTH 	: integer := 32;
	DATA_WIDTH 	: integer := 32;
	CAPACITY   	: integer := 10);
	port ( 
	clk 		: in 	std_logic;
	rst 		: in 	std_logic;
	read_en  	: in 	std_logic;
	write_en 	: in 	std_logic;
	read_addr  	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	write_addr 	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	read_data  	: out 	std_logic_vector(DATA_WIDTH-1 downto 0);
	write_data 	: in 	std_logic_vector(DATA_WIDTH-1 downto 0));
end component block_memory;

component instr_memory is
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
end component instr_memory;

						   
component execution_unit is 
	port(
	clk		: in std_logic;
	rst		: in std_logic;
	enable	: in std_logic;		 
	
	curr_wrap		: in std_logic_vector(5 downto 0);
	new_wrap_in		: in std_logic;
	new_wrap_out	: out std_logic;
	
	sync_request	: out 	std_logic;
	sync_reply		: in 	std_logic;	 	
	
	instr_mem_read 		: in 	instr_mem_read_t;
	instr_mem_address	: out	instr_mem_address_t; 
	
	data_mem_addr		: out  	data_mem_address_t;
	data_mem_data_wr	: out	data_mem_data_wr_t;
	data_mem_data_rd	: in 	data_mem_data_rd_t;
	data_mem_control	: out 	data_mem_control_t);
end component;

signal new_wrap_in : std_logic;
signal new_wrap_out: std_logic;
signal sync_req	: std_logic;
signal sync_rep	: std_logic := '0';
begin
	
	DATA_MEM_INSTANCE: block_memory 	
	generic map(ADDR_WIDTH => 32, DATA_WIDTH => 32, CAPACITY => 10)
	port map ( clk => clk, rst => reset,
			   read_en => dm_control.read_enable,
			   write_en => dm_control.write_enable,	
			   read_addr => dm_addr,
			   write_addr => dm_addr, 
			   read_data => dm_data_rd, 
			   write_data => dm_data_wr); 
	
	INSTR_MEM_INSTANCE: instr_memory 
	port map (clk => clk,	rst => reset,
			write_en	=> imem_wr_en,
			write_addr  => imem_wr_addr,
			write_data 	=> imem_wr_data,
			read_addr 	=> imem_rd_addr,
			read_data 	=> imem_rd_data);
			
	EXE_UNIT_INST: execution_unit 
	port map( clk		=> clk,
			  rst		=> reset,
			  enable	=> exeu_en, 
	
			  curr_wrap		=> (others=>'0'),
			  new_wrap_in 	=> new_wrap_in,		
			  new_wrap_out	=> new_wrap_out,
	
			  sync_request	=> sync_req,
			  sync_reply	=> sync_rep, 	
	
			  instr_mem_read 	=> imem_rd_data,
			  instr_mem_address	=> imem_rd_addr, 
	
			  data_mem_addr		=> dm_addr,
			  data_mem_data_wr	=> dm_data_wr,
			  data_mem_data_rd	=> dm_data_rd,
			  data_mem_control	=> dm_control);
 	
	
	clk <= not clk after 50 ns;		 	  
	
	CLOCK_PROC: process is
	begin
		clock<=not clock;
		wait for 50 ns;
	end process;
	
	TEST_PROC: process is 
	begin
		reset <= '1';	   
		wait for 100 ns;	
		reset <= '0';
		imem_wr_en <= '1';
		for i in 0 to NO_OF_INSTR-1	loop
			imem_wr_addr <= conv_std_logic_vector(i,12);
		    imem_wr_data <= intruction_memory_content2(i);
			wait for 100 ns;  
		end loop;
		imem_wr_en<='0';
		wait for 100 ns;
		exeu_en <= '1';
		wait for 10000ns;	 
		exeu_en <= '0';
	end process;
end architecture;

