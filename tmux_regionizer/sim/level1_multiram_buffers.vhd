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

use work.tmux_params_pkg.all;

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
        level2_eta_phi_rindex   : in get_eta_phi_small_region_t;
        
        objects_out_valid       : out std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
        objects_out             : out raw_phyiscs_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            
        
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
            level2_eta_phi_rindex   : in get_eta_phi_small_region_t;
            objects_out_valid       : out std_logic_vector(MULTIRAM_COUNT-1 downto 0);
            objects_out             : out raw_phyiscs_object_arr_t(MULTIRAM_COUNT-1 downto 0);
            
            overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level1_multiram_buffer;
    
begin

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
        signal overflow_error_arr       : std_logic_vector(LINK_COUNT-1 downto 0);
    begin
        
        -- ========================================
        overflow_error_process : process(clk_link_to_level1)
        begin
        
            if (rising_edge(clk_link_to_level1)) then
                overflow_error <= or_reduce(overflow_error_arr);
            end if;
            
        end process overflow_error_process;
        
        -- ========================================
        level1_buffer: level1_multiram_buffer
            generic map (
                MULTIRAM_COUNT          => LEVEL1_RAMS_PER_LINK
            )
            port map (
                clk_link_to_level1      => clk_link_to_level1,          --: in std_logic;
            
                link_big_region_end     => link_big_region_end(i),      --: in std_logic;
                
                link_object_in          => link_object_in(i),           --: in physics_object_t;
                link_object_we_in       => link_object_we_in(i),        --: in std_logic;
                
                level2_re_in            => level2_re_in(i / FIBERS_IN_GROUP),                --: in std_logic;
                level2_eta_phi_rindex   => level2_eta_phi_rindex,       --: in get_eta_phi_small_region_t;
                objects_out_valid       => objects_out_valid(
                    (i+1)*LEVEL1_RAMS_PER_LINK-1 downto i*LEVEL1_RAMS_PER_LINK),        --: out std_logic;
                objects_out             => objects_out(
                    (i+1)*LEVEL1_RAMS_PER_LINK-1 downto i*LEVEL1_RAMS_PER_LINK),              --: out raw_phyiscs_object_t;
                
                overflow_error          => overflow_error_arr(i),       --: out std_logic;
                reset                   => reset                        --: in std_logic
                 
            ); --end component level1_multiram_buffer 
            
    end generate gen_level1_buffers;

end Behavioral;
