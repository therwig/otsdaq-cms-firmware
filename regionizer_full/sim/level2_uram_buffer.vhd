----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/02/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level2_uram_buffer - Behavioral
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
use work.regionizer_params_pkg.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity level2_uram_buffer is
    generic (
        SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM;
        OBJECTS_PER_SMALL_REGION: integer := 5
    );
    port (         
        clk_level1_to_2         : in std_logic;
        
        level1_big_region_end   : in std_logic;
        
        object_we_in            : in std_logic;
        small_region_windex     : in integer range 0 to SMALL_REGIONS_PER_RAM-1;
        object_in               : in physics_object_t;
        
        robject_re_in           : in std_logic;
        small_region_rindex     : in integer range 0 to SMALL_REGIONS_PER_RAM-1;
        robject_valid           : out std_logic;
        robject_dout            : out physics_object_t;
        
        -- overflow not possible.. overflow_error          : out std_logic;
        reset                   : in std_logic
    );
end level2_uram_buffer;

architecture Behavioral of level2_uram_buffer is

    constant    LEVEL_RAM_ADDR_SIZE        : natural := 12; --bits
     
    
begin

    --  This is a Level-2 RAM, which stacks up objects for SMALL_REGIONS_PER_RAM
    --      small-regions.
    --      e.g. SMALL_REGIONS_PER_RAM = 3
    --          then this component would split up its RAM address space into 3
    --          sections, and ojbects would get stacked up in those 3 sections
    --          until reset or a new big-region.
    
    --  Write behavior:
    --      Each object in has a specified small-region write index, use that
    --          to determine the stack within the RAM to which to add the object.
    --          increment that stacks address with each write.
    -- 
    -- Read behavior:
    --      The read sequence for this RAM is pre-defined, so a reset and strobe fully
    --          defines the read behavior. First, small-region 0 stack is read one by one
    --          and then then next small-region, and so on.
   
    -- ==========================================================================================
    gen_transfer_to_level2 : if TRUE generate
                     
        constant    RAM_DEPTH                   : natural := 4096; 
        constant    RAM_SMALL_REGION_STEP_SIZE  : natural := 
            RAM_DEPTH / SMALL_REGIONS_PER_RAM / 2; -- by 2 for odd/event big-regions
                
        signal      we                          : std_logic := '0';
        signal      re                          : std_logic := '0';
        
        signal      waddr                       : std_logic_vector(LEVEL_RAM_ADDR_SIZE-1 downto 0) := (others => '0');
               
        
        type small_region_addr_arr_t is array(integer range <>) of unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
        type ram_addr_arr_t is array(1 downto 0) of small_region_addr_arr_t(SMALL_REGIONS_PER_RAM-1 downto 0);
        
        signal      waddr_arr                   : ram_addr_arr_t := (others => (others => (others => '0')));
        signal      waddr_base_arr              : small_region_addr_arr_t(SMALL_REGIONS_PER_RAM-1 downto 0)  := (others => (others => '0'));        
        signal      raddr_arr                   : small_region_addr_arr_t(SMALL_REGIONS_PER_RAM-1 downto 0)  := (others => (others => '0'));
        
        signal      raddr                       : std_logic_vector(LEVEL_RAM_ADDR_SIZE-1 downto 0) := (others => '0');
        signal      din                         : raw_physics_object_t := (others => '0');
        
        signal      robject_valid_sig           : std_logic := '0';
        signal      dout                        : raw_physics_object_t;
        signal      object_out                  : physics_object_t;
                       
        constant    READ_LATENCY                : natural := 2;
        type debug_small_region_arr_t is array(READ_LATENCY-1 downto 0) of integer;
        signal      debug_small_region_index    : debug_small_region_arr_t;
        
        signal      debug_no_more_data          : std_logic := '0'; 
         
    begin     
    
        robject_valid       <= robject_valid_sig;
        
        object_out          <= convert_raw_to_physics_object(dout);
                    
        robject_dout        <= object_out when robject_valid_sig = '1' else null_physics_object;
        
        
        level2_addr_process : process(clk_level1_to_2)
                        
            variable s, rs                      : natural; --small region index shorthand  
            variable tmp_addr_base              : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);          
            variable target_waddr               : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            variable target_waddr_base          : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            
            variable target_raddr               : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
            variable target_raddr_end           : unsigned(LEVEL_RAM_ADDR_SIZE-2 downto 0);
        begin
                        
            if(rising_edge(clk_level1_to_2)) then
            
                s                           := small_region_windex;
                rs                          := small_region_rindex;
                we                          <= '0';
                
                debug_small_region_index    <= debug_small_region_index(READ_LATENCY-2 downto 0) & 
                    small_region_rindex;
                
                target_waddr                := waddr_arr(
                                to_integer(unsigned'("" & 
                                    waddr(LEVEL_RAM_ADDR_SIZE-1))))
                                    (s);
                target_waddr_base           := waddr_base_arr(s);
                                    
                re                          <= '0';
                robject_valid_sig           <= re; --read object out if read enable was successful
                                    
                
                target_raddr                := raddr_arr(rs);
                target_raddr_end            := waddr_arr(
                                to_integer(unsigned'("" & 
                                    (not waddr(LEVEL_RAM_ADDR_SIZE-1)))))
                                    (rs);
                                      
                
