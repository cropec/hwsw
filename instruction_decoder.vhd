library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity intruction_decoder is
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
end entity intruction_decoder;

architecture instr_dec_behavior of intruction_decoder is

signal cycle_count : natural range 1 to 3:= 1;
signal cycle_reset : std_logic := '0';	  
signal cycle_enable: std_logic := '0'; 

constant NOP_OPCODE : std_logic_vector(3 downto 0) := "0000";
constant ALU_OPCODE : std_logic_vector(3 downto 0) := "0001";
constant CMP_OPCODE : std_logic_vector(3 downto 0) := "0010";
constant IADD_OPCODE: std_logic_vector(3 downto 0) := "0011";
constant LD_OPCODE  : std_logic_vector(3 downto 0) := "0100";
constant ST_OPCODE  : std_logic_vector(3 downto 0) := "0101";
constant JMP_OPCODE : std_logic_vector(3 downto 0) := "0110"; 
constant SYNC_OPCODE: std_logic_vector(3 downto 0) := "0111";
constant NW_OPCODE	: std_logic_vector(3 downto 0) := "1000";
  
begin	
	
	pc_ld 		<= '0' when rst = '1' or enable = '0' or cond_reg = '0' 
										or (opcode = SYNC_OPCODE and sync_reply = '0') else '1';
				
	wa_src		<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and (opcode = LD_OPCODE or opcode = IADD_OPCODE) else '0';	  

	wr_en		<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and (opcode = ALU_OPCODE or opcode = IADD_OPCODE or opcode =  LD_OPCODE) else '0';

	wcr_en 		<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = CMP_OPCODE else '0';

	alu_op_src 	<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and (opcode = LD_OPCODE or opcode = ST_OPCODE or opcode = IADD_OPCODE) else '0';

	wb_src		<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = LD_OPCODE else '0'; 

	dm_wr		<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = ST_OPCODE else '0';

	dm_rd		<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = LD_OPCODE else '0';

	jmp			<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = JMP_OPCODE else '0';

	sync_req	<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = SYNC_OPCODE else '0';
		
	new_wrap	<= '1' when rst = '0' and enable = '1' and cond_reg = '1' 
										and opcode = NW_OPCODE else '0';	
		
end architecture instr_dec_behavior;
		