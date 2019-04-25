							  
library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use work.txt_util.all;
 
 
entity FILE_READ is
  generic (
  	stim_file:      string  := "sim_energy_table.dat"; 
  	BIT_WIDTH:		integer := 5
          );
  port(
       CLK              : in  std_logic;
       RST              : in  std_logic;
       Y                : out std_logic_vector(BIT_WIDTH-1 downto 0);
       VALID            : out std_logic;
       EOG              : out std_logic
      );
end FILE_READ;

 
-- I/O Dictionary
--
-- Inputs:
--
-- CLK:              new cell needed
-- RST:              reset signal, wait with reading till reset seq complete
--   
-- Outputs:
--
-- Y:                Output vector
-- EOG:              End Of Generation, all lines have been read from the file
--
   
   
architecture read_from_file of FILE_READ is
  
  
    file stimulus: TEXT open read_mode is stim_file; 
	
	constant VALID_SIZE : integer := 4;
	
	signal Y_sig : std_logic_vector(BIT_WIDTH - 1 + VALID_SIZE downto 0) := (others => '0');
	

begin
	
	Y <= Y_sig(BIT_WIDTH-1 downto 0);
									   
	-- read data and control information from a file
	
	receive_data: process
									  
		variable s: string(BIT_WIDTH + VALID_SIZE downto 1);--y'range);
		
		variable Y_var : std_logic_vector(BIT_WIDTH - 1 + VALID_SIZE downto 0);
	   
	begin                                       
	
		EOG <= '0';
		
		VALID <= '0';
		
		-- wait for Reset to complete
		wait until RST='1';
		wait until RST='0';		
		wait until CLK = '1';		  
		while not endfile(stimulus) loop
		
			-- read digital data from input file  	 
			str_read(stimulus,s);		
			Y_var    := hex_to_std_logic_vector(s);	
			Y_sig    <= Y_var;
			VALID    <= Y_var(BIT_WIDTH); --'1';  -- valid from data or not
			wait until CLK = '1';
		
		end loop;
        VALID <= '0';															   
		EOG <= '1';				  
		wait;
	
	 end process receive_data;			

end read_from_file;
 