							  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.regionizer_pkg.all;  
use work.algo_pkg.all; 


library UNISIM;
use UNISIM.Vcomponents.ALL;

entity infra is
    port(
        link_serial_din         : in  std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
        link_serial_dout        : out std_logic_vector(MAX_FIBER_COUNT-1 downto 0);
        
        links_out               : in  LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
        links_in                : out LinkMasterArrType(MAX_FIBER_COUNT-1 downto 0);
        
        link_clk                : in  std_logic
    );
end;
   
architecture arch of infra is
  
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
   
begin


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
    
end arch;
 
