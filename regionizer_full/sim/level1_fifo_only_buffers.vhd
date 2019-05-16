----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level1_fifo_only_buffers - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.regionizer_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity level1_fifo_only_buffers is
   generic (
        LINK_COUNT              : natural := MAX_FIBER_COUNT
   );
   port ( 
        clk_link_to_level1      : in  std_logic;
        clk_level1_to_2         : in  std_logic; 
        
        link_big_region_end     : in  std_logic_vector (LINK_COUNT-1 downto 0);
        
        link_object_we_in       : in  std_logic_vector (LINK_COUNT-1 downto 0);
        link_object_in          : in  physics_object_arr_t (LINK_COUNT-1 downto 0);
        level1_big_region_end   : out std_logic_vector(FIBER_GROUPS-1 downto 0);
        
        level2_big_region_end   : in  std_logic_vector(FIBER_GROUPS-1 downto 0);
        small_region_closed     : in  level2_to_1_sr_closed_arr_t(FIBER_GROUPS-1 downto 0);
        level2_pipe_out         : out level1_to_2_global_pipe_t;
                
        overflow_error          : out std_logic;
        level2_reset            : in  std_logic;
        reset                   : in  std_logic
        
    );
end level1_fifo_only_buffers;

architecture Behavioral of level1_fifo_only_buffers is

    component level1_fifo_only_buffer  
        generic (
            SOURCE_FIBER_INDEX      : natural := INVALID_SOURCE_FIBER
        );
        port (
           
            clk_link_to_level1      : in  std_logic;
            clk_level1_to_2         : in  std_logic; 
            
            link_big_region_end     : in  std_logic;
            
            link_object_we_in       : in  std_logic;
            link_object_in          : in  physics_object_t;
            level1_big_region_end   : out std_logic;
            
            level2_big_region_end   : in  std_logic;
            small_region_closed     : in  std_logic_vector(SMALL_REGION_COUNT-1 downto 0);
            level2_pipe_in          : in  level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
            level2_pipe_out         : out level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
                    
            overflow_error          : out std_logic;
            level2_reset            : in  std_logic;
            reset                   : in  std_logic
        );
    end component level1_fifo_only_buffer;
    
    type pipes_shr_t    is array(integer range <>) of level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
    
    type level1_detector_done_arr_t    is array(integer range <>) of std_logic_vector(INPUT_DECTECTOR_COUNT-1 downto 0);
    signal level1_detector_big_region_end   : level1_detector_done_arr_t(FIBER_GROUPS-1 downto 0) := (others => (others => '0'));
        
    type integer_arr_t is array(natural range <> ) of integer;
    constant DETECTOR_FIBERS_ARR            : integer_arr_t(2 downto 0) := (0 => TRACKER_FIBERS, 1 => EMCALO_FIBERS, 2 => CALO_FIBERS);
    constant OBJECTS_FIBERS_ARR             : integer_arr_t(2 downto 0) := (
            0 => 0, 
            1 => DETECTOR_FIBERS_ARR(0), 
            2 => DETECTOR_FIBERS_ARR(0)+DETECTOR_FIBERS_ARR(1));
    