-- ============= -- primary reset or not if statement         
                if (reset = '1') then                
                    
                    waddr                           <= (others => '0');
                    raddr                           <= (others => '0');
                    
                    debug_no_more_data              <= '0';
                    
                    --initialize write address arrays
                    for i in 0 to 1 loop
                        tmp_addr_base := (others => '0');
                        for j in 0 to SMALL_REGIONS_PER_RAM-1 loop
                            waddr_arr(i)(j)              <= tmp_addr_base;
                            
                            if i = 0 then --only need one set of these
                                waddr_base_arr(j)        <= tmp_addr_base;
                                raddr_arr(j)             <= tmp_addr_base;
                            end if;
                                               
                            tmp_addr_base                   := tmp_addr_base + RAM_SMALL_REGION_STEP_SIZE; 
                        end loop;
                    end loop;
                    
                    
                else --not reset 
                
                
                    if ( level1_big_region_end = '1') then 
                        --when big-region ends, toggle high order bit
                        -- and reset waddr for new big-region
                        
                        waddr(LEVEL_RAM_ADDR_SIZE-1)    <= 
                            not waddr(LEVEL_RAM_ADDR_SIZE-1);
                        raddr(LEVEL_RAM_ADDR_SIZE-1)    <=  --reads from non-write half   
                            waddr(LEVEL_RAM_ADDR_SIZE-1); 
                        
                        debug_no_more_data              <= '0';
                        
                        --reset write address arrays for new target big-region (use not)
                        tmp_addr_base := (others => '0');
                        for j in 0 to SMALL_REGIONS_PER_RAM-1 loop
                            waddr_arr(
                                to_integer(unsigned'("" & 
                                    (not waddr(LEVEL_RAM_ADDR_SIZE-1)))))(j)              
                                                                    <= tmp_addr_base;
                            raddr_arr(j)                     <= tmp_addr_base;
                            tmp_addr_base                    := tmp_addr_base + RAM_SMALL_REGION_STEP_SIZE; 
                        end loop;
                            
                    
                    end if; -- end handle end of big-region
                
                    --behavior:
                    --  write to small-region based on input eta-phi index
                    --      writing increments that small-region write address
                    --      for next data.
                     
                    if (object_we_in = '1') then
                    
                        -- write to RAM position associated with small region
                        waddr(LEVEL_RAM_ADDR_SIZE-2 downto 0)    <= 
                                std_logic_vector(target_waddr);
                                
                        we     <= '1';                        
                        din    <= convert_physics_object_to_raw(object_in);                       
                        
                        -- increment write address
                        if(target_waddr + 1 < 
                            target_waddr_base + OBJECTS_PER_SMALL_REGION) then
                            
                            waddr_arr(
                                to_integer(unsigned'("" & 
                                    waddr(LEVEL_RAM_ADDR_SIZE-1))))
                                    (s) <= target_waddr + 1;
                                    
                        end if;                
                        
                    end if; -- end if we 
                    
                    
                    if (robject_re_in = '1') then
                    
                        -- increment read address if there is more data
                        if(target_raddr  < target_raddr_end) then
                            re                   <= '1';
                            raddr(LEVEL_RAM_ADDR_SIZE-2 downto 0) <= 
                                std_logic_vector(target_raddr);
                            raddr_arr(rs)        <= target_raddr + 1;
                        else -- no more data
                            debug_no_more_data <= '1';
                        end if; 
                        
                    end if; -- end if re  
                    
                    
                end if;
-- ============= -- end primary reset or not if statement
                
            end if; --end rising edge if
       
        end process level2_addr_process;   
            
-- ===== -- start uram generate
        gen_level2_uram : if TRUE generate
            
            constant URAM_ADDR_SIZE         : natural := 23; --bits
            constant URAM_DATA_SIZE         : natural := 72; --bits
            
            signal ram_din_we                   : std_logic_vector(8 downto 0);
            signal ram_waddr                    : std_logic_vector(22 downto 0);
            signal ram_din                      : std_logic_vector(71 downto 0);
            
            signal ram_raddr                    : std_logic_vector(22 downto 0);
            signal ram_dout                     : std_logic_vector(71 downto 0);
                        
        begin 
        
            ram_din_we      <= (others => we);
            
            ram_waddr(URAM_ADDR_SIZE-1 downto URAM_ADDR_SIZE-LEVEL_RAM_ADDR_SIZE)   <= 
                waddr;
            ram_waddr(URAM_ADDR_SIZE-LEVEL_RAM_ADDR_SIZE-1 downto 0)                <= 
                (others => '0');
            
            ram_din(URAM_DATA_SIZE-1 downto PHYSICS_OBJECT_BIT_SIZE-1)              <= 
                (others => '0');
            ram_din(PHYSICS_OBJECT_BIT_SIZE-1 downto 0)                             <= 
                din;
            
            ram_raddr(URAM_ADDR_SIZE-1 downto URAM_ADDR_SIZE-LEVEL_RAM_ADDR_SIZE)   <= 
                raddr;
            ram_raddr(URAM_ADDR_SIZE-LEVEL_RAM_ADDR_SIZE-1 downto 0)                <= 
                (others => '0');
                
            dout                                     <= ram_dout(PHYSICS_OBJECT_BIT_SIZE-1 downto 0);
        
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
              CLK => clk_level1_to_2,           -- 1-bit input: Clock source
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
           
        end generate gen_level2_uram;
-- ===== -- end uram generate

   end generate gen_transfer_to_level2; 
          
end Behavioral;
