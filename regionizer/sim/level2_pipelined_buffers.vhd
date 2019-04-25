----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level2_pipelined_buffers - Behavioral
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


entity level2_pipelined_buffers is
    generic (
        LINK_COUNT              : integer := MAX_FIBER_COUNT
    );
    port ( 
        
        clk_level1_to_2         : in std_logic;
        
        link_big_region_end     : in std_logic_vector (LINK_COUNT-1 downto 0);
         
        level2_re               : out std_logic_vector(FIBER_GROUPS-1 downto 0);
        level2_eta_phi_rindex   : out eta_phi_small_region_arr_t(FIBER_GROUPS-1 downto 0);
               
        level2_din_valid        : in std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
        level2_din              : in physics_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
        
        level2_dout_valid       : out std_logic;
        level2_dout             : out physics_object_arr_t(INPUT_DECTECTOR_COUNT*ALGO_MAX_DETECTOR_OBJECTS-1 downto 0);
                
        reset                   : in std_logic
    );
end level2_pipelined_buffers;

architecture Behavioral of level2_pipelined_buffers is

    constant IN_OBJECT_COUNT        : integer := LEVEL1_RAMS_PER_LINK * (FIBERS_IN_GROUP/INPUT_DECTECTOR_COUNT);
    
    component level2_pipelined_buffer
        generic (
            IN_OBJECT_COUNT         : integer := LEVEL1_RAMS_PER_LINK * (FIBERS_IN_GROUP/INPUT_DECTECTOR_COUNT);
            OUT_OBJECT_COUNT        : integer := ALGO_MAX_DETECTOR_OBJECTS
        );
        port ( 
            clk_level1_to_2         : in std_logic;
        
            level2_din_valid        : in std_logic_vector(IN_OBJECT_COUNT-1 downto 0);
            level2_din              : in physics_object_arr_t(IN_OBJECT_COUNT-1 downto 0);
            
            level2_dout_valid       : out std_logic;         
            level2_dout             : out physics_object_arr_t(OUT_OBJECT_COUNT-1 downto 0);
            
            reset                   : in std_logic 
        );
    end component level2_pipelined_buffer;
    
    
begin

    -- behavior
    --
    --  For each group start reading once big-region is fully in Level-1 RAM
    --      
    
    -- ==========================================================================================
    gen_read_enable_behavior : for g in 0 to FIBER_GROUPS-1 generate
    
        signal link_big_region_end_hold     : std_logic_vector (FIBERS_IN_GROUP-1 downto 0) := (others => '0');
        signal big_region_ready             : std_logic := '0';
        signal small_region_rindex          : small_region_index_t := 0;  
           
        signal level2_re_sig                : std_logic := '0';                 
        
        --signals for debugging
        signal debug_sr_rindex_back         : eta_phi_small_region_t;  
                    
        constant RINDEX_DELAY               : integer := 3;
        signal debug_sr_rindex_pipeline     : eta_phi_small_region_arr_t(RINDEX_DELAY-1 downto 0);
                
    begin
        
        level2_re(g)                                <= level2_re_sig;
        level2_eta_phi_rindex(g)                    <= convert_small_region_to_object(small_region_rindex);
        
        debug_sr_rindex_back                        <= debug_sr_rindex_pipeline(RINDEX_DELAY-1);
        
        -- ========================================
        read_enable_process : process(clk_level1_to_2)
        begin
        
            if (rising_edge(clk_level1_to_2)) then
            
                level2_re_sig <= '0';
                debug_sr_rindex_pipeline(RINDEX_DELAY-1 downto 0) <= debug_sr_rindex_pipeline(RINDEX_DELAY-2 downto 0) & 
                    convert_small_region_to_object(small_region_rindex);
                
                 
                if (reset = '1') then
                
                    link_big_region_end_hold    <= (others =>'0');
                    big_region_ready            <= '0';
                    
                    small_region_rindex         <= 0;
                    
                else --not reset
                
                    for i in 0 to FIBERS_IN_GROUP-1 loop
                        if (link_big_region_end(i) = '1') then
                            link_big_region_end_hold(i) <= '1';
                        end if;
                    end loop;
                    
                    big_region_ready <= and_reduce(link_big_region_end_hold);
                    
                    level2_re_sig <= big_region_ready;
                    
                
                    --when big region is ready, reset for next big-region
                    if (big_region_ready = '1') then
                        link_big_region_end_hold    <= (others =>'0');
                        small_region_rindex         <= small_region_rindex + 1;    
                    end if;
                    
                    --read all small regions
                    if (level2_re_sig = '1' and 
                        small_region_rindex < 
                            ALGO_INPUT_SMALL_REGION_ETA_SIZE*ALGO_INPUT_SMALL_REGION_PHI_SIZE-1) then 
                        
                        small_region_rindex         <= small_region_rindex + 1;
                        level2_re_sig               <= '1';
                        
                    end if;
                    
                    
                    
                end if; --end reset if
            
            end if; --end rising edge if
        
        end process read_enable_process;
        
    end generate gen_read_enable_behavior; 
    
    
    -- ==========================================================================================
    gen_level2_buffers : for i in 0 to INPUT_DECTECTOR_COUNT-1 generate    
        signal group_read_valid             : std_logic_vector(FIBER_GROUPS-1 downto 0) := (others => '0');
    begin
    
        --FIXME -- need to get group valid, and use that to mux the din from the proper group/tmux
        --FIXME -- indices for din are wrong!
    
        -- ========================================
        level2_buffer: level2_pipelined_buffer
--            generic (
--                IN_OBJECT_COUNT         : integer;
--                OUT_OBJECT_COUNT        : integer
--            );
            port map ( 
                clk_level1_to_2         => clk_level1_to_2,        --: in std_logic;
                
                level2_din_valid        => level2_din_valid(
                    (i+1)*IN_OBJECT_COUNT-1 downto 
                    i*IN_OBJECT_COUNT),                   --: in std_logic_vector(IN_OBJECT_COUNT-1 downto 0);
                level2_din              => level2_din(
                    (i+1)*IN_OBJECT_COUNT-1 downto 
                    i*IN_OBJECT_COUNT),                   --: in raw_physics_object_arr_t(IN_OBJECT_COUNT-1 downto 0);
                        
                level2_dout             => level2_dout(
                    (i+1)*ALGO_MAX_DETECTOR_OBJECTS-1 downto 
                    i*ALGO_MAX_DETECTOR_OBJECTS),                   --: out raw_physics_object_arr_t(OUT_OBJECT_COUNT-1 downto 0);
                
                reset                   => reset                    --: in std_logic
            );
    end generate gen_level2_buffers;

end Behavioral;
