

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--a la AlgorithConstants from old CMS_CAL/work
package tmux_params_pkg is

    
--    --package algo_pkg is
    
--    type LinkMasterType is record
--    tValid : std_logic;
--    tData  : std_logic_vector(63 downto 0);
--    tLast  : std_logic;
--    end record LinkMasterType;
    
--    type LinkMasterArrType is array (natural range<>) of LinkMasterType;
    
--    type LinkSlaveType is record
--    tReady : std_logic;
--    end record LinkSlaveType;
    
--    type LinkSlaveArrType is array (natural range<>) of LinkSlaveType;
--    --end package algo_pkg is

    constant MAX_FIBER_COUNT           : natural := 48;
    
    constant FIBERS_IN_GROUP           : natural := 14;
    constant FIBER_GROUPS              : natural := 3;
    
	constant INPUT_FIBERS              : natural := FIBER_GROUPS * FIBERS_IN_GROUP; -- up to MAX_FIBER_COUNT
	constant INPUT_WORD_SIZE           : natural := 64; --in bits 
	
    type input_fiber_t is array(natural range <> ) of std_logic_vector(INPUT_WORD_SIZE-1 downto 0);
	
    constant OUTPUT_FIBERS              : natural := 8;
    constant OUTPUT_WORD_SIZE           : natural := 64; --in bits
    
    constant TMUX_INPUT_WORD_SIZE       : natural := 192; --in bits 
    
--    constant ALGO_INPUT_CHANNEL_COUNT   : natural := 94;
--    constant ALGO_INPUT_CHANNEL_SIZE    : natural := 32; --in bits
--    constant ALGO_DATA_SIZE             : natural := ALGO_INPUT_CHANNEL_SIZE * ALGO_INPUT_CHANNEL_COUNT;  
    
--    constant TMUX_BUFFER_DATA_SIZE : natural := ALGO_DATA_SIZE / TMUX_INPUT_WORD_SIZE;
        
    type link_input_data_arr_t is array(integer range <>) of std_logic_vector(TMUX_INPUT_WORD_SIZE-1 downto 0); 
    --type algo_tmux_buffer_data_arr_t is array(integer range <>) of std_logic_vector(ALGO_DATA_SIZE-1 downto 0);   
    
--    --single input link buffer and debugging info
--    type input_buffer_t is record
--        data : std_logic_vector(ALGO_DATA_SIZE-1 downto 0);
--        valid: std_logic; --for debugging (kind of used improperly)
--        last_data: std_logic_vector(TMUX_INPUT_WORD_SIZE-1 downto 0); --for debugging
--        source_fiber: natural; --for debugging
--        fiber_group: natural; --for debugging
--        fiber_in_group: natural; --for debugging
--    end record; 
    
--    --full tmux buffer and debugging info
--    type algo_tmux_buffer_t is record
--        data : std_logic_vector(ALGO_DATA_SIZE-1 downto 0);--algo_tmux_buffer_data_arr_t(TMUX_BUFFER_DATA_SIZE-1 downto 0);
--        valid: std_logic;
--        source_fiber: natural; --for debugging
--        fiber_group: natural; --for debugging
--        fiber_in_group: natural; --for debugging
--    end record; 

    constant VERTEX_BIT_WIDTH   : natural := 10;
    constant ALGO_INPUT_SMALL_REGION_ETA_SIZE   : natural := 3;
    constant ALGO_INPUT_SMALL_REGION_PHI_SIZE   : natural := 2;
    
    type physics_object_t is record
        --64 bit object break down:
        phi                 : signed(9 downto 0);
        eta                 : signed(9 downto 0);
        
        quality             : std_logic;             --just tracker
        z0                  : unsigned(9 downto 0);  --just tracker
        otherPt             : unsigned(15 downto 0); --pt-err or em-pt (for calo)
        pt                  : unsigned(15 downto 0);
        
        small_region_eta    : integer range 0 to ALGO_INPUT_SMALL_REGION_ETA_SIZE;   
        small_region_phi    : integer range 0 to ALGO_INPUT_SMALL_REGION_PHI_SIZE;
        
        --for debugging
        source_fiber        : natural;
        source_event_index  : natural;       
    end record; 
    
    type physics_object_arr_t is array(integer range <>) of physics_object_t;
    
    
    --algorithm inputs interpreted as physics objects
    type algo_input_physics_objects_t is record
    
        emcalo_objects      : physics_object_arr_t(14 downto 0);
        calo_objects        : physics_object_arr_t(14 downto 0); 
        trk_objects         : physics_object_arr_t(14 downto 0); 
        muon_objects        : physics_object_arr_t(1 downto 0);
         
        vertex              : std_logic_vector(VERTEX_BIT_WIDTH-1 downto 0);
        
        --for debugging
        source_event_index  : natural;
        small_region_eta    : integer range 0 to ALGO_INPUT_SMALL_REGION_ETA_SIZE;
        small_region_phi    : integer range 0 to ALGO_INPUT_SMALL_REGION_PHI_SIZE;   
    end record;
    
    type event_small_region_eta_arr_t               is array(integer range <>) of algo_input_physics_objects_t;    
    subtype event_small_region_eta_buffer_t         is event_small_region_eta_arr_t(ALGO_INPUT_SMALL_REGION_ETA_SIZE-1 downto 0);
    type event_small_region_phi_eta_arr_t           is array(integer range <>) of event_small_region_eta_buffer_t;
    subtype event_small_region_phi_eta_buffer_t     is event_small_region_phi_eta_arr_t(ALGO_INPUT_SMALL_REGION_PHI_SIZE-1 downto 0);
    
    type event_small_region_phi_eta_buffer_arr_t    is array(integer range <>) of event_small_region_phi_eta_buffer_t;
    
    
    --algorithm inputs interpreted as bit busses
    --full input into HLS and debugging info
    --FIXME -- algo is now 94 x 32b + vertex
    type algo_input_data_arr_t is array(integer range <>) of std_logic_vector(192-1 downto 0);
    type algo_input_t is record
        data                : algo_input_data_arr_t(48-1 downto 0);
        valid               : std_logic;
        
        --for debugging
        source_fiber        : natural; 
        fiber_group         : natural; 
        fiber_in_group      : natural;
    end record; 
    
    
    type output_fiber_t is array(natural range <> ) of std_logic_vector(OUTPUT_WORD_SIZE-1 downto 0);
    
    
    constant null_physics_object :  physics_object_t := (
            phi                 => (others => '0'),
            eta                 => (others => '0'),
            quality             => '0',
            z0                  => (others => '0'),
            otherPt             => (others => '0'),
            pt                  => (others => '0'),
            
            small_region_phi    => 0,
            small_region_eta    => 0,
            
            source_fiber        => 2147483647,
            source_event_index  => 2147483647
        );
    constant null_event_buffer : event_small_region_phi_eta_buffer_t := ( 
        --phi
        others => (
            --eta 
            others => (
                 emcalo_objects     => (others => null_physics_object),
                 calo_objects       => (others => null_physics_object),
                 trk_objects        => (others => null_physics_object),
                 muon_objects       => (others => null_physics_object),
                 
                 vertex             => (others => '0'),
                         
                 source_event_index => 2147483647,
                 small_region_phi   => 0,
                 small_region_eta   => 0
            )
        ));


