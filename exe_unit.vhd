library IEEE;
library work; --.interfaces;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all; 
use work.interfaces.all;

entity execution_unit is 
	port(
	clk		: in std_logic;
	rst		: in std_logic;
	enable	: in std_logic;		 
	
	curr_wrap		: in std_logic_vector(5 downto 0);
	new_wrap_in		: in std_logic;
	new_wrap_out	: out std_logic;
	
	sync_request	: out std_logic;
	sync_reply		: in 	std_logic;	 	
	
	instr_mem_read 		: in 	instr_mem_read_t;
	instr_mem_address	: out	instr_mem_address_t; 
	
	data_mem_addr		: out  	data_mem_address_t;
	data_mem_data_wr	: out	data_mem_data_wr_t;
	data_mem_data_rd	: in 	data_mem_data_rd_t;
	data_mem_control	: out 	data_mem_control_t);
end entity;

architecture behavior of execution_unit is 

-----------------Component declarations---------------------------
	
	constant WORD_WIDTH 		: natural := 32;   
	constant ADDR_WIDTH 		: natural := 32;
	constant INSTR_ADDR_WIDTH 	: natural := 12;
	constant ALUOP_WIDTH 		: natural := 4;  
	constant REGF_ADDR_WIDHT 	: natural := 5;

	-----------------Instruction decoder--------------------------
	component intruction_decoder is
	port(rst		: in  std_logic;	 
		 enable 	: in  std_logic;		 
		 opcode		: in  std_logic_vector(3 downto 0);
		 cond_reg	: in  std_logic;	--content of the condition register that predicates the instruction
		 sync_reply : in  std_logic;	--1 if all the exe units are executing the sync instruction
		 pc_ld		: out std_logic;	--program counter load
		 wa_src		: out std_logic; 	--write address source - mux 1 sel
		 wr_en		: out std_logic;	--write register enable
		 wcr_en		: out std_logic; 	--write condition register enable
		 alu_op_src : out std_logic;	--alu operand source
		 wb_src		: out std_logic;	--write back source
		 dm_wr		: out std_logic;	--data memory write
		 dm_rd		: out std_logic;    --data memory read
		 jmp		: out std_logic;	--jump cmd signal
		 sync_req	: out std_logic;	--sync cmd signal
		 new_wrap	: out std_logic);	--new wrap cmd signal
	end component intruction_decoder;
	----------Block memroy used for register file-----------------
	component block_memory is
	generic(ADDR_WIDTH 	: integer := 5;
			DATA_WIDTH 	: integer := 32;
			CAPACITY   	: integer := 32);
	port(clk 			: in 	std_logic;
		 rst 			: in 	std_logic;
		 read_en  		: in 	std_logic;
		 write_en 		: in 	std_logic;
		 read_addr  	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
		 write_addr 	: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
		 read_data  	: out 	std_logic_vector(DATA_WIDTH-1 downto 0);
		 write_data 	: in 	std_logic_vector(DATA_WIDTH-1 downto 0));
	end component block_memory;	 
	
	component reg_file is
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
	end component reg_file;
	---------------Condition register file-------------------------
	component condition_register_file is
	port(clk, rst, wr_en 					: in std_logic;  
		 wr_addr_pos, wr_addr_neg, rd_addr	: in std_logic_vector(2 downto 0);
		 wr_data_pos, wr_data_neg			: in std_logic;
		 rd_data							: out std_logic);
	end component condition_register_file;
	--------------2 to 1 multiplexer with variable data width-------
	component multiplexer2_1 is										 
	generic(DATA_WIDTH 	: integer := 32;
			SELX 		: integer := 0);
	port(input1	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		 input2	: in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		 sel	: in 	std_logic;
		 output	: out 	std_logic_vector(DATA_WIDTH-1 downto 0));
	end component multiplexer2_1;	
	----------Bit extension module with variable data width---------
	component bit_extension is										 
	generic(INPUT_DATA_WIDTH 	: integer := 16;
			OUTPUT_DATA_WIDHT 	: integer := 32);
	port(input	: in 	std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
		 output	: out 	std_logic_vector(OUTPUT_DATA_WIDHT-1 downto 0));
	end component;	
	--------------------ALU unit------------------------------------
	component ALU is
  	generic(DATA_WIDTH	: positive := 32; 
  			dummy		: positive := 2);
  	port(InputA		: in 	STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
       	 InputB		: in 	STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
       	 Output		: out 	STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
         Operands	: in 	STD_LOGIC_VECTOR(3 downto 0));       
	end component ALU; 		 
	--------------------Adder to increment the PC--------------------
	component adder is 
	generic (DATA_WIDTH : natural := 32);
	port(input1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		 input2 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		 output : out std_logic_vector(DATA_WIDTH-1 downto 0));
	end component adder;
			
