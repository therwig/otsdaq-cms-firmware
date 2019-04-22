							  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tmux_params_pkg.all;
  
use work.algo_pkg.all; --because of vivado issues, copied pieces to tmux_params_pkg

entity tmux_wrapper is
--  generic (  	
--
--          );
  port(
  
      ap_clk   : in  std_logic;
      ap_rst   : in  std_logic;
      ap_start : in  std_logic;
      ap_done  : out std_logic;
      ap_idle  : out std_logic;
      ap_ready : out std_logic;
      
      algo_in_debug      : out algo_input_t;
  
      -- Input Links 
      link_in_master : in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
      link_in_slave  : out LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
  
      -- Output Links 
      link_out_master : out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
      link_out_slave  : in  LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0)
      


      );
end;
   
architecture arch of tmux_wrapper is
  
    component tmux_clocks 
           port (
               reset                    : in std_logic;
               clk_in1                  : in std_logic;
               clk_40                   : out std_logic;
               clk_240                  : out std_logic;
               clk_360                  : out std_logic;
               locked                   : out std_logic
           );
    end component tmux_clocks;
    
    component level1_multiram_buffers    
           generic (
               LINK_COUNT               : integer     
           );
           port (
               
                clk_link_to_level1       : in std_logic; 
               
                link_big_region_end      : in std_logic_vector (LINK_COUNT-1 downto 0);
               
                link_object_we_in        : in std_logic_vector (LINK_COUNT-1 downto 0);
                link_object_in           : in physics_object_arr_t (LINK_COUNT-1 downto 0);
               
                level2_re_in             : in std_logic_vector(FIBER_GROUPS-1 downto 0);
                level2_eta_phi_rindex    : in get_eta_phi_small_region_t;
                
                objects_out_valid        : out std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                objects_out              : out raw_phyiscs_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                
                overflow_error           : out std_logic;
                reset                    : in std_logic
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
            level2_eta_phi_rindex   : out get_eta_phi_small_region_t;
                   
            level2_din_valid        : in std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            level2_din              : in raw_phyiscs_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
            
            level2_dout_valid       : out std_logic;
            level2_dout             : out raw_phyiscs_object_arr_t(INPUT_DECTECTOR_COUNT*ALGO_MAX_DETECTOR_OBJECTS-1 downto 0);
                    
            reset                   : in std_logic
        );
    end component level2_pipelined_buffers;
    
