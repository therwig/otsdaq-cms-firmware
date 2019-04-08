library S1CaloL2Algo;
library ieee;					  


use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;		 
use ieee.std_logic_misc.all;	   

	-- Add your library and packages declaration here ...

library work;
use work.tmux_params_pkg.all; 

--need entity for tb to compile...
entity algorithm_tb is
end algorithm_tb;

architecture TB_ARCHITECTURE of algorithm_tb is

    
    constant DATA_CLK_PERIOD : time := 8.333 ns; --120 MHz
    constant ALGO_CLK_PERIOD : time := 8.333 ns; --120 MHz
	
    signal data_clk : STD_LOGIC := '0';    
    signal algo_clk : STD_LOGIC := '0';        
    signal input_fiber_reader_reset : STD_LOGIC := '0';
        
    signal input_fiber_data : input_fiber_t (INPUT_FIBERS-1 downto 0);
    signal input_fiber_valid : STD_LOGIC_VECTOR(INPUT_FIBERS-1 downto 0);
		  
	signal output_fiber_data : output_fiber_t(OUTPUT_FIBERS-1 downto 0);	
    signal output_fiber_valid : STD_LOGIC_VECTOR(OUTPUT_FIBERS-1 downto 0);     
	
	 	 
	signal EOF_input_fiber : STD_LOGIC_VECTOR(INPUT_FIBERS-1 downto 0);		 	   	 
--	signal emulator_fiber_data,emulator_fiber_data_delay : STD_LOGIC_VECTOR(OUTPUT_FIBERS*32-1 downto 0);	   
--	signal EOF_EMULATOR, output_match : STD_LOGIC_VECTOR(OUTPUT_FIBERS-1 downto 0);		  	 
--	signal event_counter,event_counter2 : unsigned(7 downto 0) := (others => '0');	   
										
--	signal output_fiber_save_strobe : STD_LOGIC_VECTOR(OUTPUT_FIBERS-1 downto 0); 
	
--	signal et_ht_match : STD_LOGIC;		
	
	
	 	   	 
	
begin
	
--	tb_fiber_in_gen : for i in 0 to FIBER_PAIRS-1 generate  
		
--		tb_fiber_in(i*2) <= payload_even(i*32+31 downto i*32);
--		tb_fiber_in(i*2+1) <= payload_odd(i*32+31 downto i*32);
		
--	end generate;		   		   
	
--	process(data_clk)
--	begin		
--		if rising_edge(data_clk) and data_valid_even(0) = '1' then
--			tb_fiber_frame <= tb_fiber_frame + 1;
--		end if;
		
		
--	end process;
	
	
	
	
--	-- Unit Under Test port map
--	UUT : algorithm
--		port map (
--			data_clk => data_clk,	
--			algo_clk => algo_clk,
--			ipb_clk => ipb_clk,	  
--			ipb_reset => ipb_reset,	
--			data_rst => data_rst,
--			ipb_strobe => ipb_strobe,
--			ipb_we => ipb_we,		   
--			data_valid_even => data_valid_even,-- when inputBlock = '0' else (others => '0'),
--			data_valid_odd => data_valid_odd,	
--			start_event_even => start_event_even,
--			start_event_odd => start_event_odd,		   
--			ipb_addr => ipb_addr,	
--			ipb_wdata => ipb_wdata,			 
--			ipb_rdata => ipb_rdata,	  		 
--			ipb_ack => ipb_ack,		  		 
--			ipb_err => ipb_err,
--			payload_even => payload_even,
--			payload_odd => payload_odd,					 
--			output_fiber_valid => output_fiber_valid,	 
--			output_fiber_start => output_fiber_start,		 
--			output_fiber_strobe => output_fiber_strobe,
--			output_fiber_data => output_fiber_data
--		);

	-- Add your stimulus here ...					
																							   	
	data_clk <= not data_clk after DATA_CLK_PERIOD/2;	   
	algo_clk <= not algo_clk after ALGO_CLK_PERIOD/2;
	
	stimulator_process: process
	begin
        wait for DATA_CLK_PERIOD*4;
        input_fiber_reader_reset <= '1';
        wait for DATA_CLK_PERIOD*4;
        input_fiber_reader_reset <= '0';
        wait; --forever
    end process;
	   
	
	sim_fiber_reader_array: for fiber_index in 0 to INPUT_FIBERS-1 generate
					
					   
		sim_fiber_reader_entity: entity work.FILE_READ
			generic map(
				stim_file => "/home/rrivera/CorrelatorTrigger/tmux_wrapper/sim_tmux_wrapper/sim/sim_data/sim_input_fiber_"&integer'image(fiber_index)&".dat",
				BIT_WIDTH => INPUT_WORD_SIZE
			)
			port map(
				CLK  => data_clk,
				RST => input_fiber_reader_reset,
				Y  => input_fiber_data(fiber_index), 
				VALID => input_fiber_valid(fiber_index),
				EOG => EOF_input_fiber(fiber_index)
			);	 		
			
	end generate;		
			 
			 
    tmux_wrapper_entity: entity work.tmux_wrapper
        port map(
            CLK  => data_clk,
            RST => input_fiber_reader_reset,
            INPUT_DATA => input_fiber_data,
            INPUT_DATA_VALID => input_fiber_valid,
            INPUTS_TO_ALGO => open
            );
         
	
