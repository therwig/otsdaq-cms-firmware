							  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.regionizer_pkg.all;
  
use work.algo_pkg.all; --because of vivado issues, copied pieces to tmux_params_pkg

entity regionizer_wrapper is
    port(
  
        link_clk            : in  std_logic;
        
        algo_in_debug       : out algo_input_t;
        
        -- Input Links 
        link_in_master      : in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
        link_in_slave       : out LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
        
        -- Output Links 
        link_out_master     : out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
        link_out_slave      : in  LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
    
        algo_reset          : in  std_logic;
        reset               : in  std_logic

    );
end;
   
architecture arch of regionizer_wrapper is
  
  
    constant BUFFER_SCENARIO     : integer := 1;    -- 0 := level-1 multiram per link sencario, 100-30 level-2 pipeline in HLS
                                                    -- 1 := level-1 FIFO per link, shift-register transfer to level-2 object RAM shared in small-region groups
    
    component regionizer_clocks 
           port (
               reset                    : in std_logic;
               link_clk                 : in std_logic;
               clk_40                   : out std_logic;
               clk_120                  : out std_logic;
               clk_240                  : out std_logic;
               clk_320                  : out std_logic;
               locked                   : out std_logic
           );
    end component regionizer_clocks;
    
    -- component delcarations for scenario 0
    component level1_multiram_buffers    
        generic (
           LINK_COUNT               : integer     
        );
        port (
           
            clk_link_to_level1      : in std_logic; 
           
            link_big_region_end     : in std_logic_vector (LINK_COUNT-1 downto 0);
           
            link_object_we_in       : in std_logic_vector (LINK_COUNT-1 downto 0);
            link_object_in          : in physics_object_arr_t (LINK_COUNT-1 downto 0);
           
            level2_re_in            : in std_logic_vector(FIBER_GROUPS-1 downto 0);
            level2_eta_phi_rindex   : in eta_phi_small_region_arr_t(FIBER_GROUPS-1 downto 0);
            
            objects_out_valid       : out std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            objects_out             : out physics_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            
            overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level1_multiram_buffers;
 
    component level2_pipelined_buffers 
        generic (
            LINK_COUNT              : integer := MAX_FIBER_COUNT
        );
        port ( 
            
            clk_level1_to_2         : in std_logic;
            
            link_big_region_end     : in std_logic_vector (LINK_COUNT-1 downto 0);
             
            level2_re               : out std_logic_vector(FIBER_GROUPS-1 downto 0);
            level2_eta_phi_rindex   : out eta_phi_small_region_arr_t(FIBER_GROUPS-1 downto 0);
                   
            level2_din_valid        : in std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            level2_din              : in physics_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            
            level2_dout_valid       : out std_logic;
            level2_dout             : out physics_object_arr_t(INPUT_DECTECTOR_COUNT*ALGO_MAX_DETECTOR_OBJECTS-1 downto 0);
                    
            reset                   : in std_logic
        );
    end component level2_pipelined_buffers;
    -- end component delcarations for scenario 0
    
    -- component delcarations for scenario 1
    component level1_fifo_only_buffers    
        generic (
            LINK_COUNT              : natural    
        );
        port (
           
            clk_link_to_level1      : in  std_logic;
            clk_level1_to_2         : in  std_logic; 
            
            link_big_region_end     : in  std_logic_vector(LINK_COUNT-1 downto 0);
            
            link_object_we_in       : in  std_logic_vector(LINK_COUNT-1 downto 0);
            link_object_in          : in  physics_object_arr_t(LINK_COUNT-1 downto 0);
            level1_big_region_end   : out std_logic_vector(FIBER_GROUPS-1 downto 0);
                            
            level2_big_region_end   : in  std_logic_vector(FIBER_GROUPS-1 downto 0);
            small_region_closed     : in  level2_to_1_sr_closed_arr_t(FIBER_GROUPS-1 downto 0);
            level2_pipe_out         : out level1_to_2_global_pipe_t;
                    
            overflow_error          : out std_logic;
            level2_reset            : in  std_logic;
            reset                   : in  std_logic
        );
    end component level1_fifo_only_buffers;
    
    component level2_ram_buffers 
        port ( 
            
            clk_level1_to_2         : in  std_logic;
                    
            level1_big_region_end   : in  std_logic_vector(FIBER_GROUPS-1 downto 0);
            
            object_pipe_in          : in  level1_to_2_global_pipe_t;
            
            small_region_closed     : out level2_to_1_sr_closed_arr_t(FIBER_GROUPS-1 downto 0);  
            next_big_region         : out std_logic_vector(FIBER_GROUPS-1 downto 0);
            
            robjects_re             : in  std_logic;
            robjects_out_valid      : out std_logic;
            robjects_out            : out raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
            
            -- overflow not possible.. overflow_error          : out std_logic;
            reset                   : in std_logic
        );
    end component level2_ram_buffers;
    -- end component delcarations for scenario 1
    
    
    component algo_wrapper
        port (
            clk                 : in std_logic;
            
            valid_in            : in std_logic;
            objects_in          : in raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0); --ALGO_INPUT_OBJECTS_COUNT constant defined in regionizer_pkg
            
            valid_out           : out std_logic;
            results_out         : out raw_algo_object_out_arr_t(ALGO_OBJECTS_OUT-1 downto 0);   --ALGO_OBJECTS_OUT constant defined in algo_pkg
            
            reset               : in std_logic
        );
    end component algo_wrapper;
  
    --=======================
    -- tmux wrapper additions
    
    
