----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level2_pipelined_buffer - Behavioral
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

use work.tmux_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity level2_pipelined_buffer is
    generic (
        IN_OBJECT_COUNT         : integer := LEVEL1_RAMS_PER_LINK * (FIBERS_IN_GROUP/INPUT_DECTECTOR_COUNT);
        OUT_OBJECT_COUNT        : integer := ALGO_MAX_DETECTOR_OBJECTS
    );
    port ( 
        
        clk_level1_to_2         : in std_logic;
        
        level2_din_valid        : in std_logic_vector(IN_OBJECT_COUNT-1 downto 0);
        level2_din              : in raw_phyiscs_object_arr_t(IN_OBJECT_COUNT-1 downto 0);
        
        level2_dout_valid       : out std_logic;         
        level2_dout             : out raw_phyiscs_object_arr_t(OUT_OBJECT_COUNT-1 downto 0);
        
        reset                   : in std_logic        
    );
end level2_pipelined_buffer;

architecture Behavioral of level2_pipelined_buffer is

    constant PIPE_LINE_STAGES   : natural := 30; -- Note: if 320MHz then 48 is max size
    
    type pipeline_t is array(integer range <>) of raw_phyiscs_object_arr_t(IN_OBJECT_COUNT-1 downto 0);
    signal pipeline             : pipeline_t(PIPE_LINE_STAGES-1 downto 0) := (others => (others => (others => '0')));
    signal pipeline_valid       : std_logic_vector(PIPE_LINE_STAGES-1 downto 0) := (others => '0');          
    
begin

    --  This is a pipline for a specific detector type
    --
    -- =====
    -- Write behavior:
    --
    --  When Level-1 identifies a big-region has closed,
    --      all Level-1 RAMs for a detector write simultaneously to pipeline in.
    --      e.g. 10 links x 18 RAMs =  180  x 64b words in.  
    --      The first clock with we '1' is small-region[0] objects, then
    --          the next clock in is small-region[1], and so on.
    --          There must be enough clocks to finish all small-regions in the big
    --          region before the next TMux-group closes its big-region,
    --          i.e. 6 Bx for 3 TMux-groups
    
    -- =====
    -- Pipeline behavior:
    --
    --  Each stage of the pipeline is working towards
    --      the detector output object count for the algorithm.
    --      e.g. 30 objects from tracker per small-region
    
    --
    -- ======
    -- Read behavior:
    --
    --  Data out from pipeline will come out with a valid and algo objects
    --      at the end of the pipeline.
    --    
    
    -- ========================================
    pipeline_process: process(clk_level1_to_2)
    begin
    
        if (rising_edge(clk_level1_to_2)) then
        
            pipeline_valid <= pipeline_valid(PIPE_LINE_STAGES-2 downto 0) & 
                or_reduce(level2_din_valid);
            
            --by default, take input when valid and shift pipeline down,
            --  override with special behavior
            pipeline(PIPE_LINE_STAGES-1 downto 1) <= pipeline(PIPE_LINE_STAGES-2 downto 0);
            for i in 0 to IN_OBJECT_COUNT-1 loop
                if(level2_din_valid(i) = '1') then
                    pipeline(0)(i) <= level2_din(i);
                else
                    pipeline(0)(i) <= (others => '0');
                end if;
            end loop;
            
            -- could just do HLS sort of IN_OBJECT_COUNT --> high OUT_OBJECT_COUNT
            --  
--              for ( int i=0; i < OUT_OBJECT_COUNT; ++i) 
--              {
--                  max = 0;
--                  maxj = -1;
--                  for( int j=i; j < IN_OBJECT_COUNT; ++j)
--                  {
--                      if(data[j] > max) 
--                          { max = data[j]; maxj = j; }
--                  }            --     
--                  tmp = data[i];
--                  data[i] = data[maxj];
--                  data[maxj] = tmp;          
--              }
            
            
            
            
        end if; --end rising_edge
    
    end process pipeline_process;

end Behavioral;
