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
        clk_level1_to_2         : in std_logic;
            
        big_region_end          : in std_logic;
        
        object_pipe_in          : in level1_to_2_global_pipe_t;
        
        next_big_region         : out std_logic;
        small_region_closed     : out std_logic_vector(ALGO_INPUT_SMALL_REGION_COUNT-1 downto 0);  
        
        robjects_re             : in std_logic;
        robjects_out_valid      : out std_logic;
        robjects_out            : out physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
        
        -- overflow not possible.. overflow_error          : out std_logic;
        reset                   : in std_logic
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
            clk_level1_to_2         : in std_logic;
            
            big_region_end          : in std_logic;
            
            object_pipe_in          : level1_to_2_pipe_t;
            
            next_big_region         : out std_logic;
            small_region_closed     : out std_logic_vector(ALGO_INPUT_SMALL_REGION_COUNT-1 downto 0);  
            
            robjects_re             : in std_logic;
            robjects_out_valid      : out std_logic;
            robjects_out            : out physics_object_arr_t(PARALLEL_OBJECT_RAMS-1 downto 0);
            
            -- overflow not possible.. overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level2_ram_buffer;
    
    
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

    robjects_out_valid          <= robjects_re; -- unnecessary and_reduce(all valids)

    -- generate Tracker Level-2 buffers
    level2_tracker_buffer_gen : if TRUE generate
        constant DETECTOR_OBJECTS_TO_ALGO   : integer := 25;   
        constant SHARED_SMALL_REGION_RAMS   : integer := ALGO_INPUT_SMALL_REGION_COUNT/SMALL_REGIONS_PER_RAM;    
    begin
        level2_tracker_buffer_group_gen : for g in 0 to FIBER_GROUPS-1 generate
            type debug_count_arr_t is array(integer range <>) of integer;
            signal debug_pipe_valid_count   : debug_count_arr_t(SHARED_SMALL_REGION_RAMS-1 downto 0) := (others => 0);
        begin                    
        
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
                        clk_level1_to_2                 => clk_level1_to_2,        --: in std_logic;
                                
                        big_region_end                  => '0',                         --: in std_logic;
                        
                        object_pipe_in                  => object_pipe_in(g).tracker_pipe(i), --: level1_to_2_pipe_t;
                        
                        next_big_region                 => open,                        --: out std_logic;
                        small_region_closed             => open,                        --: out std_logic_vector(ALGO_INPUT_SMALL_REGION_COUNT-1 downto 0);  
                        
                        robjects_re                     => '0',                         --: in std_logic;
                        robjects_out_valid              => open,                        --: out std_logic;
                        robjects_out                    => open,                        --: out physics_object_arr_t(PARALLEL_OBJECT_RAMS-1 downto 0);  
                
                        reset                           => reset
                    );    
                --end tracker buffer component
                                                     
            end generate level2_tracker_buffer_multiram_gen;
        end generate level2_tracker_buffer_group_gen;
    end generate level2_tracker_buffer_gen;
        

end Behavioral;
