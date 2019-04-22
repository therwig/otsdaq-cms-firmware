----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level1_uram_buffer - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

entity level1_uram_buffer is
    port ( 
        
        clk_link_to_level1     : in std_logic;
        
        link_big_region_end     : in std_logic;
        
        link_object_in          : in physics_object_t;
        link_object_we_in       : in std_logic;
        wobject_eta_phi_index   : in get_eta_phi_small_region_t;
        
        level2_re_in            : in std_logic;
        robject_eta_phi_index   : in get_eta_phi_small_region_t;
        robject_valid           : out std_logic;
        robject_dout            : out raw_phyiscs_object_t;
                
        overflow_error          : out std_logic;
        reset                   : in std_logic
    );
end level1_uram_buffer;

architecture Behavioral of level1_uram_buffer is

    constant    LEVEL_RAM_ADDR_SIZE        : natural := 12; --bits
     
    
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
    gen_transfer_to_level1 : if TRUE generate
    
                 
        constant    LEVEL_SMALL_REGION_COUNT    : natural := 
            ALGO_INPUT_SMALL_REGION_ETA_SIZE * ALGO_INPUT_SMALL_REGION_PHI_SIZE;
        constant    RAM_DEPTH                   : natural := 4096; 
        constant    RAM_SMALL_REGION_STEP_SIZE  : natural := 
            RAM_DEPTH / LEVEL_SMALL_REGION_COUNT / 2; -- by 2 for odd/event big-regions
                
        signal      level1_we                   : std_logic := '0';
        signal      level1_re                   : std_logic := '0';
        signal      no_more_data                : std_logic;
        
        signal      level1_waddr                : std_logic_vector(LEVEL_RAM_ADDR_SIZE-1 downto 0);
               
        
        type level1_small_region_addr_arr_t is array(integer range <>) of unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
        type level1_ram_addr_arr_t is array(1 downto 0) of level1_small_region_addr_arr_t(LEVEL_SMALL_REGION_COUNT-1 downto 0);
        
        signal      level1_waddr_arr            : level1_ram_addr_arr_t;
        signal      level1_waddr_base_arr       : level1_ram_addr_arr_t;        
        signal      level1_raddr_arr            : level1_small_region_addr_arr_t(LEVEL_SMALL_REGION_COUNT-1 downto 0);
        
        signal      level1_raddr                : std_logic_vector(LEVEL_RAM_ADDR_SIZE-1 downto 0);
        signal      level1_din                  : raw_phyiscs_object_t;
        signal      level1_dout                 : raw_phyiscs_object_t;
                
         
    begin     
    
        
        
        level1_addr_process : process(clk_link_to_level1)
            variable level1_addr_base           : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            variable s, rs                      : natural; --small region index shorthand            
            variable target_waddr               : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            variable target_waddr_base          : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            
            variable target_raddr               : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            variable target_raddr_end           : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
        begin
            
            if(rising_edge(clk_link_to_level1)) then
            
                s                           := wobject_eta_phi_index.eta_phi_small_region;
                rs                          := robject_eta_phi_index.eta_phi_small_region;
                level1_we                   <= '0';
                
                target_waddr                := level1_waddr_arr(
                                to_integer(unsigned'("" & 
                                    level1_waddr(LEVEL_RAM_ADDR_SIZE-1))))
                                    (s);
                                    
                level1_re                   <= '0';
                no_more_data                <= '0';
                robject_valid               <= '0';
                
                target_raddr                := level1_raddr_arr(rs);
                target_raddr_end            := level1_waddr_arr(
                                to_integer(unsigned'("" & 
                                    (not level1_waddr(LEVEL_RAM_ADDR_SIZE-1)))))
                                    (rs);
                                      
                