--    component algo_unpacked
--    port (
--      ap_clk   : in  std_logic;
--      ap_rst   : in  std_logic;
--      ap_start : in  std_logic;
--      ap_done  : out std_logic;
--      ap_idle  : out std_logic;
--      ap_ready : out std_logic;
    
--      link_in_0_V  : in std_logic_vector (191 downto 0);
--      link_in_1_V  : in std_logic_vector (191 downto 0);
--      link_in_2_V  : in std_logic_vector (191 downto 0);
--      link_in_3_V  : in std_logic_vector (191 downto 0);
--      link_in_4_V  : in std_logic_vector (191 downto 0);
--      link_in_5_V  : in std_logic_vector (191 downto 0);
--      link_in_6_V  : in std_logic_vector (191 downto 0);
--      link_in_7_V  : in std_logic_vector (191 downto 0);
--      link_in_8_V  : in std_logic_vector (191 downto 0);
--      link_in_9_V  : in std_logic_vector (191 downto 0);
--      link_in_10_V : in std_logic_vector (191 downto 0);
--      link_in_11_V : in std_logic_vector (191 downto 0);
--      link_in_12_V : in std_logic_vector (191 downto 0);
--      link_in_13_V : in std_logic_vector (191 downto 0);
--      link_in_14_V : in std_logic_vector (191 downto 0);
--      link_in_15_V : in std_logic_vector (191 downto 0);
--      link_in_16_V : in std_logic_vector (191 downto 0);
--      link_in_17_V : in std_logic_vector (191 downto 0);
--      link_in_18_V : in std_logic_vector (191 downto 0);
--      link_in_19_V : in std_logic_vector (191 downto 0);
--      link_in_20_V : in std_logic_vector (191 downto 0);
--      link_in_21_V : in std_logic_vector (191 downto 0);
--      link_in_22_V : in std_logic_vector (191 downto 0);
--      link_in_23_V : in std_logic_vector (191 downto 0);
--      link_in_24_V : in std_logic_vector (191 downto 0);
--      link_in_25_V : in std_logic_vector (191 downto 0);
--      link_in_26_V : in std_logic_vector (191 downto 0);
--      link_in_27_V : in std_logic_vector (191 downto 0);
--      link_in_28_V : in std_logic_vector (191 downto 0);
--      link_in_29_V : in std_logic_vector (191 downto 0);
--      link_in_30_V : in std_logic_vector (191 downto 0);
--      link_in_31_V : in std_logic_vector (191 downto 0);
--      link_in_32_V : in std_logic_vector (191 downto 0);
--      link_in_33_V : in std_logic_vector (191 downto 0);
--      link_in_34_V : in std_logic_vector (191 downto 0);
--      link_in_35_V : in std_logic_vector (191 downto 0);
--      link_in_36_V : in std_logic_vector (191 downto 0);
--      link_in_37_V : in std_logic_vector (191 downto 0);
--      link_in_38_V : in std_logic_vector (191 downto 0);
--      link_in_39_V : in std_logic_vector (191 downto 0);
--      link_in_40_V : in std_logic_vector (191 downto 0);
--      link_in_41_V : in std_logic_vector (191 downto 0);
--      link_in_42_V : in std_logic_vector (191 downto 0);
--      link_in_43_V : in std_logic_vector (191 downto 0);
--      link_in_44_V : in std_logic_vector (191 downto 0);
--      link_in_45_V : in std_logic_vector (191 downto 0);
--      link_in_46_V : in std_logic_vector (191 downto 0);
--      link_in_47_V : in std_logic_vector (191 downto 0);
    
--      link_out_0_V  : out std_logic_vector (191 downto 0);
--      link_out_1_V  : out std_logic_vector (191 downto 0);
--      link_out_2_V  : out std_logic_vector (191 downto 0);
--      link_out_3_V  : out std_logic_vector (191 downto 0);
--      link_out_4_V  : out std_logic_vector (191 downto 0);
--      link_out_5_V  : out std_logic_vector (191 downto 0);
--      link_out_6_V  : out std_logic_vector (191 downto 0);
--      link_out_7_V  : out std_logic_vector (191 downto 0);
--      link_out_8_V  : out std_logic_vector (191 downto 0);
--      link_out_9_V  : out std_logic_vector (191 downto 0);
--      link_out_10_V : out std_logic_vector (191 downto 0);
--      link_out_11_V : out std_logic_vector (191 downto 0);
--      link_out_12_V : out std_logic_vector (191 downto 0);
--      link_out_13_V : out std_logic_vector (191 downto 0);
--      link_out_14_V : out std_logic_vector (191 downto 0);
--      link_out_15_V : out std_logic_vector (191 downto 0);
--      link_out_16_V : out std_logic_vector (191 downto 0);
--      link_out_17_V : out std_logic_vector (191 downto 0);
--      link_out_18_V : out std_logic_vector (191 downto 0);
--      link_out_19_V : out std_logic_vector (191 downto 0);
--      link_out_20_V : out std_logic_vector (191 downto 0);
--      link_out_21_V : out std_logic_vector (191 downto 0);
--      link_out_22_V : out std_logic_vector (191 downto 0);
--      link_out_23_V : out std_logic_vector (191 downto 0);
--      link_out_24_V : out std_logic_vector (191 downto 0);
--      link_out_25_V : out std_logic_vector (191 downto 0);
--      link_out_26_V : out std_logic_vector (191 downto 0);
--      link_out_27_V : out std_logic_vector (191 downto 0);
--      link_out_28_V : out std_logic_vector (191 downto 0);
--      link_out_29_V : out std_logic_vector (191 downto 0);
--      link_out_30_V : out std_logic_vector (191 downto 0);
--      link_out_31_V : out std_logic_vector (191 downto 0);
--      link_out_32_V : out std_logic_vector (191 downto 0);
--      link_out_33_V : out std_logic_vector (191 downto 0);
--      link_out_34_V : out std_logic_vector (191 downto 0);
--      link_out_35_V : out std_logic_vector (191 downto 0);
--      link_out_36_V : out std_logic_vector (191 downto 0);
--      link_out_37_V : out std_logic_vector (191 downto 0);
--      link_out_38_V : out std_logic_vector (191 downto 0);
--      link_out_39_V : out std_logic_vector (191 downto 0);
--      link_out_40_V : out std_logic_vector (191 downto 0);
--      link_out_41_V : out std_logic_vector (191 downto 0);
--      link_out_42_V : out std_logic_vector (191 downto 0);
--      link_out_43_V : out std_logic_vector (191 downto 0);
--      link_out_44_V : out std_logic_vector (191 downto 0);
--      link_out_45_V : out std_logic_vector (191 downto 0);
--      link_out_46_V : out std_logic_vector (191 downto 0);
--      link_out_47_V : out std_logic_vector (191 downto 0);
    
--      link_out_0_V_ap_vld  : out std_logic;
--      link_out_1_V_ap_vld  : out std_logic;
--      link_out_2_V_ap_vld  : out std_logic;
--      link_out_3_V_ap_vld  : out std_logic;
--      link_out_4_V_ap_vld  : out std_logic;
--      link_out_5_V_ap_vld  : out std_logic;
--      link_out_6_V_ap_vld  : out std_logic;
--      link_out_7_V_ap_vld  : out std_logic;
--      link_out_8_V_ap_vld  : out std_logic;
--      link_out_9_V_ap_vld  : out std_logic;
--      link_out_10_V_ap_vld : out std_logic;
--      link_out_11_V_ap_vld : out std_logic;
--      link_out_12_V_ap_vld : out std_logic;
--      link_out_13_V_ap_vld : out std_logic;
--      link_out_14_V_ap_vld : out std_logic;
--      link_out_15_V_ap_vld : out std_logic;
--      link_out_16_V_ap_vld : out std_logic;
--      link_out_17_V_ap_vld : out std_logic;
--      link_out_18_V_ap_vld : out std_logic;
--      link_out_19_V_ap_vld : out std_logic;
--      link_out_20_V_ap_vld : out std_logic;
--      link_out_21_V_ap_vld : out std_logic;
--      link_out_22_V_ap_vld : out std_logic;
--      link_out_23_V_ap_vld : out std_logic;
--      link_out_24_V_ap_vld : out std_logic;
--      link_out_25_V_ap_vld : out std_logic;
--      link_out_26_V_ap_vld : out std_logic;
--      link_out_27_V_ap_vld : out std_logic;
--      link_out_28_V_ap_vld : out std_logic;
--      link_out_29_V_ap_vld : out std_logic;
--      link_out_30_V_ap_vld : out std_logic;
--      link_out_31_V_ap_vld : out std_logic;
--      link_out_32_V_ap_vld : out std_logic;
--      link_out_33_V_ap_vld : out std_logic;
--      link_out_34_V_ap_vld : out std_logic;
--      link_out_35_V_ap_vld : out std_logic;
--      link_out_36_V_ap_vld : out std_logic;
--      link_out_37_V_ap_vld : out std_logic;
--      link_out_38_V_ap_vld : out std_logic;
--      link_out_39_V_ap_vld : out std_logic;
--      link_out_40_V_ap_vld : out std_logic;
--      link_out_41_V_ap_vld : out std_logic;
--      link_out_42_V_ap_vld : out std_logic;
--      link_out_43_V_ap_vld : out std_logic;
--      link_out_44_V_ap_vld : out std_logic;
--      link_out_45_V_ap_vld : out std_logic;
--      link_out_46_V_ap_vld : out std_logic;
--      link_out_47_V_ap_vld : out std_logic
    
--      );
--    end component algo_unpacked;

  
--    signal ap_clk_unp   : std_logic;
--    signal ap_rst_unp   : std_logic;
--    signal ap_start_unp : std_logic;
--    signal ap_done_unp  : std_logic;
--    signal ap_idle_unp  : std_logic;
--    signal ap_ready_unp : std_logic;
      
