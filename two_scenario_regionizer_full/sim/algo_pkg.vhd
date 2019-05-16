library ieee;
use ieee.std_logic_1164.all;

package algo_pkg is

    type LinkMasterType is record
        tValid : std_logic;
        tData  : std_logic_vector(63 downto 0);
        tLast  : std_logic;
    end record LinkMasterType;
    
    type LinkMasterArrType is array (natural range<>) of LinkMasterType;
    
    type LinkSlaveType is record
        tReady : std_logic;
    end record LinkSlaveType;
    
    type LinkSlaveArrType is array (natural range<>) of LinkSlaveType;
    
    
    constant ALGO_INPUT_BIT_SIZE                : natural := 32;
    constant ALGO_OUTPUT_BIT_SIZE               : natural := 32;
    
    constant null_raw_algo_object_in            : std_logic_vector(ALGO_INPUT_BIT_SIZE-1 downto 0) := (others => '0');
    
    constant ALGO_OBJECT_OUT_BIT_SIZE           : natural := 2*ALGO_OUTPUT_BIT_SIZE;
    subtype raw_algo_object_out_t is std_logic_vector(ALGO_OBJECT_OUT_BIT_SIZE-1 downto 0);
    type raw_algo_object_out_arr_t is array(integer range <>) of raw_algo_object_out_t;
    
    
    
    constant ALGO_OBJECTS_OUT                   : natural := 60;

end package;