------------------------Signals declarations------------------------------	

signal program_counter: std_logic_vector(INSTR_ADDR_WIDTH-1 downto 0); --to be replaced with program counter register file
signal incremented_pc : std_logic_vector(INSTR_ADDR_WIDTH-1 downto 0);  		
--signal incremented_pc2 : std_logic_vector(INSTR_ADDR_WIDTH-1 downto 0);  

signal instr_dec_if : instr_dec_if_t;  	

signal instruction : instruction_t;	  
signal instruction_in : instruction_t;

signal reg_file_if: reg_file_if_t;	

signal cond_rf_if: condition_reg_file_if_t;

signal mux_1_if : mux_5_if_t;	
signal mux_2_if : mux_4_if_t;
signal mux_3_if : mux_32_if_t;
signal mux_4_if : mux_32_if_t;	
signal mux_5_if : mux_12_if_t;

signal alu_if : alu_32_if_t;

signal jump_address : std_logic_vector(ADDR_WIDTH-1 downto 0); 
signal imm_value	: std_logic_vector(ADDR_WIDTH-1 downto 0);

------------pipeline registers---------
signal ppreg_exe_in : pipeline_exe_t;
signal ppreg_mem_in : pipeline_mem_t;
signal ppreg_wb_in	 : pipeline_wb_t;  			

signal ppreg_exe : pipeline_exe_t;
signal ppreg_mem : pipeline_mem_t;
signal ppreg_wb	 : pipeline_wb_t;  
--------------------------------------------------------------------------	 
		  
begin

-----------------Components instances-------------------------------------

INSTR_DEC_INST: intruction_decoder
	port map(	rst			=> rst,	
				enable 		=> enable,
				opcode		=> instr_dec_if.opcode,
				cond_reg	=> instr_dec_if.cond_reg, 
				sync_reply	=> sync_reply,
				pc_ld 		=> instr_dec_if.pc_ld,
				wa_src  	=> instr_dec_if.wa_src,
				wr_en	 	=> instr_dec_if.wr_en,
				wcr_en		=> instr_dec_if.wcr_en,
				alu_op_src	=> instr_dec_if.alu_op_src,
				wb_src		=> instr_dec_if.wb_src,
				dm_wr		=> instr_dec_if.dm_wr,
				dm_rd		=> instr_dec_if.dm_rd,	 
				jmp			=> instr_dec_if.jmp,
				sync_req	=> sync_request,
				new_wrap	=> new_wrap_out);
				  
	--REG_FILE1_INST: block_memory	
--	generic map (ADDR_WIDTH => 5,
--				 DATA_WIDTH => WORD_WIDTH,
--				 CAPACITY   => 32)
--	port map(clk 	=> clk,
--			 rst  	=> rst,
--			 write_en   => reg_file_if.wr_en,
--			 read_en    => reg_file_if.rd_en,
--			 write_addr => reg_file_if.wr_addr,
--			 read_addr  => reg_file_if.rd_addr_1,
--			 write_data => reg_file_if.wr_data,
--			 read_data  => reg_file_if.rd_data_1);
	REG_FILE1_INST: reg_file
	generic map (ADDR_WIDTH => 5,
				 DATA_WIDTH => WORD_WIDTH,
				 CAPACITY   => 32)
	port map(clk 	=> clk,
			 rst  	=> rst,
			 write_en   => reg_file_if.wr_en,
			 write_addr => reg_file_if.wr_addr,
			 read_addr  => reg_file_if.rd_addr_1,
			 write_data => reg_file_if.wr_data,
			 read_data  => reg_file_if.rd_data_1); 
	
	REG_FILE2_INST: reg_file
	generic map (ADDR_WIDTH => 5,
				 DATA_WIDTH => WORD_WIDTH,
				 CAPACITY   => 32)
	port map(clk 	=> clk,
			 rst  	=> rst,
			 write_en   => reg_file_if.wr_en,
			 write_addr => reg_file_if.wr_addr,
			 read_addr  => reg_file_if.rd_addr_2,
			 write_data => reg_file_if.wr_data,
			 read_data  => reg_file_if.rd_data_2); 
			 
