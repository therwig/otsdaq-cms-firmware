----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level2_ram_buffer - Behavioral
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

use work.regionizer_params_pkg.all;



-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity level2_ram_buffer is
    generic (
        SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM;
        PARALLEL_OBJECT_RAMS    : integer := LEVEL2_PARALLEL_OBJECT_RAMS;
        SHARED_BUFFER_INDEX     : integer;  --use for debugging to label data out
        OBJECTS_TO_ALGO         : integer := 25
    );
    port ( 
        clk_level1_to_2         : in  std_logic;
        
        level1_big_region_end   : in  std_logic;
        
        object_pipe_in          : in  level1_to_2_pipe_t;
        
        next_big_region         : out std_logic;
        small_region_closed     : out std_logic_vector(SMALL_REGIONS_PER_RAM-1 downto 0);  
        
        robjects_re             : in  std_logic;
        robjects_out_valid      : out std_logic_vector(PARALLEL_OBJECT_RAMS-1 downto 0);
        robjects_out            : out physics_object_arr_t(PARALLEL_OBJECT_RAMS-1 downto 0);
        
        -- overflow not possible.. overflow_error          : out std_logic;
        reset                   : in std_logic
    );
end level2_ram_buffer;

architecture Behavioral of level2_ram_buffer is
   

    component level2_uram_buffer  
        generic (
            SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM;
            SHARED_BUFFER_INDEX     : integer;  --use for debugging to label data out
            OBJECTS_PER_SMALL_REGION: integer := OBJECTS_TO_ALGO/PARALLEL_OBJECT_RAMS
        ); 
        port (
            clk_level1_to_2         : in  std_logic;
            
            level1_big_region_end   : in  std_logic;
            
            object_we_in            : in  std_logic;
            small_region_windex     : in  integer range 0 to SMALL_REGIONS_PER_RAM-1;
            object_in               : in  physics_object_t;
            
            robject_re_in           : in  std_logic;
            small_region_rindex     : in  integer range 0 to SMALL_REGIONS_PER_RAM-1;
            robject_valid           : out std_logic;
            robject_dout            : out physics_object_t;
            
            -- overflow not possible.. overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level2_uram_buffer;
     

    signal object_in_latch              : physics_object_t;
    signal small_region_windex_latch    : integer range 0 to SMALL_REGIONS_PER_RAM-1 := 0;
    
           
    signal ram_din_we                   : std_logic_vector(PARALLEL_OBJECT_RAMS-1 downto 0) := (others => '0');
            
    signal debug_read_event_index       : natural := INVALID_EVENT_INDEX;
    
    signal small_region_rindex          : integer range 0 to SMALL_REGIONS_PER_RAM-1;
    signal robjects_out_valid_arr       : std_logic_vector(PARALLEL_OBJECT_RAMS-1 downto 0);
    
begin

    
    --  This is a Level-2 multiram buffer to aggregate detector objects for the algo
    --      This component is a single "small-region group buffer" .. many of theses
    --          components would comprise all the small-region object buffers.
    --      e.g. SMALL_REGIONS_PER_RAM = 3 and PARALLEL_OBJECT_RAMS = 5
    --          then this component would consist of 5 rams, and there would be 6
    --          more similar instances covering 3x6 = 18 small-regions; totaling 30 RAMs for 
    --          a detector (per link group).
    --
    --      Inputs come from a Level-1 FIFO stage.. one FIFO for each link for the detector
    --      Outputs go to the HLS algo, e.g. 25 objects for Tracker per small-region
    --    
    -- =====
    -- Write behavior:
    --  Each clock, one object can potentially be written to URAM (or potentially BRAM)
    --      Note: URAMs are dual port 72b x 4096    
    --      For a link group 18BX is available to transfer a big-region.. and
    --          if we start as soon as data is in the Level-1 FIFO then latency is negligible.
    --          18Bx @ 320 MHz is 8 x 18 = 144 clocks to write
    --  The objects that trickle in are determined by availabilty of the shift-register
    --      propagating through Level-1 FIFOs, and throttled by small-regions being closed out.
    --  
    --  each RAM is segmented into a small-region stack (size := OBJECTS_TO_ALGO /
    --      PARALLEL_OBJECT_RAMS) per small-region (SMALL_REGIONS_PER_RAM) per 
    --      big-region (2 placeholders)
    --  e.g.OBJECTS_TO_ALGO = 25, PARALLEL_OBJECT_RAMS = 5, SMALL_REGIONS_PER_RAM = 3
    --      would be 5 stack locations x 3 small-regions x 2 big-regions-places = 30 locations used per RAM
    --        
    --
    -- 
    -- =====
    -- Read behavior:
    --      Each re gets PARALLEL_OBJECT_RAMS objects out of the RAMs, stepping through
    --          each small-region stack and each small-region for the active big region.
    --      e.g. OBJECTS_TO_ALGO = 25, PARALLEL_OBJECT_RAMS = 5
    --          would readout all 25 objects for the small-region[0] after the first 5 re strobes
    
    
    -- ==========================================================================================
    gen_level2_we_process : if TRUE generate
              
        signal big_region_addr              : std_logic := '0';        
        
        type small_region_object_count_arr_t is array(natural range <> ) of integer range 0 to OBJECTS_TO_ALGO;
        signal small_region_object_count    : small_region_object_count_arr_t(SMALL_REGIONS_PER_RAM-1 downto 0) := (others => 0);
        
        type small_region_ram_pointer_arr_t is array(natural range <> ) of integer range 0 to PARALLEL_OBJECT_RAMS-1;  
        signal small_region_ram_pointer     : small_region_ram_pointer_arr_t(SMALL_REGIONS_PER_RAM-1 downto 0) := (others => 0);
        
        signal small_region_closed_sig      : std_logic_vector(SMALL_REGIONS_PER_RAM-1 downto 0) := (others => '0');
        
        --for debugging
        
        type counter_arr_t is array(natural range <> ) of unsigned(15 downto 0);
        signal debug_we_count               : unsigned(15 downto 0) := (others =>'0');
        signal debug_source_event_index     : natural := INVALID_EVENT_INDEX;
        
    begin
    
        small_region_closed     <= small_region_closed_sig;
    
        -- ========================================
        debug_count_process : process(clk_level1_to_2)
        begin
            if (rising_edge(clk_level1_to_2)) then
            
                if (level1_big_region_end = '1') then
                    big_region_addr <= not big_region_addr;
                
                    if (debug_read_event_index = INVALID_EVENT_INDEX) then
                        debug_read_event_index <= 0;
                    else
                        debug_read_event_index <= debug_source_event_index + 1;
                    end if;
                end if;
            
                if (reset = '1') then
                    debug_we_count <= (others =>'0');  
                else
                
                    if (level1_big_region_end = '1') then
                        debug_we_count <= (others => '0');
                    elsif (object_pipe_in.valid = '1') then
                        debug_we_count <= debug_we_count + 1;
                    end if;
                    
                end if;
                
            end if;
        end process debug_count_process;
        
                
        --  The objects that trickle in are determined by availabilty of the shift-register
        --      propagating through Level-1 FIFOs, and throttled by small-regions being closed out.
    
        process(clk_level1_to_2)
            variable object_count       :  integer range 0 to OBJECTS_TO_ALGO;
            variable ram_pointer        :  integer range 0 to PARALLEL_OBJECT_RAMS-1;
        begin
            
            
            
            if (rising_edge(clk_level1_to_2)) then
                            
                object_in_latch                 <= object_pipe_in.object;
                small_region_windex_latch       <= object_pipe_in.sr_ram_subindex;
                ram_din_we                      <= (others => '0');
            
                object_count                    := small_region_object_count(object_pipe_in.sr_ram_subindex);
                ram_pointer                     := small_region_ram_pointer(object_pipe_in.sr_ram_subindex);
                                
                         
                if (reset = '1') then                
                
                    small_region_object_count   <= (others => 0);  
                    small_region_ram_pointer    <= (others => 0);
                    small_region_closed_sig     <= (others => '0');                    
                    
                elsif (small_region_closed_sig(object_pipe_in.sr_ram_subindex) = '0' and 
                    object_pipe_in.valid = '1') then --if small-region is still open and have data
                                                      
                    ram_din_we(ram_pointer)                                     <= '1';
                    small_region_object_count(object_pipe_in.sr_ram_subindex)   <= object_count + 1;
                                                
                    --increment RAM pointer                                                
                    if (ram_pointer = PARALLEL_OBJECT_RAMS-1) then
                        --wrap around
                        small_region_ram_pointer(object_pipe_in.sr_ram_subindex) <= 0;
                    else
                        small_region_ram_pointer(object_pipe_in.sr_ram_subindex) <= ram_pointer + 1;
                    end if;
                    
                    -- check for small-region is closed
                    if(object_count = OBJECTS_TO_ALGO-1) then  
                        small_region_closed_sig(object_pipe_in.sr_ram_subindex)         <= '1';
                    end if;                        
                    
                end if; --end primary reset                
            
            
                -- handle end of big-region on write side
                --  Note: big_region_end indicates next clock would be first we for new big-region
                if (level1_big_region_end = '1') then
                    small_region_object_count   <= (others => 0);  
                    small_region_ram_pointer    <= (others => 0);
                    small_region_closed_sig     <= (others => '0'); --reopen small regions
                end if;
                  
            end if; --end rising edge if        
        end process;
        
    end generate gen_level2_we_process;
    
    
    -- ==========================================================================================
    gen_uram_buffers : for i in 0 to PARALLEL_OBJECT_RAMS-1 generate   
        signal robject_sig      : physics_object_t;
    begin        
        
        -- add debug_source_event_index to debug info to read objects        
        robjects_out(i) <= ( 
            phi                 => robject_sig.phi,
            eta                 => robject_sig.eta,
            quality             => robject_sig.quality,
            lsEM                => robject_sig.lsEM,
            z0                  => robject_sig.z0,
            otherPt             => robject_sig.otherPt,
            pt                  => robject_sig.pt,
            
            small_region        => robject_sig.small_region,
            source_fiber        => robject_sig.source_fiber,
            source_event_index  => debug_read_event_index
        ); 
        
        -- ========================================
        uram_buffer : level2_uram_buffer    
        
            generic map (
                SMALL_REGIONS_PER_RAM   => LEVEL2_SMALL_REGIONS_PER_RAM,
                SHARED_BUFFER_INDEX     => SHARED_BUFFER_INDEX,
                OBJECTS_PER_SMALL_REGION=> (OBJECTS_TO_ALGO + LEVEL2_PARALLEL_OBJECT_RAMS - 1) / LEVEL2_PARALLEL_OBJECT_RAMS -- ceil(OBJECTS_TO_ALGO / LEVEL2_PARALLEL_OBJECT_RAMS)
            )
            port map (
                clk_level1_to_2         => clk_level1_to_2,             --: in std_logic;
                
                level1_big_region_end   => level1_big_region_end,       --: in std_logic;
                
                object_we_in            => ram_din_we(i),               --: in std_logic;
                object_in               => object_in_latch,             --: in physics_object_t;
                small_region_windex     => small_region_windex_latch,   --: in integer range 0 to SMALL_REGIONS_PER_RAM-1
                
                robject_re_in           => robjects_re,                 --: in std_logic;
                small_region_rindex     => small_region_rindex,         --: in integer range 0 to SMALL_REGIONS_PER_RAM-1;
                robject_valid           => robjects_out_valid(i),       --: out std_logic;
                robject_dout            => robject_sig,                 --: out physics_object_t;
                
                reset                   => reset                        --: in std_logic
            );
    
    end generate gen_uram_buffers;
    
    
    -- ==========================================================================================
    gen_level2_re_process : if TRUE generate
            
        constant CLOCKS_TO_READ         : integer := (OBJECTS_TO_ALGO + LEVEL2_PARALLEL_OBJECT_RAMS - 1) / LEVEL2_PARALLEL_OBJECT_RAMS; -- ceil(OBJECTS_TO_ALGO/LEVEL2_PARALLEL_OBJECT_RAMS)
        
        signal read_count               : unsigned(3 downto 0) := (others => '0');
        
        signal debug_done_with_stack    : std_logic := '0';
        
    begin
    
        -- =====
        -- Read behavior:
        --      Each re gets PARALLEL_OBJECT_RAMS objects out of the RAMs, stepping through
        --          each small-region stack and each small-region for the active big region.
        --      e.g. OBJECTS_TO_ALGO = 25, PARALLEL_OBJECT_RAMS = 5
        --          would readout all 25 objects for the small-region[0] after the first 5 re strobes
        
        -- ========================================
        re_process : process(clk_level1_to_2)
        begin
            if (rising_edge(clk_level1_to_2)) then
                            
                debug_done_with_stack       <= '0';    
                
                if (reset = '1') then
                
                    small_region_rindex <= 0;
                    read_count          <= (others => '0');
                    
                else --else not reset
                
                    if (robjects_re = '1') then
                    
                        if(read_count = CLOCKS_TO_READ-1) then
                            --switch to next small-region sharing the RAM
                            read_count              <= (others => '0'); 
                            debug_done_with_stack   <= '1';
                    
                            if(small_region_rindex = SMALL_REGIONS_PER_RAM - 1) then
                                --wrap around back to first small-region sharing the RAM
                                small_region_rindex <= 0; 
                            else
                                small_region_rindex <= small_region_rindex + 1;
                            end if;
                        else --still reading from small-region stack
                            read_count <= read_count + 1;
                        end if;
                        
                    end if;
                    
                end if; --end primary reset if
                
            end if;
        end process re_process;
        
    end generate gen_level2_re_process;
    
          
end Behavioral;
