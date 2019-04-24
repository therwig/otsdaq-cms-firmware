

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
    
    constant TMUX_INPUT_WORD_SIZE       : natural := 64; --in bits
    constant PHYSICS_OBJECT_BIT_SIZE    : natural := 64; --in bits 
    
    
    constant LEVEL1_RAMS_PER_LINK       : natural := 6; -- Level-1 RAMs per link (i.e. if 6, then 5 of 30 s.r. in each RAM)    
    constant LEVEL2_SR_SEGMENTS         : natural := 3; -- Level-2 RAMs per Algo-input-opbject (i.e. if 3, then 10 of 30 s.r. in each RAM)
    
    constant INPUT_DECTECTOR_COUNT      : natural := 3;
    constant ALGO_MAX_DETECTOR_OBJECTS  : natural := 30;
    constant ALGO_INPUT_OBJECTS_COUNT   : natural := 100;
    
--    constant ALGO_INPUT_CHANNEL_COUNT   : natural := 94;
--    constant ALGO_INPUT_CHANNEL_SIZE    : natural := 32; --in bits
--    constant ALGO_DATA_SIZE             : natural := ALGO_INPUT_CHANNEL_SIZE * ALGO_INPUT_CHANNEL_COUNT;  
    
--    constant TMUX_BUFFER_DATA_SIZE : natural := ALGO_DATA_SIZE / TMUX_INPUT_WORD_SIZE;
        
    type link_input_data_arr_t is array(integer range <>) of std_logic_vector(TMUX_INPUT_WORD_SIZE-1 downto 0); 
    
    subtype raw_physics_object_t is std_logic_vector(PHYSICS_OBJECT_BIT_SIZE-1 downto 0);
    type raw_physics_object_arr_t is array(integer range <>) of raw_physics_object_t;
    
    
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
        lsEM                : std_logic;             --just calo
        z0                  : signed(9 downto 0);  --just tracker
        otherPt             : signed(15 downto 0); --pt-err or em-pt (for calo)
        pt                  : signed(15 downto 0);
        
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
            lsEM                => '0',
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

    constant ETA_OVERLAP_SIZE       : integer := 32;
    constant PHI_OVERLAP_SIZE       : integer := 32;
    
    -- apply big region offset to center in region associated wit this FPGA
    --  TODO -- make these big region offsets registers
    constant ETA_BIG_REGION_OFFSET  : integer := 0; -- eta big regions boundaries are at BR0 | -243 | BR1 | +243 | BR2 
                                                    -- possible eta offsets ?: +486, 0, -486
    constant PHI_BIG_REGION_OFFSET  : integer := 0; -- phi big regions boundaries are at BR0 | -170 | BR1 | +170 | BR2
                                                    -- possible phi offsets ?: +240, 0, -240    

    function is_eta_small_region_overlap(
        eta                 : signed(9 downto 0))
                    return std_logic;
    function is_phi_small_region_overlap(
        phi                 : signed(9 downto 0))
                    return std_logic;
    function get_eta_small_region_index(
        eta                 : signed(9 downto 0);
        i                   : natural) -- i from 0 to 1
                    return integer;
    function get_phi_small_region_index(
        phi                 : signed(9 downto 0);
        i                   : natural) -- i from 0 to 1
                    return integer;
                    
    type get_eta_phi_small_region_t is record
        eta_small_region    : natural;
        phi_small_region    : natural;
        eta_phi_small_region: natural;
        is_another          : std_logic; --indicate there is another small region to get
    end record;
    
    function get_eta_phi_small_region(
        eta                 : signed(9 downto 0);
        phi                 : signed(9 downto 0);
        i                   : natural) -- i from 0 to 3
       return  get_eta_phi_small_region_t;
            
end tmux_params_pkg;

