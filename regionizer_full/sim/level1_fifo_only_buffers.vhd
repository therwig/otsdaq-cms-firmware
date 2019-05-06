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
use work.regionizer_params_pkg.all;

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
        
        level2_big_region_end   : in  std_logic;
        level2_pipe_in          : in  level1_to_2_global_pipe_t;
        level2_pipe_out         : out level1_to_2_global_pipe_t;
                
        overflow_error          : out std_logic;
        reset                   : in  std_logic
        
    );
end level1_fifo_only_buffers;

architecture Behavioral of level1_fifo_only_buffers is

    component level1_fifo_only_buffer  
        port (
           
            clk_link_to_level1      : in  std_logic;
            clk_level1_to_2         : in  std_logic; 
            
            link_big_region_end     : in  std_logic;
            
            link_object_we_in       : in  std_logic;
            link_object_in          : in  physics_object_t;
            
            level2_big_region_end   : in  std_logic;
            level2_pipe_in          : in  level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
            level2_pipe_out         : out level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
                    
            overflow_error          : out std_logic;
            reset                   : in  std_logic
        );
    end component level1_fifo_only_buffer;
    
    type pipes_shr_t    is array(integer range <>) of level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
begin

    --  This is the Level-1 FIFO-only buffer container.
    
    --  Generate fiber groups for each detector
    gen_tracker_fiber_groups : for g in 0 to FIBER_GROUPS-1 generate
        signal level1_to_2_pipes        : pipes_shr_t(TRACKER_FIBERS downto 0);
    begin

        level1_to_2_pipes(0)                        <= level2_pipe_in(g).tracker_pipe;
        level2_pipe_out(g).tracker_pipe             <= level1_to_2_pipes(TRACKER_FIBERS);
    
        gen_level1_buffers : for i in 0 to TRACKER_FIBERS-1 generate
        begin
                
            level1_buffer: level1_fifo_only_buffer
                port map (
                    
                    clk_link_to_level1              => clk_link_to_level1,          --: in  std_logic;
                    clk_level1_to_2                 => clk_level1_to_2,             --: in  std_logic; 
                    
                    link_big_region_end             => link_big_region_end(i),      --: in  std_logic;
                    
                    link_object_we_in               => link_object_we_in(i),        --: in  std_logic;
                    link_object_in                  => link_object_in(i),           --: in  physics_object_t;
                    
                    level2_big_region_end           => link_big_region_end(i),      --: in  std_logic;
                    level2_pipe_in                  => level1_to_2_pipes(i),        --: in  level1_to_2_pipe_arr_t(LEVEL2_PIPES_OUT-1 downto 0);
                    level2_pipe_out                 => level1_to_2_pipes(i+1),      --: out level1_to_2_pipe_arr_t(LEVEL2_PIPES_OUT-1 downto 0);
                            
                    overflow_error                  => open,                        --: out std_logic;
                    reset                           => reset                        --: in  std_logic
                );    
                
        end generate gen_level1_buffers;
    end generate gen_tracker_fiber_groups;

end Behavioral;