--	sim_output_writer_array: for fiber_index in 0 to OUTPUT_FIBERS-1 generate   
	
--		sim_output_writer_array: entity work.FILE_WRITE
--			generic map(
--				output_file => "src/TestBench/output_fiber_"&integer'image(fiber_index)&".dat",
--				BIT_WIDTH => 32
--			)
--			port map(
--				CLK  => output_fiber_save_strobe(fiber_index),
--				RST => payload_reader_reset,
--				D => output_fiber_data(fiber_index*32+31 downto fiber_index*32),
--				EOG => '0'
--			);	 													 
			
--	end generate;		
	
	
--	emulator_output_reader_array: for fiber_index in 0 to OUTPUT_FIBERS-1 generate   
--	begin
--		sim_output_writer_array: entity work.FILE_READ
--			generic map(
--				stim_file => "TestBench/emulator_output_fiber_"&integer'image(fiber_index)&".dat",
--				BIT_WIDTH => 32
--			)
--			port map(
--				CLK  => output_fiber_save_strobe(fiber_index),
--				RST => ipb_reset,
--				Y => emulator_fiber_data(fiber_index*32+31 downto fiber_index*32),
--				EOG => EOF_EMULATOR(fiber_index)
--			);	 													 
		
--			output_fiber_save_strobe(fiber_index) <= data_clk_delay and output_fiber_strobe(fiber_index) and output_fiber_valid(fiber_index);
--	end generate;		 	
	
--	--compare emulator and simulation output fibers
--	process(data_clk)
--	begin			 	  
--		if rising_edge(data_clk) then
--			emulator_fiber_data_delay <= emulator_fiber_data;	 
--			if(output_fiber_strobe(0) = '1' and output_fiber_valid(0) = '1') then
--				event_counter <= event_counter + 1;
--			end if;							 	 
--			if(output_fiber_strobe(2) = '1' and output_fiber_valid(2) = '1') then
--				event_counter2 <= event_counter2 + 1;
--			end if;							 				
--		end if;
--	end process;
	
--	emulator_match_array: for fiber_index in 0 to OUTPUT_FIBERS-1 generate
--		process(output_fiber_data(fiber_index*32+31 downto fiber_index*32),emulator_fiber_data_delay(fiber_index*32+31 downto fiber_index*32))
--		begin
			
			
				
				
			
--			if(emulator_fiber_data_delay(fiber_index*32+31 downto fiber_index*32) = 
--				output_fiber_data(fiber_index*32+31 downto fiber_index*32))	 then
--				output_match(fiber_index)  <= '1';
			
--			else 
--				output_match(fiber_index)  <= '0';
--			end if;
--		end process;
--	end generate;
	
	
--	process(output_fiber_data(4*32+31 downto 4*32),emulator_fiber_data_delay(4*32+31 downto 4*32))
--	begin					  
--				if(emulator_fiber_data_delay(4*32+15 downto 4*32) = 
--					output_fiber_data(4*32+15 downto 4*32))	 then
--					et_ht_match <= '1';
--				else
--					et_ht_match <= '0';				
--				end if;	
					   
--	end process;
	
	
	

end TB_ARCHITECTURE;

--configuration TESTBENCH_FOR_algorithm of algorithm_tb is
--	for TB_ARCHITECTURE
--		for UUT : algorithm
--			use entity work.algorithm(algorithm);
--		end for;
--	end for;
--end TESTBENCH_FOR_algorithm;

