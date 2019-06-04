library S1CaloL2Algo;
library ieee;					  


use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;		 
use ieee.std_logic_misc.all;	   

	-- Add your library and packages declaration here ...

library work;
use work.regionizer_pkg.all; 
use work.algo_pkg.all;

--need entity for tb to compile...
entity regionizer_tb is
end regionizer_tb;

architecture TB_ARCHITECTURE of regionizer_tb is

    component FILE_READ 
        generic (
                stim_file           : string  := "sim_energy_table.dat"; 
                BIT_WIDTH           : integer := 5
              );
        port(
                CLK                 : in  std_logic;
                RST                 : in  std_logic;
                Y                   : out std_logic_vector(BIT_WIDTH-1 downto 0);
                VALID               : out std_logic;
                EOG                 : out std_logic
              );
    end component FILE_READ;
        
    component FILE_WRITE
        generic (
            output_file:      string  := "sim_output.dat"; 
            BIT_WIDTH:        integer := 5
              );
        port(
            CLK              : in  std_logic;
            RST              : in  std_logic;
            VALID            : in  std_logic;
            D                : in  std_logic_vector(BIT_WIDTH-1 downto 0);
            EOG              : in  std_logic
            );
    end component FILE_WRITE;
    
    
    component regionizer_wrapper 
    port(
      
            link_clk            : in  std_logic;
            
            algo_in_debug       : out raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
            algo_in_vertex_debug: out std_logic_vector(VERTEX_BIT_WIDTH-1 downto 0);
            algo_in_valid_debug : out std_logic;
            
            algo_out_debug      : out raw_algo_object_out_arr_t(ALGO_OBJECTS_OUT-1 downto 0);
            algo_out_valid_debug: out std_logic;
            
            -- Input Links 
            link_in_master      : in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_in_slave       : out LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
            
            -- Output Links 
            link_out_master     : out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_out_slave      : in  LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
        
            algo_reset          : in  std_logic;
            reset               : in  std_logic
    
        );
    end component regionizer_wrapper;
    
    
        
    constant DATA_CLK_PERIOD : time := 8.333 ns; --120 MHz
	
    signal data_clk : STD_LOGIC := '0'; 
    signal system_reset : STD_LOGIC := '0'; --reset things on link clock
    signal algo_reset : STD_LOGIC := '0';   --reset things on algo clock     
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
	
	
	
    signal link_in_master       : LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
    signal link_in_slave        : LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
    
    signal link_out_master      : LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
    signal link_out_slave       : LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
    --signal link_out_master2 : LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
    --signal link_out_slave2  : LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
	 	   	 
	signal has_reset            : std_logic := '0';
	
	signal algo_in              : raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
    signal algo_in_vertex       : std_logic_vector(VERTEX_BIT_WIDTH-1 downto 0);
    signal algo_in_valid        : std_logic;
            
    signal algo_out             : raw_algo_object_out_arr_t(ALGO_OBJECTS_OUT-1 downto 0);
    signal algo_out_valid       : std_logic;
	