-- ============= -- primary reset or not if statement         
                if (reset = '1') then                
                    
                    overflow_error <= '0';
                    
                    --initialize write address arrays
                    for i in 0 to 1 loop
                        level1_addr_base := (others => '0');
                        for j in 0 to LEVEL_SMALL_REGION_COUNT-1 loop
                            level1_waddr_arr(i)(j)              <= level1_addr_base;
                            level1_waddr_base_arr(i)(j)         <= level1_addr_base;
                            
                            if i = 0 then
                                level1_raddr_arr(j)             <= level1_addr_base;
                            end if;
                                               
                            level1_addr_base                   := level1_addr_base + RAM_SMALL_REGION_STEP_SIZE; 
                        end loop;
                    end loop;
                    
                    
                else --not reset 
                
                
                    if ( link_big_region_end = '1') then 
                        --when big-region ends, toggle high order bit
                        -- and reset waddr for new big-region
                        
                        level1_waddr(LEVEL_RAM_ADDR_SIZE-1) <= 
                            not level1_waddr(LEVEL_RAM_ADDR_SIZE-1);
                        
                        --reset write address arrays for new target big-region (use not)
                        level1_addr_base := (others => '0');
                        for j in 0 to LEVEL_SMALL_REGION_COUNT-1 loop
                            level1_waddr_arr(
                                to_integer(unsigned'("" & 
                                    (not level1_waddr(LEVEL_RAM_ADDR_SIZE-1)))))(j)              
                                                                    <= level1_addr_base;
                            level1_raddr_arr(j)                     <= level1_addr_base;
                            level1_addr_base                        := level1_addr_base + RAM_SMALL_REGION_STEP_SIZE; 
                        end loop;
                            
                    
                    end if; -- end handle end of big-region
                
                    --behavior:
                    --  write to small-region based on input eta-phi index
                    --      writing increments that small-region write address
                    --      for next data.
                     
                    if (link_object_we_in = '1') then
                    
                        -- write to RAM position associated with small region
                        level1_waddr(LEVEL_RAM_ADDR_SIZE-2 downto 0) <= 
                                std_logic_vector(target_waddr);
                        level1_we            <= '1';
                        
                        level1_din(63)                        <= link_object_in.quality;
                        level1_din(62)                        <= '0'; 
                        level1_din(52)                        <= link_object_in.lsEM;
                        level1_din(61 downto 52)              <= std_logic_vector(link_object_in.z0);
                        level1_din(51 downto 42)              <= std_logic_vector(link_object_in.phi);
                        level1_din(41 downto 32)              <= std_logic_vector(link_object_in.eta);
                        level1_din(31 downto 16)              <= std_logic_vector(link_object_in.otherPt);
                        level1_din(15 downto 0)               <= std_logic_vector(link_object_in.pt);                        
                        
                        -- increment write address
                        if(target_waddr + 1 < 
                            target_waddr_base + RAM_SMALL_REGION_STEP_SIZE) then
                            level1_waddr_arr(
                                to_integer(unsigned'("" & 
                                    level1_waddr(LEVEL_RAM_ADDR_SIZE-1))))
                                    (s) <= target_waddr + 1;
                        else -- wrap around case
                            overflow_error <= '1';
                        end if;                
                        
                    end if; -- end if we 
                    
                    
                    if (level2_re_in = '1') then
                    
                        -- increment read address if there is more data
                        if(target_raddr  < target_raddr_end) then
                            level1_re                   <= '1';
                            level1_raddr(LEVEL_RAM_ADDR_SIZE-2 downto 0) <= 
                                std_logic_vector(target_raddr);
                            level1_raddr_arr(rs)        <= target_raddr + 1;
                        else -- no more data
                            no_more_data <= '1';
                        end if; 
                        
                    end if; -- end if re  
                    
                    --read object out if read enable was successful
                    if (level1_re = '1') then
                        robject_dout <= level1_dout;
                        robject_valid <= '1';
                    else
                        robject_dout <= (others => '0');
                    end if;
                    
                end if;
-- ============= -- end primary reset or not if statement
                
            end if; --end rising edge if
       
        end process level1_addr_process;   
            