--	REG_FILE2_INST: block_memory	
--	generic map (ADDR_WIDTH => 5,
--				 DATA_WIDTH => WORD_WIDTH,
--				 CAPACITY   => 32)
--	port map(clk 	=> clk,
--			 rst  	=> rst,
--			 write_en   => reg_file_if.wr_en,
--			 read_en    => reg_file_if.rd_en,
--			 write_addr => reg_file_if.wr_addr,
--			 read_addr  => reg_file_if.rd_addr_2,
--			 write_data => reg_file_if.wr_data,
--			 read_data  => reg_file_if.rd_data_2);
			 
	COND_REG_FILE_INST: condition_register_file	 
	port map(clk => clk,
			 rst => rst,
			 wr_en 		 => cond_rf_if.wr_en,
			 wr_addr_pos => cond_rf_if.wr_addr_pos,
			 wr_addr_neg => cond_rf_if.wr_addr_neg,
			 rd_addr 	 => cond_rf_if.rd_addr,
			 wr_data_pos => cond_rf_if.wr_data_pos,
			 wr_data_neg => cond_rf_if.wr_data_neg,
			 rd_data 	 => cond_rf_if.rd_data);
		  
	MUX_1_INST: multiplexer2_1 									 
		generic map ( DATA_WIDTH => REGF_ADDR_WIDHT)
		port map( input1 => mux_1_if.in1,
				  input2 => mux_1_if.in2,
				  sel	 => mux_1_if.sel,
				  output => mux_1_if.output);
				  
	MUX_2_INST: multiplexer2_1 									 
		generic map ( DATA_WIDTH => ALUOP_WIDTH)
		port map( input1 => mux_2_if.in1,
				  input2 => mux_2_if.in2,
				  sel	 => mux_2_if.sel,
				  output => mux_2_if.output); 
				  
	MUX_3_INST: multiplexer2_1 									 
		generic map ( DATA_WIDTH => WORD_WIDTH)
		port map( input1 => mux_3_if.in1,
				  input2 => mux_3_if.in2,
				  sel	 => mux_3_if.sel,
				  output => mux_3_if.output);  
				  
	MUX_4_INST: multiplexer2_1 									 
		generic map ( DATA_WIDTH => WORD_WIDTH)
		port map( input1 => mux_4_if.in1,
				  input2 => mux_4_if.in2,
				  sel	 => mux_4_if.sel,
				  output => mux_4_if.output);  
				  
	MUX_5_INST: multiplexer2_1 									 
		generic map ( DATA_WIDTH => INSTR_ADDR_WIDTH)
		port map( input1 => mux_5_if.in1,
				  input2 => mux_5_if.in2,
				  sel	 => mux_5_if.sel,
				  output => mux_5_if.output);  	 
				  				  
	ALU_INST: alu
		generic map ( DATA_WIDTH => WORD_WIDTH)
		port map( InputA => alu_if.in1,
				  InputB => alu_if.in2,
				  Output => alu_if.output,
				  Operands => alu_if.operands);
				  	
	IMMVAL_BIT_EXT_INST: bit_extension										 
		generic map( INPUT_DATA_WIDTH =>15,
					 OUTPUT_DATA_WIDHT => 32) 
		port map( input => ppreg_exe.imm_val,
				  output => imm_value);
					
	JUMP_BIT_EXT_INST: bit_extension										 
		generic map( INPUT_DATA_WIDTH => 25,
					 OUTPUT_DATA_WIDHT => 32) 
		port map( input => instruction.jmp_addr,
				  output => jump_address);
		
	ADDER_INST: adder
	generic map (DATA_WIDTH => 12)
	port map(input1	=> program_counter,
			 input2 => X"001",
			 --input2(11 downto 1) => (others => '0'),
			 --input2(0)	=> '1',
			 output 	=> incremented_pc);
				  