--    signal buffer_count : unsigned(4 downto 0) := (others => '0');
--    signal buffer_state : unsigned(FIBER_GROUPS downto 0) := (others => '0');
        
--    type buffer_group_t is array(FIBERS_IN_GROUP-1 downto 0) of input_buffer_t;
--    type buffer_group_array_t is array(natural range <> ) of buffer_group_t;
--    signal tmux_buffers : buffer_group_array_t(FIBER_GROUPS-1 downto 0);
    
    
--    signal tmux_algo_in : algo_tmux_buffer_t;

    -- map tmux_algo_in on algo_in since naming of inputs and outputs to HLS component already done
    signal algo_in                      : algo_input_t;
  
--    constant RESET_DELAY : natural := 23;
--    signal ap_rst_delay : std_logic_vector(RESET_DELAY-1 downto 0) := (others => '1');
    signal has_reset                    : std_logic := '0';
    
    
    constant EVENT_BUFFER_COUNT         : natural := 3;
    signal event_buffers                : event_small_region_phi_eta_buffer_arr_t(EVENT_BUFFER_COUNT-1 downto 0);
    
    signal clk_40, clk_120, clk_240, clk_320     : std_logic;
    
    signal level2_valid_out             : std_logic := '0';
    signal level2_objects_out           : raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0) := (others => (others => '0'));
begin

    algo_in_debug <= algo_in;


    clocks : regionizer_clocks 
        port map(
        
            -- Clock out ports
            clk_40      => clk_40,
            clk_120     => clk_120,
            clk_240     => clk_240,
            clk_320     => clk_320,
            locked      => open,
            
            -- Clock in ports
            reset       => reset,
            link_clk    => link_clk
        );        
    
    process(link_clk) is
    begin
        if rising_edge(link_clk) then
            if(reset = '1') then
                --ap_rst_delay <= (others => '1');
                has_reset <= '1';
            else
                --ap_rst_delay <= ap_rst_delay(RESET_DELAY-2 downto 0) & ap_rst;
                               
            end if;
        end if;
    end process;
  
 
    --for every fiber...
    --  18*3 = 54 x 120MHz clocks of data per event 
    --  data passed from above in 3*64b = 192b chunks every 40MHz
    --      data format:
    --          every bx (3 clocks), first 32b are wasted (except the first one, 31:22 is vertex [12b])
    --          then 64b chunks of data
    --      objects should be buffered by eta-phi region, skipping null pt objects
    --      object format LO-32:
    --          31:16   := otherPt
    --          15:0    := pt
    --      object format HI-32:
    --          31      := unused
    --          30      := uqality  (tracker)
    --          29:20   := z0       (tracker)
    --          19:10   := phi
    --          9:0     := eta
    
    gen_physics_object_buffer_levels : if TRUE generate
    
        signal link_objects_to_level1           : physics_object_arr_t(FIBER_GROUPS * FIBERS_IN_GROUP - 1 downto 0);
        signal link_objects_to_level1_we        : std_logic_vector(FIBER_GROUPS * FIBERS_IN_GROUP - 1 downto 0) := (others => '0');
        signal link_big_region_ends             : std_logic_vector(FIBER_GROUPS * FIBERS_IN_GROUP - 1 downto 0) := (others => '0');
        
    begin
            
         
        --generate fiber buffer approach 
        --    (each fiber should buffer the same way in a group of 6)  
        gen_fiber_group_buffer : for g in 0 to FIBER_GROUPS-1 generate        
        begin        
                        
            --generate per fiber
            gen_fiber_buffer : for i in 0 to FIBERS_IN_GROUP-1 generate
            
                constant l                                  : natural := g*FIBERS_IN_GROUP + i;
                signal   link_physics_object_buffer         : physics_object_arr_t(1 downto 0) := (others => null_physics_object);               
                
                signal   link_event_index                   : natural := 0;
               
                signal   link_vertex                        : std_logic_vector(VERTEX_BIT_WIDTH-1 downto 0) := (others => '0');
                signal   link_data                          : std_logic_vector(INPUT_WORD_SIZE-1 downto 0) := (others => '0');
                signal   link_data_valid                    : std_logic := '0';
                signal   link_data_valid_delay              : std_logic := '0';
                
                signal   link_cycle_state                   : unsigned(7 downto 0) := (others => '0');
                signal   link_big_region_state              : unsigned(7 downto 0) := (others => '0');
                                       
            begin
                
                link_data           <= link_in_master(l).tdata;
                link_data_valid     <= link_in_master(l).tvalid;
                
                link_level0_buffer_transfer_process : process(link_clk)
                begin
                
                    if(rising_edge(link_clk)) then
                            
                        --this fiber controls a physics object and a we
                        link_objects_to_level1_we(l)    <= '0'; 
                        link_objects_to_level1(l)       <= null_physics_object;  
                        
                        link_big_region_ends(l)         <= '0';
                        
                        link_data_valid_delay           <= '0';
                            