package body tmux_params_pkg is
     
  
    -- ==========================================================================================
    --  is_eta_small_region_overlap
    --      return '1' if in overlap region
    function is_eta_small_region_overlap(
        eta:signed(9 downto 0))
        return std_logic is
            
    begin
    
        if(
            (eta > -170 - ETA_OVERLAP_SIZE/2 and 
            eta < -170 + ETA_OVERLAP_SIZE/2) or 
            (eta > 170 - ETA_OVERLAP_SIZE/2 and 
            eta < 170 + ETA_OVERLAP_SIZE/2) 
            ) then
            return '1';
        else
            return '0';
        end if;
    end;   --function is_eta_small_region_overlap 
    
    -- ==========================================================================================
    --  is_phi_small_region_overlap
    --      return '1' if in overlap region
    function is_phi_small_region_overlap(
        phi:signed(9 downto 0))
        return std_logic is
            
    begin
    
        if(
            (phi > 0 - PHI_OVERLAP_SIZE/2 and
             phi < 0 + PHI_OVERLAP_SIZE/2) 
            ) then
            return '1';
        else
            return '0';
        end if;
    end;   --function is_phi_small_region_overlap 
    
    
    
    -- ==========================================================================================
    --  get_eta_small_region_index
    --      Convert the eta bit field to eta small region index
    function get_eta_small_region_index(
        eta                 : signed(9 downto 0);
        i                   : natural)
        return integer is
    
    begin
        
        --consider potential overlaps first
        if(eta > -170 - ETA_OVERLAP_SIZE/2 and 
            eta < -170 + ETA_OVERLAP_SIZE/2) then
        
            if(i = 0) then
                return 0;
            else
                return 1;
            end if;
            
        elsif(eta > 170 - ETA_OVERLAP_SIZE/2 and 
            eta < 170 + ETA_OVERLAP_SIZE/2) then
         
            if(i = 0) then
                return 1;
            else
                return 2;
            end if;
            
        elsif(eta < -170) then -- done with overlaps
            return 0;
        elsif(eta < 170) then
            return 1;
        else
            return 2;
        end if;
        
    end;   --function get_eta_small_region_index     
    
    -- ==========================================================================================
    --  get_phi_small_region_index
    --      Convert the phi bit field to phi small region index
    function get_phi_small_region_index(
        phi                 : signed(9 downto 0);
        i                   : natural)
        return integer is
    
    begin
    
        --consider potential overlaps first
        if(phi > 0 - PHI_OVERLAP_SIZE/2 and
                 phi < 0 + PHI_OVERLAP_SIZE/2) then
                
            if(i = 0) then
                return 0;
            else
                return 1;
            end if;
            
        elsif(phi < 0) then -- done with overlaps
            return 0;
        else
            return 1;
        end if;
        
    end;   --function get_phi_small_region_index               
          
    -- ==========================================================================================
    --  get_eta_phi_small_region
    --      Get the eta-phi small region index
    --      Note: for a given eta-phi pair, there may be 
    --          1,2 or 4 associated small regions. Use i to index
    --          the associate small regions.
    function get_eta_phi_small_region(
        eta                 : signed(9 downto 0);
        phi                 : signed(9 downto 0);
        i                   : natural) -- i from 0 to 3
            return  get_eta_phi_small_region_t is
        variable return_object : get_eta_phi_small_region_t;
    begin
        
        if(i = 0) then
        
            return_object.eta_small_region := 
                get_eta_small_region_index(eta,0);
            return_object.phi_small_region := 
                get_phi_small_region_index(phi,0);  
            return_object.eta_phi_small_region := 
                ALGO_INPUT_SMALL_REGION_ETA_SIZE * 
                return_object.phi_small_region +
                return_object.eta_small_region;
            return_object.is_another := 
                is_eta_small_region_overlap(eta) or
                is_phi_small_region_overlap(phi);
                
        elsif(i = 1) then
        
            --take from eta first if both, otherwise take phi
            if(is_eta_small_region_overlap(eta) = '1') then
                return_object.eta_small_region := 
                    get_eta_small_region_index(eta,1);
                return_object.phi_small_region := 
                    get_phi_small_region_index(phi,0);
            else
                return_object.eta_small_region := 
                    get_eta_small_region_index(eta,0);
                return_object.phi_small_region := 
                    get_phi_small_region_index(phi,1); 
            end if;
            
            return_object.eta_phi_small_region := 
                ALGO_INPUT_SMALL_REGION_ETA_SIZE * 
                return_object.phi_small_region +
                return_object.eta_small_region;
            return_object.is_another := 
                is_eta_small_region_overlap(eta) and
                is_phi_small_region_overlap(phi);
                
        elsif(i = 2) then
        
            --take from phi now
            return_object.eta_small_region := 
                get_eta_small_region_index(eta,0);
            return_object.phi_small_region := 
                get_phi_small_region_index(phi,1); 
            
            return_object.eta_phi_small_region := 
                ALGO_INPUT_SMALL_REGION_ETA_SIZE * 
                return_object.phi_small_region +
                return_object.eta_small_region;
            return_object.is_another := '1'; -- must get 4th
            
        elsif(i = 3) then
        
            --take second from eta and phi last
            return_object.eta_small_region := 
                get_eta_small_region_index(eta,1);
            return_object.phi_small_region := 
                get_phi_small_region_index(phi,1); 
            
            return_object.eta_phi_small_region := 
                ALGO_INPUT_SMALL_REGION_ETA_SIZE * 
                return_object.phi_small_region +
                return_object.eta_small_region;
            return_object.is_another := '0'; -- no more
                
        end if;
        
        return return_object;
    end;   --function get_phi_small_region_index               
          
    
end tmux_params_pkg;
 
