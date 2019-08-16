							  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.regionizer_pkg.all;  
use work.algo_pkg.all; 


library UNISIM;
use UNISIM.Vcomponents.ALL;

entity infra_wrapper is
    port(
  
        link_clk_port           : in  std_logic;
        reset_port              : in  std_logic;
        algo_reset_port         : in  std_logic;
        
        link_serial_din_port    : in std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
        link_serial_dout_port   : out std_logic_vector(MAX_FIBER_COUNT-1 downto 0)
        
    );
end;
   
architecture arch of infra_wrapper is
  
    component regionizer_wrapper 
    port(
     
            link_clk            : in  std_logic;
            
            algo_in_debug       : out raw_physics_object_arr_t(ALGO_INPUT_OBJECTS_COUNT-1 downto 0);
            algo_in_vertex_debug: out std_logic_vector(VERTEX_BIT_WIDTH-1 downto 0);
            algo_in_valid_debug : out std_logic;
            
            algo_out_debug      : out raw_algo_object_out_arr_t(ALGO_OBJECTS_OUT-1 downto 0);
            algo_out_valid_debug: out std_logic;
            
            -- Input Links 
            link_in_master      : in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_in_slave       : out LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
            
            -- Output Links 
            link_out_master     : out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_out_slave      : in  LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
            
            algo_reset          : in  std_logic;
            reset               : in  std_logic
   
    );
    end component regionizer_wrapper;
 
    component infra
        port(
      
            link_serial_din         : in  std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
            link_serial_dout        : out std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
            
            links_out               : in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            links_in                : out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            
            link_clk                : in  std_logic
    
        ); 
    end component infra;
    
--    component infra_fifo 
--        port ( 
            
--            clk : IN STD_LOGIC;
--            srst : IN STD_LOGIC;
--            din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
--            wr_en : IN STD_LOGIC;
--            rd_en : IN STD_LOGIC;
--            dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
--            full : OUT STD_LOGIC;
--            empty : OUT STD_LOGIC;
--            wr_rst_busy : OUT STD_LOGIC;
--            rd_rst_busy : OUT STD_LOGIC
--        );
--    end component infra_fifo;
    
    signal link_clk         : std_logic;
    signal reset            : std_logic;
    signal algo_reset       : std_logic;
    signal link_serial_din  : std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
    signal link_serial_dout : std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
            
    signal links_in         : LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
    signal links_out        : LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
    signal slave_in         : LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
begin

    --make regionizer wrapper
    algo : regionizer_wrapper
        port map(
      
            link_clk                => link_clk,            --: in  std_logic;
            
            algo_in_debug           => open,                --: out algo_input_physics_objects_t;
            
            -- Input Links 
            link_in_master          => links_in,            --: in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_in_slave           => open,                --: out LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
            
            -- Output Links 
            link_out_master         => links_out,           --: out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            link_out_slave          => slave_in,            --: in  LinkSlaveArrType(MAX_FIBER_COUNT-1 downto 0);
        
            algo_reset              => algo_reset,          --: in  std_logic
            reset                   => reset                --: in  std_logic
    
        ); 


    infra_inst : infra
        port map (
      
            link_serial_din         => link_serial_din,     --: in  std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
            link_serial_dout        => link_serial_dout,    --: out std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
            
            links_out               => links_out,           --: in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            links_in                => links_in,            --: out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
            
            link_clk                => link_clk             --: in  std_logic
    
        ); 
    
  
    gen_link_ibufs : for i in 0 to MAX_FIBER_COUNT-1 generate
        link_ibuf       : IBUF  port map (I=>link_serial_din_port(i), O=>link_serial_din(i));
    end generate gen_link_ibufs;
  
    gen_link_obufs : for i in 0 to MAX_FIBER_COUNT-1 generate
        link_obuf       : OBUF  port map (I=>link_serial_dout(i), O=>link_serial_dout_port(i));
    end generate gen_link_obufs;
    
    link_clk_ibufg      : IBUFG port map (I=>link_clk_port, O=>link_clk);
    reset_bufg          : IBUF  port map (I=>reset_port, O=>reset);
    algo_reset_ibuf     : IBUF  port map (I=>algo_reset_port, O=>algo_reset);
    
end arch;
 
