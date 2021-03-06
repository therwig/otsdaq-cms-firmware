----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: tmux_wrapper_level1_buffers - Behavioral
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

use work.regionizer_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity level1_multiram_buffers is
   generic (
        LINK_COUNT              : integer := MAX_FIBER_COUNT
   );
   port ( 
        clk_link_to_level1      : in std_logic;
        
        link_big_region_end     : in std_logic_vector (LINK_COUNT-1 downto 0);
        
        link_object_we_in       : in std_logic_vector (LINK_COUNT-1 downto 0);
        link_object_in          : in physics_object_arr_t (LINK_COUNT-1 downto 0);
        
        level2_re_in            : in std_logic_vector(FIBER_GROUPS-1 downto 0);
        level2_eta_phi_rindex   : in eta_phi_small_region_arr_t(FIBER_GROUPS-1 downto 0);
        
        objects_out_valid       : out std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
        objects_out             : out physics_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            
        
        overflow_error          : out std_logic;
        reset                   : in std_logic
    );
end level1_multiram_buffers;

architecture Behavioral of level1_multiram_buffers is

    component level1_multiram_buffer    
        generic (
            MULTIRAM_COUNT          : integer
        );
        port (
            clk_link_to_level1     : in std_logic;
            
            link_big_region_end     : in std_logic;
            
            link_object_in          : in physics_object_t;
            link_object_we_in       : in std_logic;
            
            level2_re_in            : in std_logic;
            level2_eta_phi_rindex   : in eta_phi_small_region_t;
            objects_out_valid       : out std_logic_vector(MULTIRAM_COUNT-1 downto 0);
            objects_out             : out physics_object_arr_t(MULTIRAM_COUNT-1 downto 0);
            
            overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level1_multiram_buffer;
    
    signal overflow_error_arr       : std_logic_vector(LINK_COUNT-1 downto 0);
    
    type counter_arr_t is array(natural range <> ) of unsigned(15 downto 0);
    signal debug_we_count           : counter_arr_t(LINK_COUNT-1 downto 0) := (others => (others =>'0'));
    
begin

    
    -- ========================================
    debug_count_process : process(clk_link_to_level1)
    begin
        if (rising_edge(clk_link_to_level1)) then
        
            if (reset = '1') then
                debug_we_count <= (others => (others =>'0'));  
            else
            
                for i in 0 to LINK_COUNT-1 loop
                    if (link_big_region_end(i) = '1') then
                        debug_we_count(i) <= (others => '0');
                    elsif (link_object_we_in(i) = '1') then
                        debug_we_count(i) <= debug_we_count(i) + 1;
                    end if;
                end loop;
                
            end if;
            
        end if;
    end process debug_count_process;
    
            
    -- ========================================
    overflow_error_process : process(clk_link_to_level1)
    begin
    
        if (rising_edge(clk_link_to_level1)) then
            overflow_error <= or_reduce(overflow_error_arr);
        end if;
        
    end process overflow_error_process;

    
    -- behavior:
    
    --  write in using 120MHz clock 
    --  one dual port fifo for initial buffer
    --      64b x 512    
    --      to keep up with potential for object to be in multiple small regions
    --      
    --  transfer to small region segmented ram using 240MHz clock
    --  one dual port block ram for each link
    --      block ram is segmented by small region 
    --      e.g. 3 eta x 2 phi = 6 small regions
    --      if 1024 locations and 6 small regions, then each small region
    -- 

    
    -- ==========================================================================================
    gen_level1_buffers : for i in 0 to LINK_COUNT-1 generate
    
        signal object_we                : std_logic;
        signal object                   : physics_object_t;
        
        signal robjects_sig             : physics_object_arr_t(LEVEL1_RAMS_PER_LINK-1 downto 0);
        
    begin
    
        object_we <= link_object_we_in(i);
        object <= link_object_in(i);
        
        
        
        -- add link index at this point to debug info of physics object
        gen_add_debug_info : for j in 0 to LEVEL1_RAMS_PER_LINK-1 generate
        
            objects_out(i*LEVEL1_RAMS_PER_LINK + j) <= ( 
                phi                 => robjects_sig(j).phi,
                eta                 => robjects_sig(j).eta,
                quality             => robjects_sig(j).quality,
                lsEM                => robjects_sig(j).lsEM,
                z0                  => robjects_sig(j).z0,
                otherPt             => robjects_sig(j).otherPt,
                pt                  => robjects_sig(j).pt,
                
                small_region        => robjects_sig(j).small_region,
                source_fiber        => i,
                source_event_index  => robjects_sig(j).source_event_index
            ); 
            
        end generate gen_add_debug_info;
        
        
        -- ========================================
        level1_buffer: level1_multiram_buffer
            generic map (
                MULTIRAM_COUNT          => LEVEL1_RAMS_PER_LINK
            )
            port map (
                clk_link_to_level1      => clk_link_to_level1,          --: in std_logic;
            
                link_big_region_end     => link_big_region_end(i),      --: in std_logic;
                
                link_object_in          => object,                      --: in physics_object_t;
                link_object_we_in       => object_we,                   --: in std_logic;
                
                level2_re_in            => level2_re_in(i / FIBERS_IN_GROUP),               --: in std_logic;
                level2_eta_phi_rindex   => level2_eta_phi_rindex(i / FIBERS_IN_GROUP),       --: in eta_phi_small_region_t;
                objects_out_valid       => objects_out_valid(
                    (i+1)*LEVEL1_RAMS_PER_LINK-1 downto i*LEVEL1_RAMS_PER_LINK),    --: out std_logic;
                objects_out             => robjects_sig,                --: out physics_object_arr_t;
                
                overflow_error          => overflow_error_arr(i),       --: out std_logic;
                reset                   => reset                        --: in std_logic
                 
            ); --end component level1_multiram_buffer 
            
    end generate gen_level1_buffers;

end Behavioral;
