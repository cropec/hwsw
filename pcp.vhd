library IEEE;
library work;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;	   
use IEEE.std_logic_signed.all;
use work.interfaces.all;

entity pcp is
	generic (
	ADDR_WIDTH 	: integer := 32;
	DATA_WIDTH 	: integer := 32;
	CAPACITY   	: integer := 10);
port(
	clk		: in std_logic;
	rst		: in std_logic;
	new_wrap_in		: in std_logic; --dunno what is their purpose right now
	new_wrap_out   : out std_logic;--dunno what is their purpose right now
	imem_wr_en  : in std_logic;
   imem_wr_addr: in std_logic_vector(11 downto 0);	
   imem_wr_data: in std_logic_vector(31 downto 0);
	dmem_ext_wr_en  : in 	std_logic;
	dmem_ext_rd_en 	: in 	std_logic;
	dmem_ext_rd_addr  	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	dmem_ext_wr_addr 	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
	dmem_ext_rd_data  	: out 	std_logic_vector(DATA_WIDTH-1 downto 0);
	dmem_ext_wr_data 	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
	enable	: in std_logic);	
end pcp;

architecture Behavioral of pcp is

  
signal imem_rd_data: instr_mem_read_t;
signal imem_rd_addr: instr_mem_address_t;

signal dmem_rd_addr : data_mem_address_t;
signal dmem_wr_addr : data_mem_address_t;
signal dmem_rd_data : data_mem_data_rd_t;
signal dmem_wr_data : data_mem_data_wr_t;
signal dmem_read_en : std_logic;
signal dmem_write_en : std_logic;


signal dmem_int_addr    : data_mem_address_t;
signal dmem_int_data_wr : data_mem_data_wr_t;
signal dmem_int_data_rd : data_mem_data_rd_t;
signal dmem_int_control : data_mem_control_t;

signal sync_req : std_logic;
signal sync_rep : std_logic;


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
	
	sync_request	: out std_logic;
	sync_reply		: in 	std_logic;	 	
	
	instr_mem_read 	: in 	instr_mem_read_t;
	instr_mem_address	: out	instr_mem_address_t; 
	
	data_mem_addr		: out data_mem_address_t;
	data_mem_data_wr	: out	data_mem_data_wr_t;
	data_mem_data_rd	: in 	data_mem_data_rd_t;
	data_mem_control	: out data_mem_control_t);
end component execution_unit;

component multiplexer2_1 is										 
	generic(DATA_WIDTH 	: integer := 32;
			SELX 		: integer := 0);
	port(input1	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		 input2	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		 sel	: in 	std_logic;
		 output	: out 	std_logic_vector(DATA_WIDTH-1 downto 0));
	end component multiplexer2_1;	


begin


RD_ADDR_MEM_MUX: multiplexer2_1
		generic map ( DATA_WIDTH => DATA_WIDTH)
		port map( input1 =>std_logic_vector(dmem_ext_rd_addr) ,
				  input2 => std_logic_vector(dmem_int_addr),
				  sel	 => enable,
				  output => dmem_rd_addr);
				  
WR_ADDR_MEM_MUX: multiplexer2_1
		generic map ( DATA_WIDTH => DATA_WIDTH)
		port map( input1 =>std_logic_vector(dmem_ext_wr_addr) ,
				  input2 => std_logic_vector(dmem_int_addr),
				  sel	 => enable,
				  output => dmem_wr_addr);

	
WR_DATA_MEM_MUX: multiplexer2_1
		generic map ( DATA_WIDTH => DATA_WIDTH)
		port map( input1 =>std_logic_vector(dmem_ext_wr_data) ,
				  input2 => std_logic_vector(dmem_int_data_wr),
				  sel	 => enable,
				  output => dmem_wr_data);						  

DATA_MEM_INSTANCE: block_memory 	
	generic map(ADDR_WIDTH => 32, DATA_WIDTH => 32, CAPACITY => 10)
	port map ( clk => clk, rst => rst,
			   read_en => dmem_read_en, --(dmem_int_control.read_enable) when enable = '1' else dmem_ext_rd_en,
			   write_en => dmem_write_en,--dmem_int_control.write_enable,-- or dmem_wr_en,	
			   read_addr => dmem_rd_addr  ,
			   write_addr => dmem_wr_addr ,
			   read_data => dmem_rd_data ,
			   write_data => dmem_wr_data);
				
				dmem_read_en <= dmem_int_control.read_enable when enable = '1' else dmem_ext_rd_en;
				dmem_write_en <= dmem_int_control.write_enable when enable = '1' else dmem_ext_wr_en;
				dmem_ext_rd_data<= dmem_rd_data;
				dmem_int_data_rd <= dmem_rd_data;

	INSTR_MEM_INSTANCE: instr_memory 
	port map (clk => clk,	rst => rst,
			write_en	=> imem_wr_en,
			write_addr  => imem_wr_addr,
			write_data 	=> imem_wr_data,
			read_addr 	=> imem_rd_addr,
			read_data 	=> imem_rd_data);
			
	EXE_UNIT_INST: execution_unit 
	port map( clk		=> clk,
			  rst		=> rst,
			  enable	=> enable, 
	
			  curr_wrap		=> (others=>'0'),
			  new_wrap_in 	=> new_wrap_in,		
           new_wrap_out	=> new_wrap_out,
	
			  sync_request	=> sync_req,
			  sync_reply	=> sync_rep, 	
	
			  instr_mem_read 	=> imem_rd_data,
			  instr_mem_address	=> imem_rd_addr, 

			  data_mem_addr		=> dmem_int_addr,
			  data_mem_data_wr	=> dmem_int_data_wr,
			  data_mem_data_rd	=> dmem_int_data_rd,
			  data_mem_control	=> dmem_int_control);
 
 
		sync_rep <= '1' when sync_req = '1' else  '0';
	
	
end architecture;




