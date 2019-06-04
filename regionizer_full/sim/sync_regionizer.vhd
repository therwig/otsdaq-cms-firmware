----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/16/2019 11:23:13 AM
-- Design Name: rrivera at fnal dot gov
-- Module Name: sync_regionizer - Behavioral
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
use ieee.std_logic_misc.all;

use work.regionizer_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sync_regionizer is
   port ( 
        clk                     : in  std_logic;
        
        link0_event_end         : in  std_logic; 
        
        level1_next_event_out   : out input_group_bit_arr_t  (FIBER_GROUPS-1 downto 0);
        level2_next_event_out   : out level2_group_bit_arr_t (FIBER_GROUPS-1 downto 0);
        algo_group_valid        : out std_logic_vector (FIBER_GROUPS-1 downto 0);
        
        reset                   : in  std_logic
        
    );
end sync_regionizer;

architecture Behavioral of sync_regionizer is

    constant LINK_TO_LEVEL1_END_BX_LATENCY : integer := 1;
    constant LINK_TO_LEVEL2_END_BX_LATENCY : integer := 1;
    constant LEVEL2_TO_ALGO_LATENCY        : integer := 10;
     
    signal sync_start_latch         : std_logic_vector(1 downto 0) := (others => '0');
    
    constant CLOCKS_PER_2BX         : integer := 15; --for 300MHz, 15 clocks in 2x 40MHz 
               
    signal sync_started             : std_logic := '0';
    
    type group_18bx_subcount_arr_t is array(natural range <> ) of unsigned(8 downto 0);
    signal group_18bx_subcount      : group_18bx_subcount_arr_t(FIBER_GROUPS-1 downto 0) := (others => (others => '0'));
    
    signal sync_bx_runsubcount      : unsigned(8 downto 0) := (others => '0'); 
    signal sync_bx_subcount         : unsigned(5 downto 0) := (others => '0'); 
    signal sync_bx_count            : unsigned(5 downto 0) := (others => '0');
    signal sync_bx_wrapcount        : unsigned(5 downto 0) := (others => '0');
    
    
    type level1_group_int_arr_t is array(natural range <> ) of integer_arr_t(FIBERS_IN_GROUP-1 downto 0);
    type level2_group_int_arr_t is array(natural range <> ) of integer_arr_t(LEVEL2_SHARED_SMALL_REGION_RAMS-1 downto 0);
    constant LEVEL1_LATCH_DEPTH     : level1_group_int_arr_t(FIBER_GROUPS-1 downto 0) := (others => (others => 3));
    constant LEVEL2_LATCH_DEPTH     : level2_group_int_arr_t(FIBER_GROUPS-1 downto 0) := (others => (others => 3));
    constant VERTEX_LATCH_DEPTH     : integer_arr_t         (FIBER_GROUPS-1 downto 0) := (others => 3);
    
    
