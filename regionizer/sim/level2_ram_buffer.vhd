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
use work.tmux_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



----------------------------------------------------------------------------------


entity level2_ram_buffers is
    port ( 
        reset                   : in std_logic;
        level_1to2_clk          : in std_logic;
        level_2toAlgo_clk       : in std_logic; 
        layer2_we_in            : in std_logic_vector(45-1 downto 0);
        layer2_data_in          : in raw_phyiscs_object_arr_t(45-1 downto 0);
                
        layer2_token_start      : out std_logic_vector (INPUT_FIBERS-1 downto 0)
    );
end level2_ram_buffers;

architecture Behavioral of level2_ram_buffers is

    component level2_ram_buffer
        generic (
            OBJECT_COUNT  : integer
        );
        port (
            reset                   : in std_logic;
            level_1to2_clk          : in std_logic;
            level_2toAlgo_clk       : in std_logic; 
            layer2_we_in            : in std_logic_vector(OBJECT_COUNT-1 downto 0);
            layer2_data_in          : in raw_phyiscs_object_arr_t(OBJECT_COUNT-1 downto 0);
            
            
            layer2_token_start      : out std_logic_vector (OBJECT_COUNT-1 downto 0)
        );
    end component level2_ram_buffer;
    
begin

    -- behavior
    --
    --  generate a token manager buffer for each detector type
    --      
    
    
    gen_layer2_buffers : for i in 0 to 2 generate
    begin
        layer2_buffer: level2_ram_buffer
            generic map (
                OBJECT_COUNT                    => 15   
            )
            port map (
                reset                           => reset,
                level_1to2_clk                  => level_1to2_clk,
                level_2toAlgo_clk               => level_2toAlgo_clk,
                layer2_we_in                    => layer2_we_in((i+1)*15-1 downto i*15),
                layer2_data_in                  => layer2_data_in((i+1)*15-1 downto i*15),
--                link_object_in                  => link_object_in(i),
--                link_object_we_in               => link_object_we_in(i),
--                layer2_token_in                 => (others => '0')  
            );    
    end generate;

end Behavioral;