--    --EXAMPLE from AlgorithmConstants from old CMS_CAL/work
--          function find_egamma_pipelined_col(eta_minus:std_logic; egamma: std_logic_vector(3 downto 0))
--                    return integer;

    function get_number_of_eta_small_regions(
        eta:signed(9 downto 0))
                    return integer;
    function get_number_of_phi_small_regions(
        phi:signed(9 downto 0))
                    return integer;
    function get_phi_small_region_index(
        phi:signed(9 downto 0))
                    return integer;
    function get_eta_small_region_index(
        eta:signed(9 downto 0))
                    return integer;
end tmux_params_pkg;

package body tmux_params_pkg is
  
   
    
--    --EXAMPLE from AlgorithmConstants from old CMS_CAL/work
--    --  Find col from Fiber Pair Number, Card, Region
--          function find_egamma_pipelined_col(eta_minus:std_logic; egamma: std_logic_vector(3 downto 0))
--                    return integer is
          
--            variable egamma_card : unsigned(2 downto 0);
--            variable egamma_card_rounded_region : unsigned(2 downto 0);
--                                        --variable egamma_region : unsigned
--                                        --(0 downto 0);
--            variable egamma_col : integer;
            
--        begin
          
--          egamma_card_rounded_region := unsigned(egamma(3 downto 2) & egamma(0));
--          egamma_card := unsigned(egamma(3 downto 1));
--          if (eta_minus='1' and egamma_card<6 ) then
--            egamma_col := CENTRAL_ETA_SLICES/2 - 1 - to_integer(egamma_card_rounded_region);
--          elsif (eta_minus='1' and egamma_card=6 ) then
--            egamma_col := 0;
--          elsif (eta_minus='0' and egamma_card<6 ) then
--            egamma_col := to_integer(egamma_card_rounded_region);
--          elsif (eta_minus='0' and egamma_card=6 ) then
--            egamma_col := CENTRAL_ETA_SLICES/22147483647;
--          end if;
          
--          return egamma_col;
--        end;     
  
    -- ==========================================================================================
    --  get_number_of_eta_small_regions
    --      return 2 if in overlap region
    function get_number_of_eta_small_regions(
        eta:signed(9 downto 0))
        return integer is
            
    begin
    
        if(
            (eta < -160 and eta > -180) or 
            (eta > 160 and eta < 180) 
            ) then
            return 2;
        else
            return 1;
        end if;
    end;   --function get_number_of_eta_small_regions 
    
    -- ==========================================================================================
    --  get_number_of_phi_small_regions
    --      return 2 if in overlap region
    function get_number_of_phi_small_regions(
        phi:signed(9 downto 0))
        return integer is
            
    begin
    
        if(
            (phi > -10 and phi < 10) 
            ) then
            return 2;
        else
            return 1;
        end if;
    end;   --function get_number_of_phi_small_regions 
    
    
    
    -- ==========================================================================================
    --  get_eta_small_region_index
    --      Convert the eta bit field to eta small region index
    function get_eta_small_region_index(eta:signed(9 downto 0))
        return integer is
    
    begin
    
        if(eta < -170) then
            return 0;
        elsif(eta < 171) then
            return 1;
        else
            return 2;
        end if;
    end;   --function get_eta_small_region_index     
    
    -- ==========================================================================================
    --  get_phi_small_region_index
    --      Convert the phi bit field to phi small region index
    function get_phi_small_region_index(phi:signed(9 downto 0))
        return integer is
    
    begin
    
        if(phi < 0) then
            return 0;
        else
            return 1;
        end if;
    end;   --function get_phi_small_region_index               
          
    
end tmux_params_pkg;
 
