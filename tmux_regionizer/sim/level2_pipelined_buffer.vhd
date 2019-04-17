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
        reset                   : in std_logic;
        level_1to2_clk          : in std_logic;
        level_2toAlgo_clk       : in std_logic; 
        layer2_we_in            : in std_logic_vector(IN_OBJECT_COUNT-1 downto 0);
        layer2_data_in          : in raw_phyiscs_object_arr_t(IN_OBJECT_COUNT-1 downto 0);
                
        layer2_data_out         : out raw_phyiscs_object_arr_t(OUT_OBJECT_COUNT-1 downto 0)
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
    --      e.g. 30 links x 18 RAMs =  540  x 64b words in.  
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
    
    pipeline_process: process(level_1to2_clk)
    begin
    
        if (rising_edge(level_1to2_clk)) then
        
            pipeline_valid <= pipeline_valid(PIPE_LINE_STAGES-2 downto 0) & layer2_we_in;
            
            if(layer2_we_in)
                pipeline(0) <=  
            
        
        end if; --end rising_edge
    
    end process pipeline_process;

end Behavioral;
