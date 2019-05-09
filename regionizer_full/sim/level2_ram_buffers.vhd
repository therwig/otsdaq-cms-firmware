----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level2_ram_buffers - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.regionizer_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



----------------------------------------------------------------------------------


entity level2_ram_buffers is
    generic (
        SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM
    );
    port ( 
        clk_level1_to_2         : in  std_logic;
        clk_level2_to_algo      : in  std_logic;
            
        level1_big_region_end   : in  std_logic_vector(FIBER_GROUPS-1 downto 0);
        
        object_pipe_in          : in  level1_to_2_global_pipe_t;
        
        small_region_closed     : out std_logic_vector(SMALL_REGION_COUNT-1 downto 0);  
        next_big_region         : out std_logic_vector(FIBER_GROUPS-1 downto 0);
        
        robjects_re             : in  std_logic;
        robjects_out_valid      : out std_logic;
        robjects_out            : out physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
        
        -- overflow not possible.. overflow_error          : out std_logic;
        reset                   : in  std_logic
    );
end level2_ram_buffers;

architecture Behavioral of level2_ram_buffers is

    component level2_ram_buffer
        generic (
            SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM;
            PARALLEL_OBJECT_RAMS    : integer := LEVEL2_PARALLEL_OBJECT_RAMS;
            OBJECTS_TO_ALGO         : integer := 25
        );
        port ( 
            clk_level1_to_2         : in  std_logic;
            clk_level2_to_algo      : in  std_logic;
            
            level1_big_region_end   : in  std_logic;
            
            object_pipe_in          : in  level1_to_2_pipe_t;
            
            next_big_region         : out std_logic;
            small_region_closed     : out std_logic_vector(SMALL_REGIONS_PER_RAM-1 downto 0);  
            
            robjects_re             : in  std_logic;
            robjects_out_valid      : out std_logic;
            robjects_out            : out physics_object_arr_t(PARALLEL_OBJECT_RAMS-1 downto 0);
            
            -- overflow not possible.. overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level2_ram_buffer;
    
    type level2_out_pipe_t is record
        valid   : std_logic;
        objects : physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
    end record level2_out_pipe_t;
    type level2_out_pipe_arr_t is array(natural range <> ) of level2_out_pipe_t;
    
    signal level2_out_pipes : level2_out_pipe_arr_t(2 downto 0);
     
begin

    --  This is the Level-2 multiram buffer container to instantiate group, detector 
    --      shared small-region buffers.
    --
    --      e.g. SMALL_REGIONS_PER_RAM = 3 and PARALLEL_OBJECT_RAMS = 5
    --          then this container would consist of 18/3 = 6 shared small-region buffers that each
    --              handle 3 small-regions, and stack objects for those small-regions in
    --              5 parallel RAMs.
    --
    --      Inputs come from a Level-1 FIFO stage.. one FIFO for each link for the detector
    --      Outputs go to the HLS algo, e.g. 25 objects for Tracker per small-region
    --
    -- =====
    -- Read behavior:
    --  Once a big-region is fully written to Level-2,
    --      small-regions are prepared to be handed to the algo every two clocks
    --      
    --      e.g. if it takes 5 clocks to read the full input object size from the parallel sub-buffers
    --          then 3 small-regions will have to co-exist in shift-register pipeline on the way out 
    --          of Level-2 to the algo.
    

    robjects_out_valid          <= robjects_re; -- unnecessary and_reduce(all valids)

    -- ==========================================================================================
    -- generate Tracker Level-2 buffers
    level2_tracker_buffer_gen : if TRUE generate
        constant DETECTOR_OBJECTS_TO_ALGO   : integer := 25;   
        constant SHARED_SMALL_REGION_RAMS   : integer := SMALL_REGION_COUNT/SMALL_REGIONS_PER_RAM;    
    begin
    
        -- ==========================================================================================
        level2_tracker_buffer_group_gen : for g in 0 to FIBER_GROUPS-1 generate
                
            type debug_count_arr_t is array(integer range <>) of integer;
            signal debug_pipe_valid_count   : debug_count_arr_t(SHARED_SMALL_REGION_RAMS-1 downto 0) := (others => 0);
        begin                    
        
            
            next_big_region(g)          <= level1_big_region_end(g); -- Note: should be on clk_level1_to_2
        
            -- ==========================================================================================
            level2_tracker_buffer_multiram_gen : for i in 0 to SHARED_SMALL_REGION_RAMS-1 generate
            begin
            
                --=============
                debug_count_process : process(clk_level1_to_2)
                begin
                    if(rising_edge(clk_level1_to_2)) then
                    
                        if (reset = '1') then
                            debug_pipe_valid_count(i) <= 0;
                        elsif (object_pipe_in(g).tracker_pipe(i).valid = '1') then
                            debug_pipe_valid_count(i) <= debug_pipe_valid_count(i) + 1;
                        end if; 
                    
                    end if;            
                end process debug_count_process;
                
                --=============
                layer2_tracker_buffer: level2_ram_buffer
                    generic map (
                        OBJECTS_TO_ALGO                 => DETECTOR_OBJECTS_TO_ALGO  
                    )
                    port map (
                        clk_level1_to_2                 => clk_level1_to_2,             --: in  std_logic;
                                
                        level1_big_region_end           => level1_big_region_end(g),    --: in  std_logic;
                        
                        object_pipe_in                  => object_pipe_in(g).tracker_pipe(i),   --: in  level1_to_2_pipe_t;
                        
                        next_big_region                 => open,                        --: out std_logic;
                        small_region_closed             => small_region_closed((i+1)*2-1 downto i*2),   --: out std_logic_vector(SMALL_REGION_COUNT-1 downto 0);  
                        
                        robjects_re                     => '0',                         --: in  std_logic;
                        robjects_out_valid              => open,                        --: out std_logic;
                        robjects_out                    => open,                        --: out physics_object_arr_t(PARALLEL_OBJECT_RAMS-1 downto 0);  
                
                        reset                           => reset
                    );    
                --end tracker buffer component
                                                     
            end generate level2_tracker_buffer_multiram_gen;
            
            
            -- ==========================================================================================
            level2_tracker_read_gen : if TRUE generate
            
                signal level1_big_region_here   : std_logic; 
                
                signal read_state               : unsigned(3 downto 0) := (others => '0');
                
                signal small_region_index       : unsigned(4 downto 0) := (others => '0');
            begin
            
                -- ============
                --  Once big-region data is fully in Level-2,
                --      read one small-region at a time out to algo
                --  Note: DETECTOR_OBJECTS_TO_ALGO/SHARED_SMALL_REGION_RAMS number of
                --      clocks needed to read out to algo. Plus
                --      add delay of ceil(ALGO_MAX_DETECTOR_OBJECTS/SHARED_SMALL_REGION_RAMS)  
                level2_tracker_read_process : process(clk_level2_to_algo)
                begin
                    
                    if ( rising_edge(clk_level1_to_2) ) then
                        
                        level1_big_region_here <= level1_big_region_end(g);
                        
                        if (reset = '1') then
                            read_state <= (others => '0');
                        else
                        
                            if (read_state = 0) then 
                            
                                if(level1_big_region_here = '1') then
                                    read_state <= x"1";
                                    small_region_index <= (others => '0'); --reset
                                end if;
                                
                            else if(read_state = 1) then
                                
                                if(small_region_index = SMALL_REGION_COUNT) then
                                    --done with all small-regions
                                    read_state <= x"0";
                                
                                else
                                    
                                
                                end if;
                                
                                
                            end if; --end state cases
                            
                        end if; --end primary reset if
                         
                    end if; --end rising edge if                   
                    
                end process level2_tracker_read_process;
            end generate level2_tracker_read_gen; 
                        
            
        end generate level2_tracker_buffer_group_gen;
    end generate level2_tracker_buffer_gen;
        

end Behavioral;
