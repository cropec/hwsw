library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

package interfaces is 
									 						 	
	subtype instr_mem_read_t 	is std_logic_vector(31 downto 0);	 	
	subtype instr_mem_address_t is std_logic_vector(11 downto 0); 
		
	subtype data_mem_address_t 	is std_logic_vector(31 downto 0);
	subtype data_mem_data_wr_t 	is std_logic_vector(31 downto 0);
	subtype data_mem_data_rd_t	is std_logic_vector(31 downto 0);
	type 	data_mem_control_t 	is record
		read_enable : std_logic;
		write_enable: std_logic;
	end record data_mem_control_t;
	
	
	type instr_dec_if_t is record
		opcode		: std_logic_vector(3 downto 0);
		cond_reg	: std_logic;	--value from the predicated cond reg
		pc_ld 		: std_logic; 	--load program counter
		wa_src		: std_logic;    --write address source
		wr_en	 	: std_logic;	--write register enable
		wcr_en		: std_logic;	--write condition register enable
		--rd_en		: std_logic;	--read register enable
		alu_op_src	: std_logic;	--alu operation/2nd operand source
		wb_src		: std_logic;	--write back data source
		dm_wr		: std_logic;	--data memory write enable
		dm_rd	 	: std_logic;	--data memory read enable
		jmp			: std_logic;	--jump operation
		sync_req	: std_logic;	--sync cmd signal
		new_wrap	: std_logic;	--new wrap cmd signal
	end record instr_dec_if_t;
		
	type instruction_t is record	 
		pcr_addr : std_logic_vector(2 downto 0);	--predicated cond reg addr
		opcode   : std_logic_vector(3 downto 0); 	--the opcode of the instruction
		rd_addr1 : std_logic_vector(4 downto 0);	--read address 1 from the reg file
		rw_addr2 : std_logic_vector(4 downto 0);	--read address 2/write address from/to the reg file
		wr_addr	 : std_logic_vector(4 downto 0);    --write address from to register file
		alu_op   : std_logic_vector(3 downto 0);	--alu operands
		imm_val  : std_logic_vector(14 downto 0); 	--immediate value for a load, store or immediate add instruction
		jmp_addr : std_logic_vector(24 downto 0); 	--jump address
	    wcr_addr : std_logic_vector(5 downto 0);	--addresses of the condition registers to be written
		wrap_id	 : std_logic_vector(5 downto 0);    --the id of the wrap to be initialized
		wrap_prog: std_logic_vector(11 downto 0);	--the starting address in the instruction mem of the program exe by wrap with wrap_id
	end record instruction_t;		
	   	
	type reg_file_if_t is record
		rd_addr_1	: std_logic_vector(4 downto 0);
		rd_addr_2	: std_logic_vector(4 downto 0);
		wr_addr 	: std_logic_vector(4 downto 0);
		rd_data_1	: std_logic_vector(31 downto 0);
		rd_data_2	: std_logic_vector(31 downto 0);
		wr_data		: std_logic_vector(31 downto 0);
		--rd_en		: std_logic;
		wr_en 		: std_logic;
	end record reg_file_if_t; 
	
	type condition_reg_file_if_t is record	  
		wr_en		: std_logic;
		wr_addr_pos	: std_logic_vector(2 downto 0);
		wr_addr_neg	: std_logic_vector(2 downto 0);
		rd_addr  	: std_logic_vector(2 downto 0);
		wr_data_pos	: std_logic;
		wr_data_neg	: std_logic;
		rd_data 	: std_logic;
	end record condition_reg_file_if_t;
	
	type mux_32_if_t is record
		in1	: std_logic_vector(31 downto 0);
		in2 : std_logic_vector(31 downto 0);
		output : std_logic_vector(31 downto 0);
		sel : std_logic;
	end record mux_32_if_t;   
	
	type mux_5_if_t is record
		in1	: std_logic_vector(4 downto 0);
		in2 : std_logic_vector(4 downto 0);
		output : std_logic_vector(4 downto 0);
		sel : std_logic;
	end record mux_5_if_t; 
	
	type mux_4_if_t is record
		in1	: std_logic_vector(3 downto 0);
		in2 : std_logic_vector(3 downto 0);
		output : std_logic_vector(3 downto 0);
		sel : std_logic;
	end record mux_4_if_t;	
	
	type mux_12_if_t is record
		in1	: std_logic_vector(11 downto 0);
		in2 : std_logic_vector(11 downto 0);
		output : std_logic_vector(11 downto 0);
		sel : std_logic;
	end record mux_12_if_t;
	
	type alu_32_if_t is record
		in1	: std_logic_vector(31 downto 0);
		in2 : std_logic_vector(31 downto 0);
		output : std_logic_vector(31 downto 0);	 
		operands: std_logic_vector(3 downto 0);
	end record alu_32_if_t;	   
	
	type adder_32_if_t is record
		in1	: std_logic_vector(31 downto 0);
		in2 : std_logic_vector(31 downto 0);
		output : std_logic_vector(31 downto 0);	
	end record adder_32_if_t;		 
	
	type condition_register_t is array(7 downto 0) of std_logic ;
	type condition_register_file_t is array(63 downto 0) of condition_register_t;		
	
	--------------------------------------------------------------------------
	-- pipeline_exe_t: the inteface to the pipeline register that holds the --
	-- 				   information needed during the execution stage		--
	--				  -99 bits	(98 downto 0)								--
	--------------------------------------------------------------------------
	
	type pipeline_exe_t is record			
		wr_en			: std_logic;	-- 98
		wcr_en			: std_logic;    -- 97
		alu_op_src		: std_logic;	-- 96
		wb_src			: std_logic;	-- 95
		dm_wr			: std_logic;	-- 94
		dm_rd			: std_logic;	-- 93 
		data1			: std_logic_vector(31 downto 0);  -- 92 downto 61
		data2			: std_logic_vector(31 downto 0);  -- 60 downto 29
		imm_val			: std_logic_vector(14 downto 0);  -- 28 downto 15
		alu_op			: std_logic_vector(3 downto 0);	  -- 14 downto 11
		wb_addr			: std_logic_vector(4 downto 0);	  -- 10 downto 6
		wcr_addr		: std_logic_vector(5 downto 0);	  -- 5 downto 0
	end record pipeline_exe_t;  
	
	--------------------------------------------------------------------------
	-- pipeline_mem_t:-the inteface to the pipeline register that holds the --
	-- 				   information needed during the memory stage			-- 
	--				 -80 bits	(79 downto 0)								-- //after changes 48 bits
	--------------------------------------------------------------------------
	
	type pipeline_mem_t is record		
		wr_en			: std_logic; --79
		wcr_en			: std_logic; --78
		wb_src			: std_logic; --77
		--dm_wr			: std_logic; --76
		--dm_rd			: std_logic; --75
		alu_result		: std_logic_vector(31 downto 0);--74 dwonto 43
		--data_to_mem		: std_logic_vector(31 downto 0);--42 downto 11
		wb_addr			: std_logic_vector(4 downto 0);	--10 downto 6
		wcr_addr		: std_logic_vector(5 downto 0);	--5 downto 0
	end record pipeline_mem_t; 
	
	--------------------------------------------------------------------------
	-- pipeline_wb_t:-the inteface to the pipeline register that holds the 	--
	-- 				  information needed during the write back stage		--
	--				 -43 bits (42 downto 0)									--
	--------------------------------------------------------------------------
	
	type pipeline_wb_t is record		
		wr_en			: std_logic; --44
		wcr_en			: std_logic; --43
		wb_data			: std_logic_vector(31 downto 0); --42 downto 11
		wb_addr			: std_logic_vector(4 downto 0);	 --10 downto 6
		wcr_addr			: std_logic_vector(5 downto 0);	 --5 downto 0
	end record pipeline_wb_t;
	
end package interfaces;	   