--    type t_cyc_3_arr is array(integer range <>) of integer range 0 to 2;
--    signal in_cyc  : t_cyc_3_arr(MAX_FIBER_COUNT-1 downto 0);
--    signal out_cyc : t_cyc_3_arr(MAX_FIBER_COUNT-1 downto 0);
    
--    signal link_in      : link_input_data_arr_t(MAX_FIBER_COUNT-1 downto 0);
--    signal link_in_reg  : link_input_data_arr_t(MAX_FIBER_COUNT-1 downto 0);
--    signal link_out     : link_input_data_arr_t(MAX_FIBER_COUNT-1 downto 0);
--    signal link_out_reg : link_input_data_arr_t(MAX_FIBER_COUNT-1 downto 0);  
    
--    signal link_out_ap_vld : std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
--    signal link_out_ap_vld_latched : std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
    
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
    
    signal clk_40, clk_240, clk_360     : std_logic;
begin

    algo_in_debug <= algo_in;


    clk_tmux : tmux_clocks 
        port map(
        
            -- Clock out ports
            clk_40      => clk_40,
            --clk_120 => open,
            clk_240     => clk_240,
            clk_360     => clk_360,
            locked      => open,
            
            -- Clock in ports
            reset       => ap_rst,
            clk_in1     => ap_clk
        );        
    
    process(ap_clk) is
    begin
        if rising_edge(ap_clk) then
            if(ap_rst = '1') then
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
                signal   link_data                          : std_logic_vector(TMUX_INPUT_WORD_SIZE-1 downto 0) := (others => '0');
                signal   link_data_valid                    : std_logic := '0';
                signal   link_data_valid_delay              : std_logic := '0';
                
                signal   link_cycle_state                   : unsigned(7 downto 0) := (others => '0');
                signal   link_big_region_state              : unsigned(7 downto 0) := (others => '0');
                                       
            begin
                
                link_data           <= link_in_master(l).tdata;
                link_data_valid     <= link_in_master(l).tvalid;
                
                link_level0_buffer_transfer_process : process(ap_clk)
                begin
                
                    if(rising_edge(ap_clk)) then
                            
                        --this fiber controls a physics object and a we
                        link_objects_to_level1_we(l)    <= '0'; 
                        link_objects_to_level1(l)       <= null_physics_object;  
                        
                        link_big_region_ends(l)         <= '0';
                        
                        link_data_valid_delay           <= '0';
                            
