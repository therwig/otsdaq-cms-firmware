----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: tmux_wrapper_layer2_buffer - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tmux_wrapper_layer2_buffer is
    Port ( object_in : in STD_LOGIC_VECTOR (63 downto 0);
           token_out : out STD_LOGIC);
end tmux_wrapper_layer2_buffer;

architecture Behavioral of tmux_wrapper_layer2_buffer is

begin


end Behavioral;
