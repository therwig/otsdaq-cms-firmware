							  
library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use work.txt_util.all;
 
 
entity FILE_WRITE is
  generic (
  	output_file:      string  := "sim_output.dat"; 
  	BIT_WIDTH:		integer := 5
          );
  port(
       CLK              : in  std_logic;
       RST              : in  std_logic;
       VALID            : in  std_logic;
       D                : in  std_logic_vector(BIT_WIDTH-1 downto 0);
       EOG              : in  std_logic
      );
end FILE_WRITE;

 
-- I/O Dictionary
--
-- Inputs:
--
-- CLK:              new cell needed
-- RST:              reset signal, wait with reading till reset seq complete   
-- D:                Input vector
-- EOG:              End Of Generation, all lines have been writte, close file
--
   
   
architecture write_to_file of FILE_WRITE is
  
  
    file fp: TEXT open write_mode is output_file;


begin



-- read data and control information from a file

	receive_data: process
		
		variable l: line;
		variable s: string(1 to (D'left+4)/4);
	
	begin                                       
										
		-- wait for Reset to complete
		wait until RST='1';
		wait until RST='0';
		
		
		while EOG = '0' loop				   
		   
			wait until CLK = '1';	 
			 
			-- write data to output file 	
			if(VALID = '1') then 
                s := hstr(D);
                print(fp,s);		
            end if;
		
		end loop;
		
		print("I@FILE_WRITE: finished writing "& output_file);	 
		
		wait;
	
	end process receive_data;



end write_to_file;
 