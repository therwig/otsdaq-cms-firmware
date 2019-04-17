----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level1_oneram_buffer - Behavioral
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

entity level1_oneram_buffer is
    --generic (
        --LINK_COUNT_G  : integer
    --);
    port ( 
        reset                   : in std_logic;
        clk120                  : in std_logic;
        clk240                  : in std_logic; 
        
        link_big_region_end     : in std_logic;
        
        link_object_in          : in physics_object_t;
        link_object_we_in       : in std_logic;
        layer2_token_in         : in std_logic_vector (5 downto 0));
end level1_oneram_buffer;

architecture Behavioral of level1_oneram_buffer is

    constant    LAYER_BRAM_ADDR_SIZE        : natural := 10; --bits
     
    component raw_link_buffer_layer0
        port (
            rst : in STD_LOGIC;
            wr_clk : in STD_LOGIC;
            rd_clk : in STD_LOGIC;
            din : in STD_LOGIC_VECTOR ( PHYSICS_OBJECT_BIT_SIZE-1 downto 0 );
            wr_en : in STD_LOGIC;
            rd_en : in STD_LOGIC;
            dout : out STD_LOGIC_VECTOR ( PHYSICS_OBJECT_BIT_SIZE-1 downto 0 );
            full : out STD_LOGIC;
            empty : out STD_LOGIC;
            wr_rst_busy : out STD_LOGIC;
            rd_rst_busy : out STD_LOGIC
            );
    end component raw_link_buffer_layer0;
    
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



    signal layer0_rd_en             : std_logic := '0';
    signal layer0_empty             : std_logic;
    signal layer0_full              : std_logic;
    signal layer0_rd_object         : physics_object_t;
    
    signal layer0_din               : raw_phyiscs_object_t;
    signal layer0_dout              : raw_phyiscs_object_t;
    signal layer1_dout              : raw_phyiscs_object_t;
    
    signal layer0_rd_big_region_end : std_logic;
    
    --signal layer0_dummy             : std_logic;
    
    
    
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
    
    
    layer0_din(63)                        <= link_object_in.quality;
    layer0_din(62)                        <= link_big_region_end; -- '0'; --FIXME hijacked a bit
    layer0_din(52)                        <= link_object_in.lsEM;
    layer0_din(61 downto 52)              <= std_logic_vector(link_object_in.z0);
    layer0_din(51 downto 42)              <= std_logic_vector(link_object_in.phi);
    layer0_din(41 downto 32)              <= std_logic_vector(link_object_in.eta);
    layer0_din(31 downto 16)              <= std_logic_vector(link_object_in.otherPt);
    layer0_din(15 downto 0)               <= std_logic_vector(link_object_in.pt);
    
    
            
    
    -- ==========================================================================================
    -- layer0 buffer FIFO
    layer0_fifo: raw_link_buffer_layer0
        port map (
--            rst : in STD_LOGIC;
--            wr_clk : in STD_LOGIC;
--            rd_clk : in STD_LOGIC;
--            din : in STD_LOGIC_VECTOR ( 63 downto 0 );
--            wr_en : in STD_LOGIC;
--            rd_en : in STD_LOGIC;
--            dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
--            full : out STD_LOGIC;
--            empty : out STD_LOGIC;
--            wr_rst_busy : out STD_LOGIC;
--            rd_rst_busy : out STD_LOGIC
            rst                             => reset,
            wr_clk                          => clk120,
            rd_clk                          => clk240,
            
            din                             => layer0_din,
            
            wr_en                           => link_object_we_in,
            rd_en                           => layer0_rd_en,       
                           
            dout                            => layer0_dout,
                       
            full                            => layer0_full,
            empty                           => layer0_empty,
            wr_rst_busy                     => open,
            rd_rst_busy                     => open
        );    
        
    layer0_rd_object.quality                <= layer0_dout(63);
    layer0_rd_big_region_end                <= layer0_dout(62); --FIXME hijacked a bit!
    layer0_rd_object.lsEM                   <= layer0_dout(52);    
    layer0_rd_object.z0                     <= signed(layer0_dout(61 downto 52));
    layer0_rd_object.phi                    <= signed(layer0_dout(51 downto 42));
    layer0_rd_object.eta                    <= signed(layer0_dout(41 downto 32));
    layer0_rd_object.otherPt                <= signed(layer0_dout(31 downto 16));
    layer0_rd_object.pt                     <= signed(layer0_dout(15 downto 0));

   
    -- ==========================================================================================
    gen_transfer_to_layer1 : if TRUE generate
    
        constant    BRAM_SMALL_REGION_STEP_SIZE : natural := 170; --1024/6         
        constant    LAYER_REGION_COUNT          : natural := 6;
                
        signal      layer1_we                   : std_logic := '0';
        signal      layer0_rd_en_sig            : std_logic := '0';
        signal      layer0_rd_en_latch          : std_logic;
        
        signal      layer1_waddr                : std_logic_vector(LAYER_BRAM_ADDR_SIZE-1 downto 0);
        
        type layer1_small_region_waddr_arr_t is array(integer range <>) of unsigned(LAYER_BRAM_ADDR_SIZE-1 downto 0);
        signal      layer1_waddr_arr            : layer1_small_region_waddr_arr_t(LAYER_REGION_COUNT-1 downto 0);
        signal      layer1_waddr_base_arr       : layer1_small_region_waddr_arr_t(LAYER_REGION_COUNT-1 downto 0);
        signal      layer1_waddr_big_region_end_arr       : layer1_small_region_waddr_arr_t(LAYER_REGION_COUNT-1 downto 0);
        
        signal      layer1_raddr                : std_logic_vector(LAYER_BRAM_ADDR_SIZE-1 downto 0);
        signal      layer1_din                  : std_logic_vector(PHYSICS_OBJECT_BIT_SIZE-1 downto 0);
        
        signal      layer1_transfer_state       : unsigned(7 downto 0) := (others => '0');
        
        signal      layer0_eta_phi_index_object : get_eta_phi_small_region_t;
        signal      layer0_rd_object_latch      : physics_object_t;
        signal      layer0_rd_big_region_end_latch : std_logic;
        
        
        signal      debug_layer0_eta_index, debug_layer0_eta_overlap_index      : integer;
        signal      debug_layer0_phi_index, debug_layer0_phi_overlap_index      : integer;  
    begin     
    
        layer0_rd_en                        <= layer0_rd_en_sig and (not layer0_empty);
        
        transfer_to_layer1_buffer_process : process(clk240)
            variable layer1_waddr_base          : unsigned(LAYER_BRAM_ADDR_SIZE-1 downto 0) := (others => '0');
            variable s                          : natural; --small region index shorthand
        begin
            
            if(rising_edge(clk240)) then
            
                s                           := layer0_eta_phi_index_object.eta_phi_small_region;
                layer0_rd_en_sig            <= '0';
                layer1_we                   <= '0';
                layer0_rd_en_latch          <= layer0_rd_en; --monitor when read enable actually happens
                