-- ===================== -- primary reset or not if statement         
                        if (ap_rst = '1') then
                            
                            --reset per fiber
                            
                            --physics_object_buffer_state_cnt <= (others => '0');
                            link_physics_object_buffer      <= (others => null_physics_object);
                            
                            link_vertex                     <= (others => '0');
                            link_event_index                <= 0;
                            
                            link_cycle_state                <= (others => '0');
                            link_big_region_state           <= (others => '0');
                            
                        else
                            
                            
 
-- ========================= -- read side process getting 64b every 120MHz                                                       
                            --      read data in 
                            if (has_reset = '1' and link_data_valid = '1') then
                            
                                link_data_valid_delay           <= '1';
                                
                                --manage big region state
                                --  18 BX then repeat
                                if (link_big_region_state = 18*3-1) then 
                                    link_big_region_state               <= (others => '0');
                                    link_big_region_ends(l)             <= '1';
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
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
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
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
                                    );
                                    link_physics_object_buffer(1)   <= (
                                        phi                 => (others => '0'),
                                        eta                 => (others => '0'),
                                        quality             => '0',
                                        lsEM                => '0',
                                        z0                  => (others => '0'),
                                        otherPt             => signed(link_data(32 + 31 downto 32 + 16)),
                                        pt                  => signed(link_data(32 + 15 downto 32 + 0)),
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
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
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
                                    ); 
                                    link_physics_object_buffer(0)   <= (
                                        phi                 => (others => '0'),
                                        eta                 => (others => '0'),
                                        quality             => '0',
                                        lsEM                => '0',
                                        z0                  => (others => '0'),
                                        otherPt             => signed(link_data(32 + 31 downto 32 + 16)),
                                        pt                  => signed(link_data(32 + 15 downto 32 + 0)),
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
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
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
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
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
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
                                        
                                        source_fiber        => l,
                                        source_event_index  => link_event_index,
                                        small_region_phi    => ALGO_INPUT_SMALL_REGION_PHI_SIZE,
                                        small_region_eta    => ALGO_INPUT_SMALL_REGION_ETA_SIZE
                                    ); 
                                 
                                end if; --end link_cycle
                            end if; --end read valid if
-- ========================= -- end read side process getting 64b every 120MHz
                          
-- ========================= -- write side process to link buffer at 120MHz
                            --  data comes at 40.. 2.5 per 40MHz
                            --  so 5 objects in per 20MHz.
                             
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
-- ========================= -- end write side process to link buffer at 120MHz
                         
                        end if;