-- ===================== -- primary reset or not if statement         
                        if (reset = '1') then
                            
                            --reset per fiber
                            
                            --physics_object_buffer_state_cnt <= (others => '0');
                            link_physics_object_buffer      <= (others => null_physics_object);
                            
                            link_vertex                     <= (others => '0');
                            link_event_index                <= 0;
                            
                            link_cycle_state                <= (others => '0');
                            link_big_region_state           <= (others => '0');
                            
                        else
                            
                            
 
-- ========================= -- read side process getting 64b every link_clk                                                       
                            --      read data in 
                            if (has_reset = '1' and link_data_valid = '1') then
                            
                                link_data_valid_delay           <= '1';
                                
                                --manage big region state
                                --  18 BX then repeat
                                
                                if (link_big_region_state = 18*3-2) then
                                    link_big_region_ends(l)             <= '1';
                                end if;
                                
                                if (link_big_region_state = 18*3-1) then 
                                    link_big_region_state               <= (others => '0');
                                else
                                    link_big_region_state               <= link_big_region_state + 1;
                                end if;
                                                                                        
                                --manage link cycle state
                                --  6 states, then repeat action
                                if (link_cycle_state = 6-1) then
                                    link_cycle_state                    <= (others => '0');
                                else
                                    link_cycle_state                    <= link_cycle_state + 1;
                                end if;
                                
                                
                                if (link_cycle_state = 0) then
                                      
                                    link_vertex <= link_data(31 downto 22);
                                    link_physics_object_buffer(0)   <= (
                                        phi                 => (others => '0'),
                                        eta                 => (others => '0'),
                                        quality             => '0',
                                        lsEM                => '0',
                                        z0                  => (others => '0'),
                                        otherPt             => signed(link_data(32 + 31 downto 32 + 16)),
                                        pt                  => signed(link_data(32 + 15 downto 32 + 0)),
                                        
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    ); 
                                elsif (link_cycle_state = 1) then
                                
                                    link_physics_object_buffer(0)   <= (
                                        phi                 => signed(link_data(0 + 19 downto 0 + 10)),
                                        eta                 => signed(link_data(0 + 9 downto 0 + 0)),
                                        quality             =>        link_data(0 + 31),
                                        lsEM                =>        link_data(0 + 20),
                                        z0                  => signed(link_data(0 + 29 downto 0 + 20)),
                                        otherPt             => link_physics_object_buffer(0).otherPt,
                                        pt                  => link_physics_object_buffer(0).pt,
                                        
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    );
                                    link_physics_object_buffer(1)   <= (
                                        phi                 => (others => '0'),
                                        eta                 => (others => '0'),
                                        quality             => '0',
                                        lsEM                => '0',
                                        z0                  => (others => '0'),
                                        otherPt             => signed(link_data(32 + 31 downto 32 + 16)),
                                        pt                  => signed(link_data(32 + 15 downto 32 + 0)),
                                        
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    );
                                elsif (link_cycle_state = 2) then
                                                                
                                    link_physics_object_buffer(1)   <= (
                                        phi                 => signed(link_data(0 + 19 downto 0 + 10)),
                                        eta                 => signed(link_data(0 + 9 downto 0 + 0)),
                                        quality             =>        link_data(0 + 31),
                                        lsEM                =>        link_data(0 + 20),
                                        z0                  => signed(link_data(0 + 29 downto 0 + 20)),
                                        otherPt             => link_physics_object_buffer(1).otherPt,
                                        pt                  => link_physics_object_buffer(1).pt,
                                                                                
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    ); 
                                    link_physics_object_buffer(0)   <= (
                                        phi                 => (others => '0'),
                                        eta                 => (others => '0'),
                                        quality             => '0',
                                        lsEM                => '0',
                                        z0                  => (others => '0'),
                                        otherPt             => signed(link_data(32 + 31 downto 32 + 16)),
                                        pt                  => signed(link_data(32 + 15 downto 32 + 0)),

                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    );  
                                    
                                 elsif (link_cycle_state = 3) then
                                     
                                    --first 32b empty
                                                                    
                                    link_physics_object_buffer(0)   <= (
                                        phi                 => signed(link_data(32 + 19 downto 32 + 10)),
                                        eta                 => signed(link_data(32 + 9 downto 32 + 0)),
                                        quality             =>        link_data(32 + 31),
                                        lsEM                =>        link_data(32 + 20),
                                        z0                  => signed(link_data(32 + 29 downto 32 + 20)),
                                        otherPt             => link_physics_object_buffer(0).otherPt,
                                        pt                  => link_physics_object_buffer(0).pt,
                                        
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    );  
                                    
                                 elsif (link_cycle_state = 4) then
                                                                
                                    link_physics_object_buffer(0)   <= ( --aligned to 64b
                                        phi                 => signed(link_data(32 + 19 downto 32 + 10)),
                                        eta                 => signed(link_data(32 + 9 downto 32 + 0)),
                                        quality             =>        link_data(32 + 31),
                                        lsEM                =>        link_data(32 + 20),
                                        z0                  => signed(link_data(32 + 29 downto 32 + 20)),
                                        otherPt             => signed(link_data(0 + 31 downto 0 + 16)),
                                        pt                  => signed(link_data(0 + 15 downto 0 + 0)),
                                        
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    ); 
                                    
                                 elsif (link_cycle_state = 5) then
                                         
                                    link_cycle_state        <= (others => '0'); --reset!
                                                                 
                                    link_physics_object_buffer(0)   <= ( --aligned to 64b
                                        phi                 => signed(link_data(32 + 19 downto 32 + 10)),
                                        eta                 => signed(link_data(32 + 9 downto 32 + 0)),
                                        quality             =>        link_data(32 + 31),
                                        lsEM                =>        link_data(32 + 20),
                                        z0                  => signed(link_data(32 + 29 downto 32 + 20)),
                                        otherPt             => signed(link_data(0 + 31 downto 0 + 16)),
                                        pt                  => signed(link_data(0 + 15 downto 0 + 0)),
                                        
                                        small_region        => null_small_region,
                                        source_fiber        => l,
                                        source_event_index  => link_event_index
                                    ); 
                                 
                                end if; --end link_cycle
                            end if; --end read valid if