-- ============= -- primary reset or not if statement         
                if (reset = '1') then                
                    layer1_transfer_state                   <= (others => '0');
                    layer0_eta_phi_index_object.is_another  <= '0';
                    
                    --initialize write address arrays
                    for i in 0 to LAYER_REGION_COUNT-1 loop
                        layer1_waddr_arr(i)                 <= layer1_waddr_base;
                        layer1_waddr_base_arr(i)            <= layer1_waddr_base;
                        layer1_waddr_big_region_end_arr(i)  <= layer1_waddr_base;
                        layer1_waddr_base                   := layer1_waddr_base + BRAM_SMALL_REGION_STEP_SIZE; 
                    end loop;
                    
                else --not reset 
                
                    --behavior:
                    --  get first small region
                    --  write to next RAM position for small region
                    --      writing means controlling the write address
                    --  if another small region, get it, and repeat 
                    if(layer0_rd_en_latch = '0' and layer1_transfer_state = 1) then --ignore read on empty fifo
                        layer0_eta_phi_index_object.is_another  <= '0'; --clear
                        layer1_transfer_state                   <= (others => '0'); --reset transfer state    
                    elsif(layer1_transfer_state > 0) then
                    
                        -- write to RAM position associated with small region
                        layer1_waddr            <= std_logic_vector(layer1_waddr_arr(s));
                        layer1_we               <= '1';
                        
                        --capture end waddrs for every small region at end of big region
                        if(layer0_rd_big_region_end_latch = '1') then
                            for i in 0 to LAYER_REGION_COUNT-1 loop
                                layer1_waddr_big_region_end_arr(i) <= layer1_waddr_arr(i); 
                            end loop;
                        end if;
                        
                        -- and increment write address
                        if(layer1_waddr_arr(s) + 1 < 
                            layer1_waddr_base_arr(s) + BRAM_SMALL_REGION_STEP_SIZE) then
                            layer1_waddr_arr(s) <= layer1_waddr_arr(s) + 1;
                        else -- wrap around case
                            layer1_waddr_arr(s) <= layer1_waddr_base_arr(s);
                        end if;   
                        
                        -- if another, go on, else check for another physics object
                        if(layer0_eta_phi_index_object.is_another = '1') then
                            layer1_transfer_state <= layer1_transfer_state + 1;
                            layer0_eta_phi_index_object <= 
                                get_eta_phi_small_region(
                                    layer0_rd_object_latch.eta,
                                    layer0_rd_object_latch.phi,
                                    to_integer(layer1_transfer_state)); -- get next overlapping small region   
                        else
                            layer1_transfer_state <= (others => '0'); --reset transfer state
                        end if;
                        
                        
                        --TODO -- check for overflow error catching up to raddr  
                                                
                        
                    end if; -- end transfer states > 0   
                                               
                    -- when idle, check for new data    
                    if(layer0_eta_phi_index_object.is_another = '0' and 
                        layer0_empty = '0') then -- have new data!
                        
                        layer1_transfer_state       <= (0 => '1', others => '0'); -- proceed to state = 1
                        layer0_rd_object_latch      <= layer0_rd_object;
                        layer0_rd_big_region_end_latch <= layer0_rd_big_region_end;
                        layer0_rd_en_sig            <= '1'; --retrieve next data from layer0                        
                                
                        layer0_eta_phi_index_object <= 
                            get_eta_phi_small_region(
                                layer0_rd_object.eta,
                                layer0_rd_object.phi,
                                0); -- get first small region first                                                            
                    
                        --for debugging
                        debug_layer0_eta_index      <= 
                                                    get_eta_small_region_index(
                                                        layer0_rd_object.eta,
                                                        0); -- get first small region for debugging  
                        debug_layer0_phi_index      <= 
                                                    get_phi_small_region_index(
                                                        layer0_rd_object.phi,
                                                        0); -- get first small region for debugging  
                        debug_layer0_eta_overlap_index      <= 
                                                    get_eta_small_region_index(
                                                        layer0_rd_object.eta,
                                                        1); -- get first small region for debugging  
                        debug_layer0_phi_overlap_index      <= 
                                                    get_phi_small_region_index(
                                                        layer0_rd_object.phi,
                                                        1); -- get first small region for debugging  
                                
                    end if;
                    
                    
                end if;
-- ============= -- end primary reset or not if statement
                
            end if; --end rising edge if
       
        end process transfer_to_layer1_buffer_process;   
        
        
        layer1_din(63)                        <= layer0_rd_object_latch.quality;
        layer1_din(62)                        <= '0';
        layer1_din(52)                        <= layer0_rd_object_latch.lsEM;
        layer1_din(61 downto 52)              <= std_logic_vector(layer0_rd_object_latch.z0);
        layer1_din(51 downto 42)              <= std_logic_vector(layer0_rd_object_latch.phi);
        layer1_din(41 downto 32)              <= std_logic_vector(layer0_rd_object_latch.eta);
        layer1_din(31 downto 16)              <= std_logic_vector(layer0_rd_object_latch.otherPt);
        layer1_din(15 downto 0)               <= std_logic_vector(layer0_rd_object_latch.pt);
        
        layer1_bram: physics_object_bram
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
                wea(0)              => layer1_we,
                addra               => layer1_waddr,
                dina                => layer1_din,
                douta               => open,
                clkb                => clk240,
                web(0)              => '0',
                addrb               => layer1_raddr,
                dinb                => (others => '0'),
                doutb               => layer1_dout
            );  

    end generate gen_transfer_to_layer1;
    
          
end Behavioral;
