----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: tmux_wrapper_layer1_buffer - Behavioral
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

entity tmux_wrapper_layer1_buffer is
    --generic (
        --LINK_COUNT_G  : integer
    --);
    port ( 
        reset                   : in std_logic;
        clk120                  : in std_logic;
        clk240                  : in std_logic; 
        link_object_in          : in physics_object_t;
        link_object_we_in       : in std_logic;
        layer2_token_in         : in std_logic_vector (5 downto 0));
end tmux_wrapper_layer1_buffer;

architecture Behavioral of tmux_wrapper_layer1_buffer is
    signal layer0_rd_en             : std_logic := '0';
    signal layer0_empty             : std_logic;
    signal layer0_full              : std_logic;
    signal layer0_rd_object         : physics_object_t;
    
    signal layer0_dummy             : std_logic;
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
    
    -- layer0 buffer FIFO
    
    layer0_fifo: entity work.raw_link_buffer_layer0
        port map (
            rst                             => reset,
            wr_clk                          => clk120,
            rd_clk                          => clk240,
            
            din(63)                        => layer0_rd_object.quality,
            din(62)                        => '0',
            din(61 downto 52)              => layer0_rd_object.z0,
            din(51 downto 42)              => layer0_rd_object.phi,
            din(41 downto 32)              => layer0_rd_object.eta,
            din(31 downto 16)              => layer0_rd_object.otherPt,
            din(15 downto 0)               => layer0_rd_object.pt,
            
            wr_en                           => link_object_we_in,
            rd_en                           => layer0_rd_en,       
                           
            dout(63)                        => layer0_rd_object.quality,
            dout(62)                        => layer0_dummy,
            dout(61 downto 52)              => layer0_rd_object.z0,
            dout(51 downto 42)              => layer0_rd_object.phi,
            dout(41 downto 32)              => layer0_rd_object.eta,
            dout(31 downto 16)              => layer0_rd_object.otherPt,
            dout(15 downto 0)               => layer0_rd_object.pt,
            
            full                            => layer0_full,
            empty                           => layer0_empty,
            wr_rst_busy                     => open,
            rd_rst_busy                     => open
        );    
        
        
        
end Behavioral;
