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
use ieee.std_logic_misc.all;

use work.regionizer_params_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



----------------------------------------------------------------------------------


entity level2_ram_buffers is
    generic (
        SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM
    );
    port ( 
        clk_level1_to_2         : in  std_logic;
            
        level1_big_region_end   : in  std_logic_vector(FIBER_GROUPS-1 downto 0);
        
        object_pipe_in          : in  level1_to_2_global_pipe_t;
        
        small_region_closed     : out level2_to_1_sr_closed_arr_t(FIBER_GROUPS-1 downto 0);  
        next_big_region         : out std_logic_vector(FIBER_GROUPS-1 downto 0);
        
        robjects_re             : in  std_logic;
        robjects_out_valid      : out std_logic;
        robjects_out            : out physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
        
        -- overflow not possible.. overflow_error          : out std_logic;
        reset                   : in  std_logic
    );
end level2_ram_buffers;

architecture Behavioral of level2_ram_buffers is

    component level2_ram_buffer
        generic (
            SMALL_REGIONS_PER_RAM   : integer := LEVEL2_SMALL_REGIONS_PER_RAM;
            PARALLEL_OBJECT_RAMS    : integer := LEVEL2_PARALLEL_OBJECT_RAMS;
            SHARED_BUFFER_INDEX     : integer;
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
    end component level2_ram_buffer;
    
    
    -- MAX_CLOCKS_TO_READ is the clocks needed to read out objects from parallel rams 
    --  for the detector with the most objects.
    constant MAX_CLOCKS_TO_READ         : integer := 
        (ALGO_MAX_DETECTOR_OBJECTS + LEVEL2_PARALLEL_OBJECT_RAMS - 1) /
        LEVEL2_PARALLEL_OBJECT_RAMS; -- ceil(ALGO_MAX_DETECTOR_OBJECTS/SHARED_SMALL_REGION_RAMS)
    
    type level2_out_pipe_t is record
        valid   : std_logic;
        objects : physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
    end record level2_out_pipe_t;
    type level2_out_pipe_arr_t is array(natural range <> ) of level2_out_pipe_t;
    
    signal level2_out_pipes         : level2_out_pipe_arr_t(2 downto 0);
    
    signal level2_tracker_out_valid : std_logic := '0';
    signal level2_emcalo_out_valid  : std_logic := '0';
    signal level2_calo_out_valid    : std_logic := '0';
     
begin

    --  This is the Level-2 multiram buffer container to instantiate group, detector 
    --      shared small-region buffers.
    --
    --      e.g. SMALL_REGIONS_PER_RAM = 3 and PARALLEL_OBJECT_RAMS = 5
    --          then this container would consist of 18/3 = 6 shared small-region buffers that each
    --              handle 3 small-regions, and stack objects for those small-regions in
    --              5 parallel RAMs.
    --
    --      Inputs come from a Level-1 FIFO stage.. one FIFO for each link for the detector
    --      Outputs go to the HLS algo, e.g. 25 objects for Tracker per small-region
    --
    -- =====
    -- Read behavior:
    --  Once a big-region is fully written to Level-2,
    --      small-regions are prepared to be handed to the algo every two clocks
    --      
    --      e.g. if it takes 5 clocks to read the full input object size from the parallel sub-buffers
    --          then 3 small-regions will have to co-exist in shift-register pipeline on the way out 
    --          of Level-2 to the algo.
    

    robjects_out_valid          <= robjects_re; -- unnecessary and_reduce(all valids)

    -- ==========================================================================================
    -- generate Tracker Level-2 buffers
    level2_tracker_buffer_gen : if TRUE generate
        constant DETECTOR_OBJECTS_TO_ALGO   : integer := 25;   
        constant SHARED_SMALL_REGION_RAMS   : integer := SMALL_REGION_COUNT/SMALL_REGIONS_PER_RAM;    
        constant CLOCKS_TO_STAGGER          : integer := 2;
        
        constant CLOCKS_TO_READ         : integer := (DETECTOR_OBJECTS_TO_ALGO + LEVEL2_PARALLEL_OBJECT_RAMS - 1) / LEVEL2_PARALLEL_OBJECT_RAMS; -- ceil(DETECTOR_OBJECTS_TO_ALGO/LEVEL2_PARALLEL_OBJECT_RAMS)
           
        
        type level2_out_tracker_set_t is record
            valid   : std_logic_vector(LEVEL2_PARALLEL_OBJECT_RAMS-1 downto 0);
            objects : physics_object_arr_t(LEVEL2_PARALLEL_OBJECT_RAMS-1 downto 0);
        end record level2_out_tracker_set_t;
        type level2_out_tracker_set_arr_t is array(natural range <> ) of level2_out_tracker_set_t;
        
        
    begin
    
        -- ==========================================================================================
        level2_tracker_buffer_group_gen : for g in 0 to FIBER_GROUPS-1 generate
            
            type robjects_re_arr_t is array(integer range <>) of std_logic_vector(SMALL_REGIONS_PER_RAM-1 downto 0);            
            signal robjects_re              : robjects_re_arr_t(SHARED_SMALL_REGION_RAMS-1 downto 0) := (others => (others => '0'));
            signal local_re_arr             : std_logic_vector(SMALL_REGIONS_PER_RAM-1 downto 0) := (others => '0');
            
            signal level2_out_set_arr       : level2_out_tracker_set_arr_t(SHARED_SMALL_REGION_RAMS-1 downto 0); 
                                    
            signal tracker_group_out_valid  : std_logic_vector(SMALL_REGIONS_PER_RAM-1 downto 0) := (others => '0');
                
            type debug_count_arr_t is array(integer range <>) of integer;
            signal debug_pipe_valid_count   : debug_count_arr_t(SHARED_SMALL_REGION_RAMS-1 downto 0) := (others => 0);
            
        begin                    
        
            
            next_big_region(g)          <= level1_big_region_end(g); -- Note: should be on clk_level1_to_2
        
            -- ==========================================================================================
            level2_tracker_buffer_multiram_gen : for i in 0 to SHARED_SMALL_REGION_RAMS-1 generate
            begin
            
                --=============
                debug_count_process : process(clk_level1_to_2)
                begin
                    if(rising_edge(clk_level1_to_2)) then
                    
                        if (reset = '1' or level1_big_region_end(g) = '1') then
                            debug_pipe_valid_count(i) <= 0;
                        elsif (object_pipe_in(g).tracker_pipe(i).valid = '1') then
                            debug_pipe_valid_count(i) <= debug_pipe_valid_count(i) + 1;
                        end if; 
                    
                    end if;            
                end process debug_count_process;
                
                --=============
                layer2_tracker_buffer: level2_ram_buffer
                    generic map (
                        SHARED_BUFFER_INDEX             => i,
                        OBJECTS_TO_ALGO                 => DETECTOR_OBJECTS_TO_ALGO  
                    )
                    port map (
                        clk_level1_to_2                 => clk_level1_to_2,             --: in  std_logic;
                                
                        level1_big_region_end           => level1_big_region_end(g),    --: in  std_logic;
                        
                        object_pipe_in                  => object_pipe_in(g).tracker_pipe(i),           --: in  level1_to_2_pipe_t;
                        
                        next_big_region                 => open,                        --: out std_logic;
                        small_region_closed             => small_region_closed(g).tracker_closed((i+1)*2-1 downto i*2),   --: out std_logic_vector(SMALL_REGION_COUNT-1 downto 0);  
                        
                        robjects_re                     => or_reduce(robjects_re(i)),   --: in  std_logic;
                        robjects_out_valid              => level2_out_set_arr(i).valid,    --: out std_logic_vector(PARALLEL_OBJECT_RAMS-1 downto 0);
                        robjects_out                    => level2_out_set_arr(i).objects,  --: out physics_object_arr_t(PARALLEL_OBJECT_RAMS-1 downto 0);  
                
                        reset                           => reset
                    );    
                --end tracker buffer component
                                                     
            end generate level2_tracker_buffer_multiram_gen;
            
            
            -- ==========================================================================================
            level2_tracker_read_stagger_gen : for i in 0 to SMALL_REGIONS_PER_RAM-1 generate
                                
                constant STAGGER_START_INDEX    : unsigned(3 downto 0) := to_unsigned(i*
                    ((((SMALL_REGIONS_PER_RAM - 1)*CLOCKS_TO_STAGGER) + MAX_CLOCKS_TO_READ - 1)/ 
                    MAX_CLOCKS_TO_READ + 1),4); -- e.g. ceil( (2-1)*2 / 5 ) + 1 = 2
                constant CLOCKS_TO_IDLE         : unsigned(3 downto 0) := to_unsigned(i*CLOCKS_TO_STAGGER,4); --causes the staggering pattern
           
                signal level1_big_region_here   : std_logic; 
                
                signal idle                     : std_logic := '0';
                signal idle_count               : unsigned(3 downto 0) := (others => '0');
                
                signal small_region_index       : unsigned(3 downto 0) := (others => '0');
                signal small_region_steps       : unsigned(3 downto 0) := (others => '0');
                signal small_region_rcount      : unsigned(3 downto 0) := (others => '0');
                
                signal local_robjects_re        : std_logic_vector(SHARED_SMALL_REGION_RAMS-1 downto 0) := (others => '0');
                                 
                
            begin
            
                
                connect_local_re : for r in 0 to SHARED_SMALL_REGION_RAMS-1 generate 
                    robjects_re(r)(i)       <= local_robjects_re(r);
                end generate connect_local_re;
            
                -- ============
                --  Once big-region data is fully in Level-2,
                --      read each small-region out to algo, one at a time.
                --  Note: DETECTOR_OBJECTS_TO_ALGO/LEVEL2_PARALLEL_OBJECT_RAMS number of
                --      clocks needed to read one small-region out to algo. Plus
                --      add delay of ceil(ALGO_MAX_DETECTOR_OBJECTS/SHARED_SMALL_REGION_RAMS) 
                --      to account for other detectors finishing                 
                level2_tracker_read_process : process(clk_level1_to_2)
                begin
                    
                    if ( rising_edge(clk_level1_to_2) ) then
                        
                        level1_big_region_here      <= level1_big_region_end(g);
                        
                        local_robjects_re           <= (others => '0');
                        local_re_arr(i)             <= '0';
                                
                        tracker_group_out_valid(i)  <= '0'; 
                                    
                        
                        if (reset = '1') then
                        
                            idle                    <= '1';
                            
                            idle_count              <= (others => '0');
                            small_region_index      <= STAGGER_START_INDEX; 
                            small_region_rcount     <= (others => '0');  
                            small_region_steps      <= (others => '0');
                            
                               
                        else
                        
                            --check for read sequence start
                            if (idle = '1') then
                            
                                if(level1_big_region_here = '1') then
                                
                                    if(CLOCKS_TO_IDLE = 0) then
                                        --kick off read sequence of events
                                        idle                                                <= '0';   
                                        local_robjects_re(to_integer(small_region_index))   <= '1'; 
                                        local_re_arr(i)                                     <= '1';
                                        small_region_rcount                                 <= small_region_rcount + 1; 
                                    else --start idle wait
                                        idle_count      <= idle_count + 1;
                                    end if; 
                                end if;
                                
                                if (idle_count > 0) then
                                    idle_count          <= idle_count + 1;
                                    if (idle_count = CLOCKS_TO_IDLE-1) then
                                        --kick off read sequence of events
                                        idle_count                                          <= (others => '0'); --reset for next read sequence
                                        idle                                                <= '0';   
                                        local_robjects_re(to_integer(small_region_index))   <= '1'; 
                                        local_re_arr(i)                                     <= '1';
                                        small_region_rcount                                 <= small_region_rcount + 1;
                                    end if;
                                end if;
                                                     
                            end if; --end idle handling
                            
                            
                            
                            --handle read sequence
                            if(idle = '0') then
                            
                                if(small_region_rcount < CLOCKS_TO_READ) then  
                                    local_robjects_re(to_integer(small_region_index))   <= '1';
                                    local_re_arr(i)                                     <= '1'; 
                                end if;
                                
                                if(small_region_rcount = MAX_CLOCKS_TO_READ - 1) then
                                    --reset, for next small-region read  
                                    small_region_rcount <= (others => '0');
                                    
                                    --check if done with small-region run
                                    if (small_region_steps = SMALL_REGION_COUNT-1) then  
                                        idle                    <= '1'; --done!
                                        small_region_steps      <= (others => '0');
                                    else
                                        small_region_steps      <= small_region_steps + 1;
                                    end if;                                                                        
                                    
                                    --manage small-region index incremenat and wrap around 
                                    if (small_region_index = SHARED_SMALL_REGION_RAMS-1) then
                                        small_region_index      <= (others => '0'); --wraparound 
                                    else
                                        small_region_index      <= small_region_index + 1; --increment index of multi-small-region
                                    end if;
                                    
                                else
                                    small_region_rcount <= small_region_rcount + 1; --increment count within small-region
                                end if;
                                
                            end if; --end read sequence handling
                            
                            
                        end if; --end primary reset if
                         
                    end if; --end rising edge if                   
                    
                end process level2_tracker_read_process;
                
            end generate level2_tracker_read_stagger_gen;
                        
            -- ==========================================================================================
            level2_tracker_read_to_algo_handle_gen : for i in 0 to SMALL_REGIONS_PER_RAM-1 generate
                            
                signal level2_out_set_ready     : std_logic := '0';
                signal level2_read_count        : unsigned(3 downto 0) := (others => '0');
                                           
                signal robject_set              : level2_out_tracker_set_t;   
                signal local_robject_pipe       : level2_out_tracker_set_arr_t(CLOCKS_TO_READ-1 downto 0);  
                                
                constant URAM_READ_LATENCY      : integer := 2;
                signal uram_read_valid_pipe     : std_logic_vector(URAM_READ_LATENCY-1 downto 0) := (others => '0');
                
                
                signal small_region_rindex      : unsigned(3 downto 0) := (others => '0');   
                             
                -- for debugging 
                signal debug_small_region_out   : eta_phi_small_region_t;
                
            begin
                    
                -- Behavior:
                --  This read process is from the Level-2 shared parallel rams to the algo.
                --  It is meant to be independent of the read-enable handling into the shared rams;
                --      it is linked only by the local re signal and the URAM_READ_LATENCY constant.
                            
                level2_out_set_ready        <= uram_read_valid_pipe(URAM_READ_LATENCY-1);
                robject_set.valid           <= level2_out_set_arr(to_integer(small_region_rindex)).valid;
                robject_set.objects         <= level2_out_set_arr(to_integer(small_region_rindex)).objects;
            
                -- ============             
                level2_tracker_read_to_algo_handle_process : process(clk_level1_to_2)
                begin
                
                    if ( rising_edge(clk_level1_to_2) ) then
                    
                        uram_read_valid_pipe        <= uram_read_valid_pipe(URAM_READ_LATENCY-2 downto 0) &
                                local_re_arr(i);          
                                               
                        if (reset = '1') then
                        
                            level2_read_count           <= (others => '0');
                            small_region_rindex         <= (others => '0');
                            
                        else
                        
                            --handle data out of Level-2
                            if (level2_out_set_ready = '1') then 
                            
                                local_robject_pipe <= local_robject_pipe(CLOCKS_TO_READ-2 downto 0) & robject_set;
                               
                               
                                if (level2_read_count = CLOCKS_TO_READ-1) then     
                                    
                                    --reset for next small-region 
                                    level2_read_count           <= (others => '0'); 
                                    
                                    --increment shared small-region index for next small-region
                                    if (small_region_rindex = SHARED_SMALL_REGION_RAMS-1) then
                                        small_region_rindex         <= (others => '0'); --wrap around
                                    else
                                        small_region_rindex         <= small_region_rindex + 1; 
                                    end if;
                                    
                                    --pass detector outputs to final outputs!
                                    tracker_group_out_valid(i)  <= local_robject_pipe(CLOCKS_TO_READ-2).valid(0);
                                    debug_small_region_out      <= local_robject_pipe(CLOCKS_TO_READ-2).objects(0).small_region;
                                    
                                else                                
                                    level2_read_count           <= level2_read_count + 1; 
                                end if; 
                            end if;
                            
                        end if; --end primary reset if
                         
                    end if; --end rising edge if  
                end process level2_tracker_read_to_algo_handle_process;
                            
            end generate level2_tracker_read_to_algo_handle_gen;
            
            
        end generate level2_tracker_buffer_group_gen;
    end generate level2_tracker_buffer_gen;
        

end Behavioral;
