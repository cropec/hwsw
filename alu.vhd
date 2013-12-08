library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity ALU is
  generic(	DATA_WIDTH	: positive := 32; 
  			dummy		: positive := 2);
  Port (InputA		: in 	STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
       	InputB		: in 	STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
       	Output		: out 	STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
       	Operands	: in 	STD_LOGIC_VECTOR(3 downto 0));       
end ALU;

architecture Behavioral of ALU is

begin
  
  ALU_PROCESS: process (InputA, InputB, Operands) is
  begin
	
	  case Operands is
	    
	  when "0000" => --Addition
	      Output <= STD_LOGIC_VECTOR(UNSIGNED(InputA) + UNSIGNED(InputB));
	      
	  when "0001" => --Subtraction
	      Output <= STD_LOGIC_VECTOR(UNSIGNED(InputA) - UNSIGNED(InputB));
	      
	  when "0010" => --Logic AND
	      Output <= InputA and InputB;
	      
	  when "0011" => --Logic OR
	      Output <= InputA or InputB;
	      
	  when "0100" => --Logic XOR
	      Output <= InputA xor InputB;
	      
	  when "0101" => --Arithmetic Shift Right
	      Output(DATA_WIDTH-2 downto 0) <= InputA(DATA_WIDTH-1  downto 1);
	      Output(DATA_WIDTH-1) <= InputA(DATA_WIDTH-1);
	      
	  when "0110" => --Logic Shift Right
	      Output(DATA_WIDTH-2 downto 0) <= InputA(DATA_WIDTH-1  downto 1);
	      Output(DATA_WIDTH-1) <= '0';
	      
	  when "0111" => -- Logic Shift Left
	      Output(DATA_WIDTH-1  downto 1) <= InputA(DATA_WIDTH-2 downto 0);
	      Output(0) <= '0';
	      
	  when "1000" => -- Compare if equal
	      if InputA = InputB then
	        Output(DATA_WIDTH-1 downto 1) <= (OTHERS => '0');
	       Output(0) <= '1';
	      else
	        Output(DATA_WIDTH-1 downto 0) <=(OTHERS => '0');
	      end if;
	                 
	  when "1001" => -- Compare if not equal
	      if InputA /= InputB then
	        Output(DATA_WIDTH-1 downto 1) <= (OTHERS => '0');
	        Output(0) <= '1';
	      else
	        Output(DATA_WIDTH-1 downto 0) <=(OTHERS => '0');
	      end if;
	  
	  when "1010" => --Compare if A lesser then B    
	      if InputA < InputB then
	        Output(DATA_WIDTH-1 downto 1) <= (OTHERS => '0');
	        Output(0) <= '1';
	      else
	        Output(DATA_WIDTH-1 downto 0) <=(OTHERS => '0');
	      end if;
	      
	  when "1011" => --Compare if A greater then B
	      if InputA > InputB then
	        Output(DATA_WIDTH-1 downto 1) <= (OTHERS => '0');
	        Output(0) <= '1';
	      else
	        Output(DATA_WIDTH-1 downto 0) <=(OTHERS => '0');
	      end if;
	      
	  when others =>
	      Output(DATA_WIDTH-1 downto 0) <= (OTHERS => '0');
	      
	  end case;
  
	 end process ALU_PROCESS;
  
end Behavioral;
  