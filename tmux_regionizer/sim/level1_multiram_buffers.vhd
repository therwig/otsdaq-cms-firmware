----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: tmux_wrapper_layer1_buffers - Behavioral
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
use work.tmux_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tmux_wrapper_layer1_buffers is
   generic (
        LINK_COUNT              : natural := MAX_FIBER_COUNT
   );
   port ( 
        reset                   : in std_logic;
        clk120                  : in std_logic;
        clk240                  : in std_logic; 
        
        link_big_region_end     : in std_logic_vector (LINK_COUNT-1 downto 0);
        
        link_object_in          : in physics_object_arr_t (LINK_COUNT-1 downto 0);
        link_object_we_in       : in std_logic_vector (LINK_COUNT-1 downto 0);
        layer2_token_in         : in std_logic_vector (5 downto 0));
end tmux_wrapper_layer1_buffers;

architecture Behavioral of tmux_wrapper_layer1_buffers is

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


    gen_layer1_buffers : for i in 0 to LINK_COUNT-1 generate
    begin
        layer1_buffer: entity work.tmux_wrapper_layer1_buffer
            port map (
                reset                           => reset,
                clk120                          => clk120,
                clk240                          => clk240,
                link_object_in                  => link_object_in(i),
                link_object_we_in               => link_object_we_in(i),
                layer2_token_in                 => (others => '0')  
            );    
    end generate;

end Behavioral;