-- ===== -- start uram generate
        gen_level1_uram : if TRUE generate
            
            constant URAM_ADDR_SIZE         : natural := 23; --bits
            constant URAM_DATA_SIZE         : natural := 72; --bits
            
            signal ram_din_we                   : std_logic_vector(8 downto 0);
            signal ram_waddr                    : std_logic_vector(22 downto 0);
            signal ram_din                      : std_logic_vector(71 downto 0);
            
            signal ram_raddr                    : std_logic_vector(22 downto 0);
            signal ram_dout                     : std_logic_vector(71 downto 0);
                        
        begin 
        
            ram_din_we      <= (others => level1_we);
            
            ram_waddr(URAM_ADDR_SIZE-1 downto 22-LEVEL_RAM_ADDR_SIZE+1) <= 
                level1_waddr;
            ram_waddr(URAM_ADDR_SIZE-LEVEL_RAM_ADDR_SIZE downto 0)      <= 
                (others => '0');
            
            ram_din(URAM_DATA_SIZE-1 downto PHYSICS_OBJECT_BIT_SIZE-1)  <= 
                (others => '0');
            ram_din(PHYSICS_OBJECT_BIT_SIZE-1 downto 0)                 <= 
                level1_din;
            
            ram_raddr(URAM_ADDR_SIZE-1 downto 22-LEVEL_RAM_ADDR_SIZE+1) <= level1_raddr;
            ram_raddr(URAM_ADDR_SIZE-LEVEL_RAM_ADDR_SIZE downto 0)      <= (others => '0');
            level1_dout                                     <= ram_dout(PHYSICS_OBJECT_BIT_SIZE-1 downto 0);
        
            -- =========================
            -- URAM288_BASE: 288K-bit High-Density Base Memory Building Block
            --               Virtex UltraScale+
            --                   72b x 4096
            -- Xilinx HDL Language Template, version 2018.3
            --   NOTE: should read from A and write to B because A reads happen first.
            
            URAM288_BASE_inst : URAM288_BASE
            generic map (
              AUTO_SLEEP_LATENCY => 8,            -- Latency requirement to enter sleep mode
              AVG_CONS_INACTIVE_CYCLES => 10,     -- Average consecutive inactive cycles when is SLEEP mode for power
                                                  -- estimation
              BWE_MODE_A => "PARITY_INTERLEAVED", -- Port A Byte write control
              BWE_MODE_B => "PARITY_INTERLEAVED", -- Port B Byte write control
              EN_AUTO_SLEEP_MODE => "FALSE",      -- Enable to automatically enter sleep mode
              EN_ECC_RD_A => "FALSE",             -- Port A ECC encoder
              EN_ECC_RD_B => "FALSE",             -- Port B ECC encoder
              EN_ECC_WR_A => "FALSE",             -- Port A ECC decoder
              EN_ECC_WR_B => "FALSE",             -- Port B ECC decoder
              IREG_PRE_A => "FALSE",              -- Optional Port A input pipeline registers
              IREG_PRE_B => "FALSE",              -- Optional Port B input pipeline registers
              IS_CLK_INVERTED => '0',             -- Optional inverter for CLK
              IS_EN_A_INVERTED => '0',            -- Optional inverter for Port A enable
              IS_EN_B_INVERTED => '0',            -- Optional inverter for Port B enable
              IS_RDB_WR_A_INVERTED => '0',        -- Optional inverter for Port A read/write select
              IS_RDB_WR_B_INVERTED => '0',        -- Optional inverter for Port B read/write select
              IS_RST_A_INVERTED => '0',           -- Optional inverter for Port A reset
              IS_RST_B_INVERTED => '0',           -- Optional inverter for Port B reset
              OREG_A => "FALSE",                  -- Optional Port A output pipeline registers
              OREG_B => "FALSE",                  -- Optional Port B output pipeline registers
              OREG_ECC_A => "FALSE",              -- Port A ECC decoder output
              OREG_ECC_B => "FALSE",              -- Port B output ECC decoder
              RST_MODE_A => "SYNC",               -- Port A reset mode
              RST_MODE_B => "SYNC",               -- Port B reset mode
              USE_EXT_CE_A => "FALSE",            -- Enable Port A external CE inputs for output registers
              USE_EXT_CE_B => "FALSE"             -- Enable Port B external CE inputs for output registers
            )
            port map (
              DBITERR_A => open,                    -- 1-bit output: Port A double-bit error flag status
              DBITERR_B => open,                    -- 1-bit output: Port B double-bit error flag status
              DOUT_A => ram_dout,                   -- 72-bit output: Port A read data output
              DOUT_B => open,                       -- 72-bit output: Port B read data output
              SBITERR_A => open,                    -- 1-bit output: Port A single-bit error flag status
              SBITERR_B => open,                    -- 1-bit output: Port B single-bit error flag status
              ADDR_A => ram_raddr,                  -- 23-bit input: Port A address
              ADDR_B => ram_waddr,                  -- 23-bit input: Port B address
              BWE_A => (others => '0'),             -- 9-bit input: Port A Byte-write enable
              BWE_B => ram_din_we,                  -- 9-bit input: Port B Byte-write enable
              CLK => clk_link_to_level1,           -- 1-bit input: Clock source
              DIN_A => (others => '0'),             -- 72-bit input: Port A write data input
              DIN_B => ram_din,                     -- 72-bit input: Port B write data input
              EN_A => '1',                          -- 1-bit input: Port A enable
              EN_B => '1',                          -- 1-bit input: Port B enable
              INJECT_DBITERR_A => '0',              -- 1-bit input: Port A double-bit error injection
              INJECT_DBITERR_B => '0',              -- 1-bit input: Port B double-bit error injection
              INJECT_SBITERR_A => '0',              -- 1-bit input: Port A single-bit error injection
              INJECT_SBITERR_B => '0',              -- 1-bit input: Port B single-bit error injection
              OREG_CE_A => '1',                     -- 1-bit input: Port A output register clock enable
              OREG_CE_B => '0',                     -- 1-bit input: Port B output register clock enable
              OREG_ECC_CE_A => '0',                 -- 1-bit input: Port A ECC decoder output register clock enable
              OREG_ECC_CE_B => '0',                 -- 1-bit input: Port B ECC decoder output register clock enable
              RDB_WR_A => '0',                      -- 1-bit input: Port A read/write select
              RDB_WR_B => '1',                      -- 1-bit input: Port B read/write select
              RST_A => reset,                       -- 1-bit input: Port A asynchronous or synchronous reset for output
                                                    -- registers
            
              RST_B => reset,                       -- 1-bit input: Port B asynchronous or synchronous reset for output
                                                    -- registers
            
              SLEEP => '0'                          -- 1-bit input: Dynamic power gating control
            );
    
            -- End of URAM288_BASE_inst instantiation
           
        end generate gen_level1_uram;
-- ===== -- end uram generate

   end generate gen_transfer_to_level1; 
          
end Behavioral;