begin
					
																							   	
	data_clk <= not data_clk after DATA_CLK_PERIOD/2;	
	
	stimulator_process: process
	begin
        wait for DATA_CLK_PERIOD*4;
        
        system_reset                <= '1';
        algo_reset                  <= '1';
        input_fiber_reader_reset    <= '1';
        
        wait for DATA_CLK_PERIOD*4;
        
        system_reset                <= '0';
        
        wait for DATA_CLK_PERIOD*4*40;
        
        has_reset                   <= '1';
        algo_reset                  <= '0';
        input_fiber_reader_reset    <= '0';
        
        wait; --forever
    end process;
	   
	
	sim_fiber_reader_array: for fiber_index in 0 to INPUT_FIBERS-1 generate
					
					   
		sim_fiber_reader_entity: FILE_READ
			generic map(
				stim_file => "/data/rrivera/CorrelatorTrigger/puppi_regionizer_repo/otsdaq-cms-firmware/regionizer_full/sim/sim_data/sim_input_fiber_"&integer'image(fiber_index)&".dat",
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
			 
    gen_sim_fiber_type: for fiber_index in 0 to INPUT_FIBERS-1 generate
        link_in_master(fiber_index).tValid <= input_fiber_valid(fiber_index);
        link_in_master(fiber_index).tData <= input_fiber_data(fiber_index);
--        process(data_clk)
--        begin
--            link_in_master(fiber_index).tLast <= link_in_master(fiber_index).tValid;  
--        end process;
    end generate; 
            
    gen_sim_fiber_type_unused: for fiber_index in INPUT_FIBERS to MAX_FIBER_COUNT-1 generate        
        link_in_master(fiber_index).tValid <= '0';
        link_in_master(fiber_index).tData <= (others => '0');
        --link_in_master(fiber_index).tLast <= '0';
    end generate;
			 
			 
    regionizer_wrapper_entity: regionizer_wrapper
        port map(            
            link_clk                => data_clk,        --: in  std_logic;
                    
            algo_in_debug           => algo_in,         --: out raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
            algo_in_vertex_debug    => algo_in_vertex,  --: out std_logic_vector(VERTEX_BIT_WIDTH-1 downto 0);
            algo_in_valid_debug     => algo_in_valid,   --: out std_logic;
            
            algo_out_debug          => algo_out,        --: out raw_algo_object_out_arr_t(ALGO_OBJECTS_OUT-1 downto 0);
            algo_out_valid_debug    => algo_out_valid,  --: out std_logic;
            
            -- Input Links 
            link_in_master          => link_in_master,  --: in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_in_slave           => link_in_slave,   --: out LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
            
            -- Output Links 
            link_out_master         => link_out_master, --: out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_out_slave          => link_out_slave,  --: in  LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
        
            algo_reset              => algo_reset,      --: in  std_logic;
            reset                   => system_reset     --: in  std_logic
            );
           
         
    -- ========================= 
     gen_algo_in_output : if TRUE generate
        
         -- ========================= 
        gen_vertex_in_output : if TRUE generate          
          sim_HLSinput_writer_array: FILE_WRITE
                      generic map(
                          output_file   => "/data/rrivera/CorrelatorTrigger/puppi_regionizer_repo/otsdaq-cms-firmware/regionizer_full/sim/sim_data/sim_HLS_input_vertex.dat",                          
                          BIT_WIDTH     => VERTEX_BIT_WIDTH
                      )
                      port map(
                          CLK  => data_clk,
                          VALID => algo_in_valid,
                          RST => input_fiber_reader_reset,
                          D => algo_in_vertex,
                          EOG => '0'
                      );
        end generate gen_vertex_in_output;
        
        -- ========================= 
        gen_object_in_output : for i in 0 to ALGO_INPUT_OBJECTS_COUNT-1 generate
            
          sim_HLSinput_writer_array: FILE_WRITE
                      generic map(
                          output_file   => "/data/rrivera/CorrelatorTrigger/puppi_regionizer_repo/otsdaq-cms-firmware/regionizer_full/sim/sim_data/sim_HLS_input_object_"&integer'image(i)&".dat",                          
                          BIT_WIDTH     => PHYSICS_OBJECT_BIT_SIZE
                      )
                      port map(
                          CLK  => data_clk,
                          VALID => algo_in_valid,
                          RST => input_fiber_reader_reset,
                          D => algo_in(i),
                          EOG => '0'
                      );
        end generate gen_object_in_output;
        
    end generate gen_algo_in_output;
                          
--	sim_output_writer_array: for fiber_index in 0 to OUTPUT_FIBERS-1 generate   
	
--		sim_output_writer_array: entity work.FILE_WRITE
--			generic map(
--				output_file => "/data/rrivera/CorrelatorTrigger/otsdaq-cms-firmware/tmux_regionizer/sim/sim_data/sim_output_fiber_"&integer'image(fiber_index)&".dat",
--				BIT_WIDTH => OUTPUT_WORD_SIZE
--			)
--			port map(
--				CLK  => data_clk,
--				VALID => link_out_master(fiber_index).tValid,
--				RST => input_fiber_reader_reset,
--				D => link_out_master(fiber_index).tData,
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

--configuration TESTBENCH_FOR_algorithm of regionizer_tb is
--	for TB_ARCHITECTURE
--		for UUT : algorithm
--			use entity work.algorithm(algorithm);
--		end for;
--	end for;
--end TESTBENCH_FOR_algorithm;

