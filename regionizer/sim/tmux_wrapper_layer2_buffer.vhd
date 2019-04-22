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
use ieee.numeric_std.all;
use work.tmux_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tmux_wrapper_layer2_buffer is
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
end tmux_wrapper_layer2_buffer;

architecture Behavioral of tmux_wrapper_layer2_buffer is


    constant    LAYER_BRAM_ADDR_SIZE        : natural := 10; --bits
    
    component physics_object_bram
        port (
            clka : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(LAYER_BRAM_ADDR_SIZE-1 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(PHYSICS_OBJECT_BIT_SIZE-1 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(PHYSICS_OBJECT_BIT_SIZE-1 DOWNTO 0);
            clkb : IN STD_LOGIC;
            web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addrb : IN STD_LOGIC_VECTOR(LAYER_BRAM_ADDR_SIZE-1 DOWNTO 0);
            dinb : IN STD_LOGIC_VECTOR(PHYSICS_OBJECT_BIT_SIZE-1 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(PHYSICS_OBJECT_BIT_SIZE-1 DOWNTO 0)
            );
    end component physics_object_bram;
    
    signal layer2_raddr             : std_logic_vector(LAYER_BRAM_ADDR_SIZE-1 DOWNTO 0); 
begin

    --  This is a token manager buffer for a specific detector type
    --
    -- =====
    -- Write behavior:
    --
    --  send out token-bus AND eta-phi-small-region-index every clock
    --      for 'this' subdetector  
    --  
    --  for each token, a data-valid and data is returned (from shared bus, multiple sources)
    --
    -- ======
    -- Read behavior:
    --
    --  Data from all brams are read simultaneously for each eta-phi-small-region-index
    --      into the HSL algo. 
    --    
    
    gen_block_ram : for i in 0 to OBJECT_COUNT-1 generate
        signal layer2_waddr             : std_logic_vector(LAYER_BRAM_ADDR_SIZE-1 DOWNTO 0);
    begin
    
        level1_bram: physics_object_bram
                port map (
    --                clka : IN STD_LOGIC;
    --                wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --                addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    --                dina : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    --                douta : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    --                clkb : IN STD_LOGIC;
    --                web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --                addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    --                dinb : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    --                doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
                    clka                => clk240,
                    wea(0)              => layer2_we_in(i),
                    addra               => layer2_waddr,
                    dina                => layer2_data_in(i),
                    douta               => open,
                    clkb                => clk120,
                    web(0)              => '0',
                    addrb               => layer2_raddr,
                    dinb                => (others => '0'),
                    doutb               => open
                );  

    
    end generate gen_block_ram;

end Behavioral;