begin

    -- Behavior:
    --      Based on rising-edge of sync_start, start process for Level-1 to 
    --          Level-2 to Algo interplay. It should be a fixed latency process
    --          fully defined after reset by the rising-edge of sync_start for
    --          the rest of time.
    --
    --      e.g. Assume sync-start is the first end-of-event from link[0]; for 
    --          TMUX of 6 and 3 groups, then group[0] will close transfer out of 
    --          Level-1 18BX + some constant after the sync start. Then group[1] 
    --          will close 6BX after that, Then group[2] will close 6BX after that.
    --          Level-2 will start read process to algo after that close.. and 
    --          then stagger groups by 6BX also.
    --
    --      Note: Option for adding latency for each output to easy timing of sync
    --          signals.

    sync_process : process(clk)
    begin
    
        if (rising_edge(clk)) then
            
            sync_start_latch <= sync_start_latch(0) & link0_event_end;
            
            if (reset = '1') then
            
                sync_bx_count       <= (others => '0');
                sync_bx_subcount    <= (others => '0');
                sync_bx_runsubcount <= (others => '0');
                sync_bx_wrapcount   <= (others => '0');
                sync_started        <= '0';
                
            else --else not reset
            
                if (sync_started = '0' and sync_start_latch(1) = '0' and sync_start_latch(0) = '1') then --rising edge found of sync start!
                
                    sync_started        <= '1';
                    
                end if;
                
                
                  if(sync_started = '1') then
                    
                      sync_bx_runsubcount <= sync_bx_runsubcount + 1;
                                        
                      if(sync_bx_subcount < CLOCKS_PER_2BX) then
                          sync_bx_subcount <= sync_bx_subcount + 1;
                      else   -- wrap subcount                     
                          sync_bx_subcount <= (others => '0'); -- wrap subcount 
                                                    
                          if(sync_bx_count + 2 < 18) then
                              sync_bx_count <= sync_bx_count + 2;
                          else --wrap 18BX around 
                              sync_bx_count         <= (others => '0'); --wrap 18BX around 
                              sync_bx_runsubcount   <= (others => '0'); --wrap running sub-count at 18BX moment
                              sync_bx_wrapcount     <= sync_bx_wrapcount + 1;
                          end if;                            
                      end if;
                                                  
                  end if;
            
            end if; --end primary reset if
        end if; --rising edge if
    end process sync_process;
    
    
    -- ==========================================================================================
    gen_group_running_18bx_subcount : for g in 0 to FIBER_GROUPS-1 generate
        constant BX_COUNT_MATCH         : integer := g*6;
                
        signal group_18bx_has_reset     : std_logic := '0';
        signal group_18bx_reset         : std_logic := '0';
        signal group_18bx_reset_latch   : std_logic := '0';        
                 
        signal debug_group_18bx_reset   : std_logic := '0';       
    begin
        process(clk)
        begin
            if (rising_edge(clk)) then
            
                group_18bx_reset            <= '0';
                group_18bx_reset_latch      <= group_18bx_reset;
                
                debug_group_18bx_reset      <= '0';
                
                if ( reset = '1' ) then
                    group_18bx_has_reset <= '0';
                elsif ( group_18bx_reset = '1') then
                    group_18bx_has_reset <= '1';
                 end if;
                
                if(sync_bx_count = BX_COUNT_MATCH) then
                    group_18bx_reset        <= sync_started;
                end if;
                
                if(group_18bx_reset_latch = '0' and group_18bx_reset = '1') then
                    group_18bx_subcount(g)  <= (others => '0');
                    debug_group_18bx_reset  <= '1';
                elsif(sync_started = '1' and group_18bx_has_reset = '1') then
                    group_18bx_subcount(g)  <= group_18bx_subcount(g) + 1;
                end if;
                
            end if;                
        end process;                
    end generate gen_group_running_18bx_subcount;
    
    
    -- ==========================================================================================
    -- generate Level-1 next event signals
    gen_level1_next_event : for g in 0 to FIBER_GROUPS-1 generate
        constant BX_RUNSUBCOUNT_MATCH     : integer := LINK_TO_LEVEL1_END_BX_LATENCY*CLOCKS_PER_2BX/2;  
        
        signal debug_level1_next_event    : std_logic;
        signal debug_level1_next_event_arr: std_logic_vector(FIBERS_IN_GROUP-1 downto 0);        
    begin   
    
        debug_level1_next_event             <= or_reduce(debug_level1_next_event_arr);
        -- ==========================================================================================
        -- generate individual link shift register that will give synchronized strobe at each level-1 link buffer
        gen_level1_next_event_for_link : for i in 0 to FIBERS_IN_GROUP-1 generate
        
            constant LATCH_DEPTH                    : integer := LEVEL1_LATCH_DEPTH(g)(i);
            constant BX_LINK_RUNSUBCOUNT_LAUNCH     : integer := BX_RUNSUBCOUNT_MATCH - LATCH_DEPTH;
            
            signal link_shr                         : std_logic_vector(LATCH_DEPTH-1 downto 0);
            
        begin
        
            level1_next_event_out(g)(i)     <= link_shr(LATCH_DEPTH-1);
            
            level1_next_event_proc : process(clk)
            begin
                if (rising_edge(clk)) then
                
                    link_shr                        <= link_shr(LATCH_DEPTH-2 downto 0) & '0';      
                    debug_level1_next_event_arr(i)  <= '0';      
                            
                    if(group_18bx_subcount(g) = BX_LINK_RUNSUBCOUNT_LAUNCH) then
                        link_shr(0)                     <= '1'; 
                        debug_level1_next_event_arr(i)  <= '1';
                    end if;
                end if;                
            end process level1_next_event_proc;
            
        end generate gen_level1_next_event_for_link;
    end generate gen_level1_next_event;
    
    -- ==========================================================================================
    -- generate Level-2 next event signals
    gen_level2_next_event : for g in 0 to FIBER_GROUPS-1 generate
        constant BX_RUNSUBCOUNT_MATCH     : integer := LINK_TO_LEVEL2_END_BX_LATENCY*CLOCKS_PER_2BX/2; 
        
        signal debug_level2_next_event    : std_logic;
        signal debug_level2_next_event_arr: std_logic_vector(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);        
    begin      
                  
        debug_level2_next_event             <= or_reduce(debug_level2_next_event_arr);
        
        -- ==========================================================================================
        -- generate individual link shift register that will give synchronized strobe at each level-2 buffer
        gen_level2_next_event_for_buffer : for i in 0 to LEVEL1_TO_2_PIPE_COUNT-1 generate
        
            constant LATCH_DEPTH                    : integer := LEVEL2_LATCH_DEPTH(g)(i);
            constant BX_BUFER_RUNSUBCOUNT_LAUNCH    : integer := BX_RUNSUBCOUNT_MATCH - LATCH_DEPTH;
            
            signal next_event_shr                   : std_logic_vector(LATCH_DEPTH-1 downto 0);
            
        begin        
            level2_next_event_out(g)(i)     <= next_event_shr(LATCH_DEPTH-1);
              
            level2_next_event_proc : process(clk)
            begin
                if (rising_edge(clk)) then
                    
                    next_event_shr <= next_event_shr(LATCH_DEPTH-2 downto 0) & '0';    
                    debug_level2_next_event_arr(i)  <= '0';
                          
                    if(group_18bx_subcount(g) = BX_BUFER_RUNSUBCOUNT_LAUNCH) then
                        next_event_shr(0) <= '1'; 
                        debug_level2_next_event_arr(i)  <= '1';
                    end if;
                end if;                
            end process level2_next_event_proc;
            
        end generate gen_level2_next_event_for_buffer;
    end generate gen_level2_next_event;
    
    -- ==========================================================================================
    -- generate vertex select signals
    gen_algo_group_valid : for g in 0 to FIBER_GROUPS-1 generate
        constant BX_RUNSUBCOUNT_ON_MATCH        : integer := LINK_TO_LEVEL1_END_BX_LATENCY*CLOCKS_PER_2BX/2 + LEVEL2_TO_ALGO_LATENCY; 
        constant BX_RUNSUBCOUNT_OFF_MATCH       : integer := LINK_TO_LEVEL1_END_BX_LATENCY*CLOCKS_PER_2BX/2 + LEVEL2_TO_ALGO_LATENCY + SMALL_REGION_COUNT*2;
         
        constant LATCH_DEPTH                    : integer := VERTEX_LATCH_DEPTH(g);
        constant BX_VALID_RUNSUBCOUNT_ON        : integer := BX_RUNSUBCOUNT_ON_MATCH  - LATCH_DEPTH;
        constant BX_VALID_RUNSUBCOUNT_OFF       : integer := BX_RUNSUBCOUNT_OFF_MATCH - LATCH_DEPTH;
        
        signal valid                            : std_logic := '0';
        signal valid_shr                        : std_logic_vector(LATCH_DEPTH-1 downto 0);
    begin
        
        algo_group_valid(g)           <= valid_shr(LATCH_DEPTH-1);
        
        algo_valid_proc : process(clk)
        begin
            if (rising_edge(clk)) then
            
                valid_shr <= valid_shr(LATCH_DEPTH-2 downto 0) & valid;
                
                if   (group_18bx_subcount(g) = BX_VALID_RUNSUBCOUNT_ON) then
                    valid <= '1'; 
                elsif(group_18bx_subcount(g) = BX_VALID_RUNSUBCOUNT_OFF) then
                   valid <= '0'; 
                end if;
            end if;                
        end process algo_valid_proc;
            
    end generate gen_algo_group_valid;

end Behavioral;