-- ========================= -- end read side process getting 64b every link_clk
                          
-- ========================= -- write side process to link buffer at link_clk
                            --  data comes at 40.. 2.5 per link_clk/3
                            --  so 5 objects in per link_clk/6.
                             
                            --write data out 
                            --  clear pt to 0 (null object after write)
                            if (link_data_valid_delay = '1') then
                                if(link_cycle_state = 2 and link_physics_object_buffer(0).pt /= 0) then --first valid buffer
                                
                                    link_objects_to_level1_we(l) <= '1';
                                    link_objects_to_level1(l) <= link_physics_object_buffer(0);
                                 
                                    --                                 link_objects_to_level1(l).small_region_phi <= 
                                    --                                     get_phi_small_region_index(link_physics_object_buffer(1).phi);
                                    --                                 link_objects_to_level1(l).small_region_eta <= 
                                    --                                     get_eta_small_region_index(link_physics_object_buffer(1).eta);
                                    
                                    link_physics_object_buffer(0).pt <= (others => '0');  --  clear pt to 0 (null object after write)
                                    
                                elsif(link_cycle_state = 3 and link_physics_object_buffer(1).pt /= 0) then --first valid buffer
                                                                    
                                    link_objects_to_level1_we(l) <= '1';
                                    link_objects_to_level1(l) <= link_physics_object_buffer(1);
                                    link_physics_object_buffer(1).pt <= (others => '0');  --  clear pt to 0 (null object after write) 
                                    
                                elsif(link_cycle_state = 4 and link_physics_object_buffer(0).pt /= 0) then --first valid buffer
                                                                    
                                    link_objects_to_level1_we(l) <= '1';
                                    link_objects_to_level1(l) <= link_physics_object_buffer(0);
                                    link_physics_object_buffer(0).pt <= (others => '0');  --  clear pt to 0 (null object after write) 
                                    
                                elsif(link_cycle_state = 5 and link_physics_object_buffer(0).pt /= 0) then --first valid buffer
                                                                    
                                    link_objects_to_level1_we(l) <= '1';
                                    link_objects_to_level1(l) <= link_physics_object_buffer(0);
                                    link_physics_object_buffer(0).pt <= (others => '0');  --  clear pt to 0 (null object after write) 
                                    
                                elsif(link_cycle_state = 0 and link_physics_object_buffer(0).pt /= 0) then --first valid buffer
                                                                    
                                    link_objects_to_level1_we(l) <= '1';
                                    link_objects_to_level1(l) <= link_physics_object_buffer(0);
                                    link_physics_object_buffer(0).pt <= (others => '0');  --  clear pt to 0 (null object after write) 
                                
                                end if; --end link cycle state if
                            end if;