-----------------Connections between components-------------------------------------

	instr_mem_address <= program_counter;

	instruction_in.pcr_addr <= instr_mem_read(31 downto 29);
	instruction_in.opcode   <= instr_mem_read(28 downto 25);
	instruction_in.rd_addr1 <= instr_mem_read(24 downto 20); 
	instruction_in.rw_addr2 <= instr_mem_read(19 downto 15);
	instruction_in.wr_addr  <= instr_mem_read(14 downto 10);
	instruction_in.alu_op   <= instr_mem_read(8 downto 5);-- when instr_mem_read(28-25) = "0010" else instr_mem_read(8 downto 5);
	instruction_in.imm_val  <= instr_mem_read(14 downto 0);
	instruction_in.jmp_addr <= instr_mem_read(24 downto 0);
	instruction_in.wcr_addr <= instr_mem_read(14 downto 9);	   
	instruction_in.wrap_id	 <= instr_mem_read(24 downto 19);
	instruction_in.wrap_prog<= instr_mem_read(11 downto 0);
	
	mux_1_if.in1 <= instruction.wr_addr;
	mux_1_if.in2 <= instruction.rw_addr2;  
	mux_1_if.sel <= instr_dec_if.wa_src;  
	
	cond_rf_if.wr_en 	   <= ppreg_wb.wcr_en;
	cond_rf_if.wr_addr_pos <= ppreg_wb.wcr_addr(5 downto 3);
	cond_rf_if.wr_addr_neg <= ppreg_wb.wcr_addr(2 downto 0);
	cond_rf_if.rd_addr     <= instruction.pcr_addr;
	cond_rf_if.wr_data_pos <= ppreg_wb.wb_data(0);
	cond_rf_if.wr_data_neg <= not ppreg_wb.wb_data(0);
	
	instr_dec_if.opcode 	<= instruction.opcode;
	instr_dec_if.cond_reg	<= cond_rf_if.rd_data;
	
	reg_file_if.rd_addr_1	<= instruction.rd_addr1;	
	reg_file_if.rd_addr_2	<= instruction.rw_addr2;	
	reg_file_if.wr_addr  	<= ppreg_wb.wb_addr;	
	reg_file_if.wr_data	 	<= ppreg_wb.wb_data;	
	--reg_file_if.rd_en	 	<= '1';	
	reg_file_if.wr_en 	 	<= ppreg_wb.wr_en;	
	
	mux_2_if.in1 <= instruction.alu_op;
	mux_2_if.in2 <= "0000";  
	mux_2_if.sel <= instr_dec_if.alu_op_src;	 
	
	mux_5_if.in1 <= incremented_pc;
	mux_5_if.in2 <= jump_address(11 downto 0);
	mux_5_if.sel <= instr_dec_if.jmp;
	--program_counter <= incremented_pc when instr_dec_if.jmp ='1' else jump_address(11 downto 0);
	
	ppreg_exe_in.wr_en 		<= instr_dec_if.wr_en;
	ppreg_exe_in.wcr_en 	<= instr_dec_if.wcr_en;
	ppreg_exe_in.alu_op_src <= instr_dec_if.alu_op_src;
	ppreg_exe_in.wb_src 	<= instr_dec_if.wb_src;	
	ppreg_exe_in.dm_wr 		<= instr_dec_if.dm_wr;
	ppreg_exe_in.dm_rd 		<= instr_dec_if.dm_rd;
	ppreg_exe_in.data1		<= reg_file_if.rd_data_1;
	ppreg_exe_in.data2		<= reg_file_if.rd_data_2;
	ppreg_exe_in.imm_val	<= instruction.imm_val;
	ppreg_exe_in.alu_op		<= mux_2_if.output;
	ppreg_exe_in.wb_addr	<= mux_1_if.output;
	ppreg_exe_in.wcr_addr	<= instruction.wcr_addr;
	
	mux_3_if.in1 <= ppreg_exe.data2;
	mux_3_if.in2 <= imm_value;
	mux_3_if.sel <= ppreg_exe.alu_op_src;
	
	alu_if.in1 <= ppreg_exe.data1;
	alu_if.in2 <= mux_3_if.output;
	alu_if.operands <= ppreg_exe.alu_op;	
	
	ppreg_mem_in.wr_en 		<= ppreg_exe.wr_en;
	ppreg_mem_in.wcr_en 	<= ppreg_exe.wcr_en;
	ppreg_mem_in.wb_src 	<= ppreg_exe.wb_src;
	--ppreg_mem_in.dm_wr		<= ppreg_exe.dm_wr;
	--ppreg_mem_in.dm_rd		<= ppreg_exe.dm_rd;
	ppreg_mem_in.alu_result <= alu_if.output;
	--ppreg_mem_in.data_to_mem<= ppreg_exe.data2;
	ppreg_mem_in.wb_addr	<= ppreg_exe.wb_addr;
	ppreg_mem_in.wcr_addr	<= ppreg_exe.wcr_addr;	
	
	data_mem_addr				 <= ppreg_mem_in.alu_result;
	data_mem_data_wr			 <= ppreg_exe.data2;
	data_mem_control.read_enable <= ppreg_exe.dm_rd;
	data_mem_control.write_enable<= ppreg_exe.dm_wr; 
	--data_mem_data_wr			 <= ppreg_mem_in.data_to_mem;
	--data_mem_control.read_enable <= ppreg_mem_in.dm_rd;
	--data_mem_control.write_enable<= ppreg_mem_in.dm_wr; 
	
	mux_4_if.in1 <= ppreg_mem.alu_result;
	mux_4_if.in2 <= data_mem_data_rd;
	mux_4_if.sel <= ppreg_mem.wb_src;
	  
	ppreg_wb_in.wr_en 	<= ppreg_mem.wr_en;
	ppreg_wb_in.wcr_en 	<= ppreg_mem.wcr_en;
	ppreg_wb_in.wb_data <= mux_4_if.output;
	ppreg_wb_in.wb_addr <= ppreg_mem.wb_addr;
	ppreg_wb_in.wcr_addr<= ppreg_mem.wcr_addr;
	
	PROGRAM_COUNTER_PROC: process(clk,instr_dec_if.jmp) is
	begin
		if rising_edge(clk)  then
			if rst = '1' then
				program_counter <= (others=>'0');
				--incremented_pc2 <= (others=>'0');
				ppreg_exe.wr_en 	<= '0';
				ppreg_exe.wcr_en 	<= '0';
				ppreg_exe.alu_op_src<= '0';
				ppreg_exe.wb_src 	<= '0';	
				ppreg_exe.dm_wr 	<= '0';
				ppreg_exe.dm_rd 	<= '0';
				ppreg_exe.data1		<= (others=>'0');
				ppreg_exe.data2		<= (others=>'0');
				ppreg_exe.imm_val	<= (others=>'0');
				ppreg_exe.alu_op	<= (others=>'0');
				ppreg_exe.wb_addr	<= (others=>'0');
				ppreg_exe.wcr_addr	<= (others=>'0');
				ppreg_mem.wr_en 	<= '0';
				ppreg_mem.wcr_en 	<= '0';
				ppreg_mem.wb_src 	<= '0';
				--ppreg_mem.dm_wr		<= '0';
				--ppreg_mem.dm_rd		<= '0';
				ppreg_mem.alu_result<= (others=>'0');
				--ppreg_mem.data_to_mem<= (others=>'0');
				ppreg_mem.wb_addr	<= (others=>'0');
				ppreg_mem.wcr_addr	<= (others=>'0'); 
				ppreg_wb.wr_en 	<= '0';
				ppreg_wb.wcr_en 	<= '0';
				ppreg_wb.wb_data <= (others=>'0');
				ppreg_wb.wb_addr <= (others=>'0');
				ppreg_wb.wcr_addr<= (others=>'0');
			elsif instr_dec_if.pc_ld = '1' then
				program_counter <= mux_5_if.output;
				--program_counter <= incremented_pc;
				ppreg_exe <= ppreg_exe_in;
				ppreg_mem <= ppreg_mem_in;
				ppreg_wb  <= ppreg_wb_in;
				instruction <= instruction_in;
			end if;
		 end if;
	end process;  
	  
		
end architecture behavior;
		
	
	