begin

    --  This is the Level-1 FIFO-only buffer container.
    --      Organized fiber groups for each detector that share
    --      a shift-register pipeline for each small-region-set.
    --          e.g. if a small-region-set is size 2, then there are 9 pipelines
    --          to cover the 18 small-regions. 
    
    -- ========
    global_done_proc : process(clk_level1_to_2)
    begin
        if (rising_edge(clk_level1_to_2)) then
            
            for g in 0 to FIBER_GROUPS-1 loop
                level1_big_region_end(g) <= and_reduce(level1_detector_big_region_end(g));
            end loop;
            
        end if;
    end process global_done_proc;
    
    
    
    -- ==========================================================================================
    -- generate detector Level-1 buffers
    level1_detector_buffer_gen : for d in 0 to INPUT_DECTECTOR_COUNT-1 generate
        constant DETECTOR_FIBERS            : integer := DETECTOR_FIBERS_ARR(d);
    begin
    
        -- ==========================================================================================
        --  Generate fiber groups for detector
        gen_detector_fiber_groups : for g in 0 to FIBER_GROUPS-1 generate
        
            signal level1_to_2_pipes        : pipes_shr_t(DETECTOR_FIBERS downto 0) := (others => (others => empty_pipe));
            signal group_big_region_end     : std_logic_vector(DETECTOR_FIBERS-1 downto 0);
            signal detector_closed          : std_logic_vector(SMALL_REGION_COUNT-1 downto 0);
            
        begin
        
            ---------------
            --connect the proper detector specific objects
            tracker_detector_pipe_gen : if d = 0 generate
                level2_pipe_out(g).tracker_pipe         <= level1_to_2_pipes(DETECTOR_FIBERS);
                detector_closed                         <= small_region_closed(g).tracker_closed;
            end generate;
            emcalo_detector_pipe_gen  : if d = 1 generate
                level2_pipe_out(g).emcalo_pipe          <= level1_to_2_pipes(DETECTOR_FIBERS);
                detector_closed                         <= small_region_closed(g).emcalo_closed;
            end generate;
            calo_detector_pipe_gen    : if d = 2 generate
                level2_pipe_out(g).calo_pipe            <= level1_to_2_pipes(DETECTOR_FIBERS);
                detector_closed                         <= small_region_closed(g).calo_closed;
            end generate;
            --end connect the proper detector specific objects
            ---------------
    
            level1_to_2_pipes(0)                        <= (others => empty_pipe);            
            
            -- ========
            group_done_proc : process(clk_level1_to_2)
            begin
                if (rising_edge(clk_level1_to_2)) then
                    level1_detector_big_region_end(g)(d) <= and_reduce(group_big_region_end);
                end if;
            end process group_done_proc;
            
            -- ==========================================================================================
            gen_detector_level1_buffers : for i in 0 to TRACKER_FIBERS-1 generate
                constant SOURCE_FIBER_INDEX : integer := g*FIBERS_IN_GROUP + OBJECTS_FIBERS_ARR(d) + i;         
            begin
                                
                detector_level1_buffer: level1_fifo_only_buffer
                    generic map (
                        SOURCE_FIBER_INDEX              => SOURCE_FIBER_INDEX
                    )
                    port map (
                        
                        clk_link_to_level1              => clk_link_to_level1,          --: in  std_logic;
                        clk_level1_to_2                 => clk_level1_to_2,             --: in  std_logic; 
                        
                        link_big_region_end             => link_big_region_end(SOURCE_FIBER_INDEX),      --: in  std_logic;
                        
                        link_object_we_in               => link_object_we_in(SOURCE_FIBER_INDEX),        --: in  std_logic;
                        link_object_in                  => link_object_in(SOURCE_FIBER_INDEX),           --: in  physics_object_t;
                        level1_big_region_end           => group_big_region_end(i),     --: out std_logic;
                        
                        level2_big_region_end           => level2_big_region_end(g),    --: in  std_logic;
                        small_region_closed             => detector_closed,             --: in  std_logic_vector(SMALL_REGION_COUNT-1 downto 0);
                        level2_pipe_in                  => level1_to_2_pipes(i),        --: in  level1_to_2_pipe_arr_t(LEVEL2_PIPES_OUT-1 downto 0);
                        level2_pipe_out                 => level1_to_2_pipes(i+1),      --: out level1_to_2_pipe_arr_t(LEVEL2_PIPES_OUT-1 downto 0);
                                
                        overflow_error                  => open,                        --: out std_logic;
                        level2_reset                    => level2_reset,                --: in  std_logic;
                        reset                           => reset                        --: in  std_logic
                    );    
                    
            end generate gen_detector_level1_buffers;
        end generate gen_detector_fiber_groups;
    end generate level1_detector_buffer_gen;
    

end Behavioral;