-- ========================= -- end write side process to link buffer at link_clk
                         
                        end if;
-- ===================== -- primary reset or not if statement
                    end if; --end rising edge if
                    
                end process link_level0_buffer_transfer_process;
            end generate gen_fiber_buffer;
        end generate gen_fiber_group_buffer;
    
    
        -- ========================= 
        -- 0 := level-1 multiram per link sencario, 100-30 level-2 pipeline in HLS
        gen_levels_1_and_2_scenario_0 : if BUFFER_SCENARIO = 0 generate
        
            signal level2_re                        : std_logic_vector(FIBER_GROUPS-1 downto 0);
            signal level2_eta_phi_rindex            : eta_phi_small_region_arr_t(FIBER_GROUPS-1 downto 0);
            
            signal level2_din_valid                 : std_logic_vector(FIBER_GROUPS * FIBERS_IN_GROUP * LEVEL1_RAMS_PER_LINK-1 downto 0);
            signal level2_din                       : physics_object_arr_t(FIBER_GROUPS * FIBERS_IN_GROUP * LEVEL1_RAMS_PER_LINK-1 downto 0);
            
        begin
            level1_buffers : level1_multiram_buffers    
                generic map (
                    LINK_COUNT => FIBER_GROUPS * FIBERS_IN_GROUP 
                )
                port map (
                    
                    clk_link_to_level1       => link_clk,                       --: in std_logic; 
               
                    link_big_region_end      => link_big_region_ends,           --: in std_logic_vector (LINK_COUNT-1 downto 0);
                   
                    link_object_we_in        => link_objects_to_level1_we,      --: in std_logic_vector (LINK_COUNT-1 downto 0);
                    link_object_in           => link_objects_to_level1,         --: in physics_object_arr_t (LINK_COUNT-1 downto 0);
                   
                    level2_re_in             => level2_re,                      --: in std_logic_vector(FIBER_GROUPS-1 downto 0);
                    level2_eta_phi_rindex    => level2_eta_phi_rindex,          --: in eta_phi_small_region_arr_t;
                    
                    objects_out_valid        => level2_din_valid,               --: out std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    objects_out              => level2_din,                     --: out raw_physics_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    
                    overflow_error           => open,                           --: out std_logic;
                    reset                    => reset                           --: in std_logic                  
                );
                
            level2_buffers : level2_pipelined_buffers 
                generic map (
                    LINK_COUNT => FIBER_GROUPS * FIBERS_IN_GROUP --: integer := MAX_FIBER_COUNT
                )
                port map ( 
                    clk_level1_to_2          => link_clk,                       --: in std_logic; 
               
                    link_big_region_end      => link_big_region_ends,           --: in std_logic_vector (LINK_COUNT-1 downto 0);
                   
                    level2_re                => level2_re,                      --: out std_logic_vector(FIBER_GROUPS-1 downto 0);
                    level2_eta_phi_rindex    => level2_eta_phi_rindex,          --: out get_eta_phi_small_region_t;
                    
                    level2_din_valid         => level2_din_valid,               --: in std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    level2_din               => level2_din,                     --: in raw_physics_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    
                    level2_dout_valid        => open,                           --: out std_logic;
                    level2_dout              => open,                           --: out raw_physics_object_arr_t(INPUT_DECTECTOR_COUNT*ALGO_MAX_DETECTOR_OBJECTS-1 downto 0);
                    
                    reset                    => reset                           --: in std_logic
                );
            
        end generate gen_levels_1_and_2_scenario_0;  
        
        -- ========================= 
        -- 1 := level-1 FIFO per link, shift-register transfer to level-2 object RAM shared in small-region groups
        gen_levels_1_and_2_scenario_1 : if BUFFER_SCENARIO = 1 generate
        
            constant LEVEL1_TO_2_PIPES_COUNT        : natural := SMALL_REGION_COUNT/LEVEL2_SMALL_REGIONS_PER_RAM;
            
            signal level1_big_region_end            : std_logic_vector(FIBER_GROUPS-1 downto 0);
            signal level1_to_2_pipes_out            : level1_to_2_global_pipe_t;
            signal small_region_closed              : level2_to_1_sr_closed_arr_t(FIBER_GROUPS-1 downto 0);
            signal level2_big_region_end            : std_logic_vector(FIBER_GROUPS-1 downto 0);
        begin
        
            level1_buffers : level1_fifo_only_buffers    
                generic map (
                    LINK_COUNT              => FIBER_GROUPS * FIBERS_IN_GROUP
                )
                port map (
                    
                    clk_link_to_level1      => link_clk,                        --: in std_logic; 
                    clk_level1_to_2         => link_clk,--clk_320,                         --: in std_logic;
               
                    link_big_region_end     => link_big_region_ends,            --: in std_logic_vector (LINK_COUNT-1 downto 0);
                   
                    link_object_we_in       => link_objects_to_level1_we,       --: in std_logic_vector (LINK_COUNT-1 downto 0);
                    link_object_in          => link_objects_to_level1,          --: in physics_object_arr_t (LINK_COUNT-1 downto 0);
                    level1_big_region_end   => level1_big_region_end,           --: out std_logic_vector(FIBER_GROUPS-1 downto 0);
                    
                    level2_big_region_end   => level2_big_region_end,           --: in  std_logic_vector(FIBER_GROUPS-1 downto 0);
                    small_region_closed     => small_region_closed,             --: in  std_logic_vector(SMALL_REGION_COUNT-1 downto 0);
                    level2_pipe_out         => level1_to_2_pipes_out,           --: out level1_to_2_pipe_arr_t(LEVEL2_PIPES_OUT-1 downto 0);
                    
                    overflow_error          => open,                            --: out std_logic;
                    
                    level2_reset            => algo_reset,                      --: in std_logic;
                    reset                   => reset                            --: in std_logic                  
                );
                
            level2_buffers : level2_ram_buffers 
                port map ( 
                    clk_level1_to_2         => link_clk,--clk_320,              --: in std_logic; 
               
                    level1_big_region_end   => level1_big_region_end,           --: in std_logic_vector (FIBER_GROUPS-1 downto 0);
                        
                    object_pipe_in          => level1_to_2_pipes_out,           --: in level1_to_2_global_pipe_t;
                    
                    next_big_region         => level2_big_region_end,           --: out std_logic_vector(FIBER_GROUPS-1 downto 0);
                    
                    small_region_closed     => small_region_closed,             --: out std_logic_vector(SMALL_REGION_COUNT-1 downto 0);  
                            
                    robjects_re             => '0',                             --: in std_logic;
                    robjects_out_valid      => level2_valid_out,                --: out std_logic;
                    robjects_out            => level2_objects_out,              --: out raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
                    
                    reset                   => algo_reset                       --: in std_logic
                );
            
        end generate gen_levels_1_and_2_scenario_1;       
        
   end generate gen_physics_object_buffer_levels; 
        
   
  
    --connect to HLS algo block 
    algo_wrapper_instance : algo_wrapper
        port map (
            clk             => link_clk,            --: in std_logic;

            valid_in        => level2_valid_out,    --: in std_logic;
            objects_in      => level2_objects_out,  --: in raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
            
            valid_out       => open,                --: out std_logic;
            results_out     => open,                --: out raw_algo_object_out_t(ALGO_OBJECTS_OUT-1 downto 0);
            
            reset           => reset                --: in std_logic
        );
    
    
  
end arch;
 
