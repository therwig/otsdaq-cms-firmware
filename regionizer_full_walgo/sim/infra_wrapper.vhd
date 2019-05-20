							  
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
            
            algo_in_debug       : out algo_input_physics_objects_t;
            
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
 
    component infra_fifo 
        port ( 
            
            clk : IN STD_LOGIC;
            srst : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC;
            wr_rst_busy : OUT STD_LOGIC;
            rd_rst_busy : OUT STD_LOGIC
        );
    end component infra_fifo;
    
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



    -- ==========================================================================================
    --make links and 600+ BRAMs to represent infrastructure
    --  one fifo for output and INFRA_FIFOS_PER_FIBER-2 for input
    gen_infra_links: for i in 0 to MAX_FIBER_COUNT-1 generate
        
        signal din_word     : std_logic_vector(INPUT_WORD_SIZE-1 downto 0);
        
        type fifo_shr_t is array(natural range <> ) of std_logic_vector(INPUT_WORD_SIZE-1 downto 0);
        signal fifo_shr     : fifo_shr_t(INFRA_FIFOS_PER_FIBER-1 downto 0);
        
    begin
    
        process(link_clk)
        begin
            if (rising_edge(link_clk)) then
                din_word    <= din_word(INPUT_WORD_SIZE-2 downto 0) & link_serial_din(i);
            end if;
        end process;
    
        --into and out of fifo chain
        fifo_shr(0)             <= din_word;
        links_in(i).tData       <= fifo_shr(INFRA_FIFOS_PER_FIBER-1); 
        links_in(i).tValid      <= link_serial_din(i);
    
        --input link fifos
        gen_infra_link_din_fifos: for j in 0 to INFRA_FIFOS_PER_FIBER-2 generate     
            signal din      : std_logic_vector(INPUT_WORD_SIZE-1 downto 0);
            signal dout     : std_logic_vector(INPUT_WORD_SIZE-1 downto 0);           
        begin 
        
            --into and out of input fifo
            din                     <= fifo_shr(j);
            fifo_shr(j+1)           <= dout;
        
            fifo : infra_fifo
                port map ( 
                    
                    clk             => link_clk,                        --: IN STD_LOGIC;
                    srst            => '0',                             --: IN STD_LOGIC;
                    din             => din,                             --: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
                    wr_en           => '1',                             --: IN STD_LOGIC;
                    rd_en           => '1',                             --: IN STD_LOGIC;
                    dout            => dout,                            --: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
                    full            => open,                            --: OUT STD_LOGIC;
                    empty           => open,                            --: OUT STD_LOGIC;
                    wr_rst_busy     => open,                            --: OUT STD_LOGIC;
                    rd_rst_busy     => open                             --: OUT STD_LOGIC
                );            

        end generate gen_infra_link_din_fifos;
    
        --output link fifo
        gen_infra_link_dout_fifos: if TRUE generate   
            signal din : std_logic_vector(INPUT_WORD_SIZE-1 downto 0);
            signal dout : std_logic_vector(INPUT_WORD_SIZE-1 downto 0);           
        begin 
        
            --into and out of output fifo
            din                     <= links_out(i).tData;
            link_serial_dout(i)     <= or_reduce(dout);
            
            fifo : infra_fifo
            port map ( 
                
                clk             => link_clk,                        --: IN STD_LOGIC;
                srst            => '0',                             --: IN STD_LOGIC;
                din             => din,                             --: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
                wr_en           => links_out(i).tValid,             --: IN STD_LOGIC;
                rd_en           => '1',                             --: IN STD_LOGIC;
                dout            => dout,                            --: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
                full            => open,                            --: OUT STD_LOGIC;
                empty           => open,                            --: OUT STD_LOGIC;
                wr_rst_busy     => open,                            --: OUT STD_LOGIC;
                rd_rst_busy     => open    
            );
                                     
        end generate gen_infra_link_dout_fifos;
        
    end generate gen_infra_links;
  
  
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
 
