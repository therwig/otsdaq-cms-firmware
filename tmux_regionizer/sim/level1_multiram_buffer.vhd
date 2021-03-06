----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level1_multiram_buffer - Behavioral
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

use work.tmux_params_pkg.all;



-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity level1_multiram_buffer is
    generic (
        MULTIRAM_COUNT          : integer := LEVEL1_RAMS_PER_LINK
    );
    port ( 
        clk_link_to_level1     : in std_logic;
        
        link_big_region_end     : in std_logic;
        
        link_object_in          : in physics_object_t;
        link_object_we_in       : in std_logic;
        
        level2_re_in            : in std_logic;
        level2_eta_phi_rindex   : in get_eta_phi_small_region_t;        
        
        objects_out_valid       : out std_logic_vector(MULTIRAM_COUNT-1 downto 0);
        objects_out             : out raw_phyiscs_object_arr_t(MULTIRAM_COUNT-1 downto 0);
        
        overflow_error          : out std_logic;
        reset                   : in std_logic
    );
end level1_multiram_buffer;

architecture Behavioral of level1_multiram_buffer is

    component level1_uram_buffer    
           port (
            clk_link_to_level1     : in std_logic;
            
            link_big_region_end     : in std_logic;
            
            link_object_in          : in physics_object_t;
            link_object_we_in       : in std_logic;
            wobject_eta_phi_index   : in get_eta_phi_small_region_t;
            
            level2_re_in            : in std_logic;
            robject_eta_phi_index   : in get_eta_phi_small_region_t;
            robject_valid           : out std_logic;
            robject_dout            : out raw_phyiscs_object_t;
            
            overflow_error          : out std_logic;
            reset                   : in std_logic
           );
    end component level1_uram_buffer;
     

    signal link_object_in_latch     : raw_phyiscs_object_t;
           
    signal level1_ram_din_we        : std_logic_vector(MULTIRAM_COUNT-1 downto 0) := (others => '0');
    signal level1_ram_din           : raw_phyiscs_object_arr_t(MULTIRAM_COUNT-1 downto 0) := (others => (others => '0'));
    signal level1_ram_dout          : raw_phyiscs_object_arr_t(MULTIRAM_COUNT-1 downto 0);

    type get_eta_phi_small_region_arr_t is array(integer range <>) of get_eta_phi_small_region_t;
    signal din_eta_phi_small_region : get_eta_phi_small_region_arr_t(MULTIRAM_COUNT-1 downto 0);       
    
    signal level1_ram_overflow      : std_logic_vector(MULTIRAM_COUNT-1 downto 0);
    