-- ===================== -- primary reset or not if statement
                    end if; --end rising edge if
                    
                end process link_level0_buffer_transfer_process;
            end generate gen_fiber_buffer;
        end generate gen_fiber_group_buffer;
    
    
        -- ========================= 
        gen_object_buffer_levels_1_and_2 : if TRUE generate
        
            signal level2_re                        : std_logic_vector(FIBER_GROUPS-1 downto 0);
            signal level2_eta_phi_rindex            : get_eta_phi_small_region_t;
            
            signal level2_din_valid                 : std_logic_vector(FIBER_GROUPS * FIBERS_IN_GROUP * LEVEL1_RAMS_PER_LINK-1 downto 0);
            signal level2_din                       : raw_phyiscs_object_arr_t(FIBER_GROUPS * FIBERS_IN_GROUP * LEVEL1_RAMS_PER_LINK-1 downto 0);
            
        begin
            level1_buffers : level1_multiram_buffers    
                generic map (
                    LINK_COUNT => FIBER_GROUPS * FIBERS_IN_GROUP 
                )
                port map (
                    
                    clk_link_to_level1       => ap_clk,                         --: in std_logic; 
               
                    link_big_region_end      => link_big_region_ends,           --: in std_logic_vector (LINK_COUNT-1 downto 0);
                   
                    link_object_we_in        => link_objects_to_level1_we,      --: in std_logic_vector (LINK_COUNT-1 downto 0);
                    link_object_in           => link_objects_to_level1,         --: in physics_object_arr_t (LINK_COUNT-1 downto 0);
                   
                    level2_re_in             => level2_re,                      --: in std_logic_vector(FIBER_GROUPS-1 downto 0);
                    level2_eta_phi_rindex    => level2_eta_phi_rindex,          --: in get_eta_phi_small_region_t;
                    
                    objects_out_valid        => level2_din_valid,               --: out std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    objects_out              => level2_din,                     --: out raw_phyiscs_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    
                    overflow_error           => open,                           --: out std_logic;
                    reset                    => ap_rst                          --: in std_logic                  
                );
                
            level2_buffers : level2_pipelined_buffers 
                generic map (
                    LINK_COUNT => FIBER_GROUPS * FIBERS_IN_GROUP --: integer := MAX_FIBER_COUNT
                )
                port map ( 
                    clk_level1_to_2          => ap_clk,                         --: in std_logic; 
               
                    link_big_region_end      => link_big_region_ends,           --: in std_logic_vector (LINK_COUNT-1 downto 0);
                   
                    level2_re                => level2_re,                      --: out std_logic_vector(FIBER_GROUPS-1 downto 0);
                    level2_eta_phi_rindex    => level2_eta_phi_rindex,          --: out get_eta_phi_small_region_t;
                    
                    level2_din_valid         => level2_din_valid,               --: in std_logic_vector(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    level2_din               => level2_din,                     --: in raw_phyiscs_object_arr_t(LINK_COUNT*LEVEL1_RAMS_PER_LINK-1 downto 0);
                    
                    level2_dout_valid        => open,                           --: out std_logic;
                    level2_dout              => open,                           --: out raw_phyiscs_object_arr_t(INPUT_DECTECTOR_COUNT*ALGO_MAX_DETECTOR_OBJECTS-1 downto 0);
                    
                    reset                    => ap_rst                          --: in std_logic
                );
            
        end generate gen_object_buffer_levels_1_and_2;
        
        -- ========================= 
--        gen_object_buffer_levels_1_and_2 : if FALSE generate
--        begin
--            level1_buffers : tmux_wrapper_level1_buffers    
--                generic map (
--                    LINK_COUNT => FIBER_GROUPS * FIBERS_IN_GROUP 
--                )
--                port map (
--                    reset                           => ap_rst,
--                    clk120                          => ap_clk,
--                    clk240                          => clk_240,
                    
--                    link_big_region_end             => link_big_region_ends,
                    
--                    link_object_in                  => link_objects_to_level1,
--                    link_object_we_in               => link_objects_to_level1_we,
--                    level2_token_in                 => (others => '0')
--                );
--            level2_buffers : tmux_wrapper_level2_buffers 
--                port map (
--                    reset                           => ap_rst,
--                    clk120                          => ap_clk,
--                    clk240                          => clk_240--,
--                    --link_object_in                  => link_objects_to_level1,
--                    --link_object_we_in               => link_objects_to_level1_we,
--                    --level2_token_in                 => (others => '0')
--                );
            
--        end generate gen_object_buffer_levels_1_and_2;
        
   end generate gen_physics_object_buffer_levels; 
        
   
     
    
--    --for every 6 fibers.. use tmux_buffers for ...
--    --    the full data will be availble after 18x 120MHz clocks or 6x 40MHz clocks
--    --    stack them up in tmux_buffers, and present each for 3x 120MHz clocks or 1x 40 MHz clock
    
--    --generate fiber buffer approach 
--    --    (each fiber should buffer the same way in a group of 6)  
--    gen_fiber_group_buffer : for g in 0 to FIBER_GROUPS-1 generate
--    begin
    
--        gen_fiber_buffer : for i in 0 to FIBERS_IN_GROUP-1 generate
--        begin
            
--            process(ap_clk)
--            begin
            
--                if(rising_edge(ap_clk)) then
                    
--                    tmux_buffers(g)(i).valid <= '0';
                    
--                    --shift data in 
--                    if(has_reset = '1' and ap_rst_delay(3) = '0' and in_cyc(g*FIBERS_IN_GROUP + i) = 0 ) then
--                        tmux_buffers(g)(i).valid <= '1';
--                        tmux_buffers(g)(i).source_fiber <= (g*FIBERS_IN_GROUP + i);
--                        tmux_buffers(g)(i).fiber_group <= g;
--                        tmux_buffers(g)(i).fiber_in_group <= i;
                        
--                        tmux_buffers(g)(i).last_data <= link_in_reg(g*FIBERS_IN_GROUP + i);
--                        tmux_buffers(g)(i).data <=
--                            tmux_buffers(g)(i).data((ALGO_DATA_SIZE-1)-TMUX_INPUT_WORD_SIZE downto 0) &
--                            link_in_reg(g*FIBERS_IN_GROUP + i);
--                    end if;
--                end if;
--            end process;
    
--        end generate;
--    end generate;
    

--    --reshuffle data for algo based on tmux
--    --  i.e. map tmux_buffers onto tmux_algo_in
--    process(ap_clk)
--    begin
    
--        if(rising_edge(ap_clk)) then
            
--            tmux_algo_in.valid      <= '0';
        
        
--            if(has_reset = '0' or ap_rst_delay(3) = '1') then
--                buffer_count <= (others => '0');
--                buffer_state <= (others => '0');
--            elsif(ap_rst_delay(3) = '0' or --assume process started with data valid 0
--                (buffer_state > 0 and buffer_state < 4)) then --but keep counters going while states matter
            
--                buffer_count <= buffer_count + 1;
--                if(buffer_count = 17) then --this is 18!
--                    buffer_count <= (others => '0');
--                    buffer_state <= buffer_state + 1;
--                    if(buffer_state = 3 and ap_start_unp = '1') then
--                        buffer_state <= (0=>'1',others => '0'); --reset to 1
--                    end if;    
--                end if;
            
--                if(buffer_state > 0) then
                
--                    if(
--                        buffer_count = 0 or
--                        buffer_count = 3 or
--                        buffer_count = 6 or 
--                        buffer_count = 9 or
--                        buffer_count = 12 or
--                        buffer_count = 15) then
                        
                        
--                        tmux_algo_in.valid <= '1';
--                        tmux_algo_in.data <= tmux_buffers(to_integer(buffer_state)-1)((to_integer(buffer_count)+0)/3).data;
--                        tmux_algo_in.source_fiber <= (to_integer(buffer_state)-1)*FIBERS_IN_GROUP + ((to_integer(buffer_count)+0)/3);                            
--                        tmux_algo_in.fiber_group <= (to_integer(buffer_state)-1);
--                        tmux_algo_in.fiber_in_group <= ((to_integer(buffer_count)+0)/3);
--                    end if;
                   
--                end if;
            
--            end if;
        
--        end if;
--    end process;
    
--    algo_in.valid  <= tmux_algo_in.valid;
--    algo_in.source_fiber  <= tmux_algo_in.source_fiber;
--    algo_in.fiber_group  <= tmux_algo_in.fiber_group;
--    algo_in.fiber_in_group  <= tmux_algo_in.fiber_in_group;
--    gen_algo_in : for tmux_segment in 0 to ALGO_DATA_SIZE/TMUX_INPUT_WORD_SIZE-1 generate
--        algo_in.data(tmux_segment) <= tmux_algo_in.data(
--            TMUX_INPUT_WORD_SIZE*(tmux_segment+1)-1 downto TMUX_INPUT_WORD_SIZE*tmux_segment);
            
      
--    end generate;

	
  
--    --connect to HLS algo block    
--    i_algo_unpacked : algo_unpacked
--    port map (
--      ap_clk   => ap_clk_unp,
--      ap_rst   => ap_rst_unp,
--      ap_start => ap_start_unp,
--      ap_done  => ap_done_unp,
--      ap_idle  => ap_idle_unp,
--      ap_ready => ap_ready_unp,
    
--      link_in_0_V  => algo_in.data(0),
--      link_in_1_V  => algo_in.data(1),
--      link_in_2_V  => algo_in.data(2),
--      link_in_3_V  => algo_in.data(3),
--      link_in_4_V  => algo_in.data(4),
--      link_in_5_V  => algo_in.data(5),
--      link_in_6_V  => algo_in.data(6),
--      link_in_7_V  => algo_in.data(7),
--      link_in_8_V  => algo_in.data(8),
--      link_in_9_V  => algo_in.data(9),
--      link_in_10_V => algo_in.data(10),
--      link_in_11_V => algo_in.data(11),
--      link_in_12_V => algo_in.data(12),
--      link_in_13_V => algo_in.data(13),
--      link_in_14_V => algo_in.data(14),
--      link_in_15_V => algo_in.data(15),
--      link_in_16_V => algo_in.data(16),
--      link_in_17_V => algo_in.data(17),
--      link_in_18_V => algo_in.data(18),
--      link_in_19_V => algo_in.data(19),
--      link_in_20_V => algo_in.data(20),
--      link_in_21_V => algo_in.data(21),
--      link_in_22_V => algo_in.data(22),
--      link_in_23_V => algo_in.data(23),
--      link_in_24_V => algo_in.data(24),
--      link_in_25_V => algo_in.data(25),
--      link_in_26_V => algo_in.data(26),
--      link_in_27_V => algo_in.data(27),
--      link_in_28_V => algo_in.data(28),
--      link_in_29_V => algo_in.data(29),
--      link_in_30_V => algo_in.data(30),
--      link_in_31_V => algo_in.data(31),
--      link_in_32_V => algo_in.data(32),
--      link_in_33_V => algo_in.data(33),
--      link_in_34_V => algo_in.data(34),
--      link_in_35_V => algo_in.data(35),
--      link_in_36_V => algo_in.data(36),
--      link_in_37_V => algo_in.data(37),
--      link_in_38_V => algo_in.data(38),
--      link_in_39_V => algo_in.data(39),
--      link_in_40_V => algo_in.data(40),
--      link_in_41_V => algo_in.data(41),
--      link_in_42_V => algo_in.data(42),
--      link_in_43_V => algo_in.data(43),
--      link_in_44_V => algo_in.data(44),
--      link_in_45_V => algo_in.data(45),
--      link_in_46_V => algo_in.data(46),
--      link_in_47_V => algo_in.data(47),
    
--      link_out_0_V  => link_out(0),
--      link_out_1_V  => link_out(1),
--      link_out_2_V  => link_out(2),
--      link_out_3_V  => link_out(3),
--      link_out_4_V  => link_out(4),
--      link_out_5_V  => link_out(5),
--      link_out_6_V  => link_out(6),
--      link_out_7_V  => link_out(7),
--      link_out_8_V  => link_out(8),
--      link_out_9_V  => link_out(9),
--      link_out_10_V => link_out(10),
--      link_out_11_V => link_out(11),
--      link_out_12_V => link_out(12),
--      link_out_13_V => link_out(13),
--      link_out_14_V => link_out(14),
--      link_out_15_V => link_out(15),
--      link_out_16_V => link_out(16),
--      link_out_17_V => link_out(17),
--      link_out_18_V => link_out(18),
--      link_out_19_V => link_out(19),
--      link_out_20_V => link_out(20),
--      link_out_21_V => link_out(21),
--      link_out_22_V => link_out(22),
--      link_out_23_V => link_out(23),
--      link_out_24_V => link_out(24),
--      link_out_25_V => link_out(25),
--      link_out_26_V => link_out(26),
--      link_out_27_V => link_out(27),
--      link_out_28_V => link_out(28),
--      link_out_29_V => link_out(29),
--      link_out_30_V => link_out(30),
--      link_out_31_V => link_out(31),
--      link_out_32_V => link_out(32),
--      link_out_33_V => link_out(33),
--      link_out_34_V => link_out(34),
--      link_out_35_V => link_out(35),
--      link_out_36_V => link_out(36),
--      link_out_37_V => link_out(37),
--      link_out_38_V => link_out(38),
--      link_out_39_V => link_out(39),
--      link_out_40_V => link_out(40),
--      link_out_41_V => link_out(41),
--      link_out_42_V => link_out(42),
--      link_out_43_V => link_out(43),
--      link_out_44_V => link_out(44),
--      link_out_45_V => link_out(45),
--      link_out_46_V => link_out(46),
--      link_out_47_V => link_out(47),
    
    
--      link_out_0_V_ap_vld  => link_out_ap_vld(0),
--      link_out_1_V_ap_vld  => link_out_ap_vld(1),
--      link_out_2_V_ap_vld  => link_out_ap_vld(2),
--      link_out_3_V_ap_vld  => link_out_ap_vld(3),
--      link_out_4_V_ap_vld  => link_out_ap_vld(4),
--      link_out_5_V_ap_vld  => link_out_ap_vld(5),
--      link_out_6_V_ap_vld  => link_out_ap_vld(6),
--      link_out_7_V_ap_vld  => link_out_ap_vld(7),
--      link_out_8_V_ap_vld  => link_out_ap_vld(8),
--      link_out_9_V_ap_vld  => link_out_ap_vld(9),
--      link_out_10_V_ap_vld => link_out_ap_vld(10),
--      link_out_11_V_ap_vld => link_out_ap_vld(11),
--      link_out_12_V_ap_vld => link_out_ap_vld(12),
--      link_out_13_V_ap_vld => link_out_ap_vld(13),
--      link_out_14_V_ap_vld => link_out_ap_vld(14),
--      link_out_15_V_ap_vld => link_out_ap_vld(15),
--      link_out_16_V_ap_vld => link_out_ap_vld(16),
--      link_out_17_V_ap_vld => link_out_ap_vld(17),
--      link_out_18_V_ap_vld => link_out_ap_vld(18),
--      link_out_19_V_ap_vld => link_out_ap_vld(19),
--      link_out_20_V_ap_vld => link_out_ap_vld(20),
--      link_out_21_V_ap_vld => link_out_ap_vld(21),
--      link_out_22_V_ap_vld => link_out_ap_vld(22),
--      link_out_23_V_ap_vld => link_out_ap_vld(23),
--      link_out_24_V_ap_vld => link_out_ap_vld(24),
--      link_out_25_V_ap_vld => link_out_ap_vld(25),
--      link_out_26_V_ap_vld => link_out_ap_vld(26),
--      link_out_27_V_ap_vld => link_out_ap_vld(27),
--      link_out_28_V_ap_vld => link_out_ap_vld(28),
--      link_out_29_V_ap_vld => link_out_ap_vld(29),
--      link_out_30_V_ap_vld => link_out_ap_vld(30),
--      link_out_31_V_ap_vld => link_out_ap_vld(31),
--      link_out_32_V_ap_vld => link_out_ap_vld(32),
--      link_out_33_V_ap_vld => link_out_ap_vld(33),
--      link_out_34_V_ap_vld => link_out_ap_vld(34),
--      link_out_35_V_ap_vld => link_out_ap_vld(35),
--      link_out_36_V_ap_vld => link_out_ap_vld(36),
--      link_out_37_V_ap_vld => link_out_ap_vld(37),
--      link_out_38_V_ap_vld => link_out_ap_vld(38),
--      link_out_39_V_ap_vld => link_out_ap_vld(39),
--      link_out_40_V_ap_vld => link_out_ap_vld(40),
--      link_out_41_V_ap_vld => link_out_ap_vld(41),
--      link_out_42_V_ap_vld => link_out_ap_vld(42),
--      link_out_43_V_ap_vld => link_out_ap_vld(43),
--      link_out_44_V_ap_vld => link_out_ap_vld(44),
--      link_out_45_V_ap_vld => link_out_ap_vld(45),
--      link_out_46_V_ap_vld => link_out_ap_vld(46),
--      link_out_47_V_ap_vld => link_out_ap_vld(47)
    
--      );
  
end arch;
 