begin

    --  This is a multiram buffer for a raw data link
    --    
    -- =====
    -- Write behavior:
    --  write in using link clock to URAM (and potentially BRAMS) 
    --      LEVEL1_RAMS_PER_LINK x dual port RAMs per link
    --      72b x 4096    
    --      to keep up with potential for object to be in multiple small-regions
    --  round-robin to the RAMs (with a chance for writing to 1,2,4 at a time)
    --  each RAM is segmented into ALGO_INPUT_SMALL_REGION_ETA_SIZE x ALGO_INPUT_SMALL_REGION_PHI_SIZE
    --      small-regions.
    --
    -- 
    -- =====
    -- Read behavior:
    --      Time multiplexing readout of small-regions. One object from each
    --          of the multiple rams is readout simultaneously organized by small-region.
    
    
    -- ==========================================================================================
    gen_level1_we_process : if TRUE generate
    
        signal base_we_index                : integer range 0 to MULTIRAM_COUNT-1 := 0;
        signal eta                          : signed(9 downto 0);
        signal phi                          : signed(9 downto 0);
        
        
        --for debugging
        signal debug_num_of_locations       : integer range 0 to 4 := 0;
         
    begin
    
        eta <= link_object_in.eta;
        phi <= link_object_in.phi;
        
        -- each clock determine which 1, 2, or 4 RAMs
        --  to write, and which small-region segment to write
        --  within the ram. 
        --  Note: always have 4 potential RAMs to which to write
        --      depending on overlap
    
        process(clk_link_to_level1)
        begin
            if (rising_edge(clk_link_to_level1)) then
                            
                link_object_in_latch(63)                        <= link_object_in.quality;
                link_object_in_latch(62)                        <= link_big_region_end; -- '0'; --FIXME hijacked a bit
                link_object_in_latch(52)                        <= link_object_in.lsEM;
                link_object_in_latch(61 downto 52)              <= std_logic_vector(link_object_in.z0);
                link_object_in_latch(51 downto 42)              <= std_logic_vector(link_object_in.phi);
                link_object_in_latch(41 downto 32)              <= std_logic_vector(link_object_in.eta);
                link_object_in_latch(31 downto 16)              <= std_logic_vector(link_object_in.otherPt);
                link_object_in_latch(15 downto 0)               <= std_logic_vector(link_object_in.pt);
                
                if (reset = '1') then
                
                    level1_ram_din_we <= (others => '0');
                    base_we_index <= 0;
                    
                    debug_num_of_locations <= 0;
                    
                elsif (link_object_we_in = '1') then
                                    
                    if(is_eta_small_region_overlap(eta) = '1' and
                        is_phi_small_region_overlap(phi) = '1') then
                        
                        -- then 4 locations
                        debug_num_of_locations <= 4;
                                  
                        -- set write enables                                                
                        for i in 0 to 3 loop
                            
                            if (base_we_index >= MULTIRAM_COUNT - i) then
                                level1_ram_din_we(
                                    base_we_index - (MULTIRAM_COUNT - i)) <= '1';
                                                                        
                                din_eta_phi_small_region(
                                    base_we_index - (MULTIRAM_COUNT - i)) <= 
                                        get_eta_phi_small_region(eta,phi,i);
                            else                                                    
                                level1_ram_din_we(
                                    base_we_index + i) <= '1';     
                                                      
                                din_eta_phi_small_region(
                                    base_we_index + i) <= get_eta_phi_small_region(eta,phi,i); 
                            end if;
                        end loop;
                    
                        -- increment base write index
                        if(base_we_index >= MULTIRAM_COUNT-4) then
                            base_we_index <= base_we_index - (MULTIRAM_COUNT - 4);
                        else 
                            base_we_index <= base_we_index + 4;
                        end if;
                        
                    elsif(is_eta_small_region_overlap(eta) = '1' or
                        is_phi_small_region_overlap(phi) = '1') then
                        
                        -- then 2 locations
                        debug_num_of_locations <= 2;
                    
                        -- set write enables                                                
                        for i in 0 to 1 loop
                            if (base_we_index >= MULTIRAM_COUNT - i) then
                                level1_ram_din_we(
                                    base_we_index - (MULTIRAM_COUNT - i)) <= '1';
                                 
                                din_eta_phi_small_region(
                                    base_we_index - (MULTIRAM_COUNT - i)) <= 
                                        get_eta_phi_small_region(eta,phi,i);
                            else                                                    
                                level1_ram_din_we(
                                    base_we_index + i) <= '1'; 
                                
                                din_eta_phi_small_region(
                                    base_we_index + i) <= get_eta_phi_small_region(eta,phi,i);
                            end if;
                        end loop;
                    
                        -- increment base write index
                        if(base_we_index >= MULTIRAM_COUNT-2) then
                            base_we_index <= base_we_index - (MULTIRAM_COUNT - 2);
                        else 
                            base_we_index <= base_we_index + 2;
                        end if;
                        
                    else 
                    
                        -- then 1 locations
                        debug_num_of_locations <= 1;  
                    
                        -- set write enables                                                
                        level1_ram_din_we(
                                    base_we_index) <= '1'; 
                        din_eta_phi_small_region(
                                    base_we_index) <= get_eta_phi_small_region(eta,phi,0);
                    
                        -- increment base write index
                        if(base_we_index >= MULTIRAM_COUNT-1) then
                            base_we_index <= base_we_index - (MULTIRAM_COUNT - 1);
                        else 
                            base_we_index <= base_we_index + 1;
                        end if;
                        
                    end if;
                    
                end if; --end reset
                
            
            end if; --end rising edge if        
        end process;
        
    end generate gen_level1_we_process;
    
    
    -- ==========================================================================================
    gen_uram_buffers : for i in 0 to MULTIRAM_COUNT-1 generate
        signal overflow_error_arr       : std_logic_vector(MULTIRAM_COUNT-1 downto 0);
    begin
    
        -- ========================================
        overflow_error_process : process(clk_link_to_level1)
        begin
        
            if (rising_edge(clk_link_to_level1)) then
                overflow_error <= or_reduce(overflow_error_arr);
            end if;
            
        end process overflow_error_process;
        
        -- ========================================
        uram_buffer : level1_uram_buffer    
           port map (
            clk_link_to_level1      => clk_link_to_level1,          --: in std_logic;
            
            link_big_region_end     => link_big_region_end,         --: in std_logic;
            
            link_object_in          => link_object_in,              --: in physics_object_t;
            link_object_we_in       => link_object_we_in,           --: in std_logic;
            wobject_eta_phi_index   => din_eta_phi_small_region(i), --: in get_eta_phi_small_region_t;
            
            level2_re_in            => level2_re_in,                --: in std_logic;
            robject_eta_phi_index   => level2_eta_phi_rindex,       --: in get_eta_phi_small_region_t;
            robject_valid           => objects_out_valid(i),        --: out std_logic;
            robject_dout            => objects_out(i),              --: out raw_phyiscs_object_t;
            
            overflow_error          => overflow_error_arr(i),       --: out std_logic;
            reset                   => reset                        --: in std_logic
           );
    
    end generate gen_uram_buffers;
          
end Behavioral;
