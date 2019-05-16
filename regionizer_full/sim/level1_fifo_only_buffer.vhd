----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2019 11:23:13 AM
-- Design Name: 
-- Module Name: level1_fifo_only_buffer - Behavioral
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

use work.regionizer_pkg.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity level1_fifo_only_buffer is
    generic (
        SOURCE_FIBER_INDEX      : natural := INVALID_SOURCE_FIBER
    );
    port ( 
        clk_link_to_level1      : in  std_logic;
        clk_level1_to_2         : in  std_logic; 
        
        link_big_region_end     : in  std_logic;
        
        link_object_we_in       : in  std_logic;
        link_object_in          : in  physics_object_t;
        level1_big_region_end   : out std_logic;
        
        level2_big_region_end   : in  std_logic;
        small_region_closed     : in  std_logic_vector(SMALL_REGION_COUNT-1 downto 0);
        level2_pipe_in          : in  level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
        level2_pipe_out         : out level1_to_2_pipe_arr_t(LEVEL1_TO_2_PIPE_COUNT-1 downto 0);
                
        overflow_error          : out std_logic;
        level2_reset            : in  std_logic;
        reset                   : in  std_logic
    );
end level1_fifo_only_buffer;

architecture Behavioral of level1_fifo_only_buffer is

    constant    LAYER_BRAM_ADDR_SIZE        : natural := 10; --bits
     
    component level1_fifo
        port (
            --dual clock
--            rst : in STD_LOGIC;
--            wr_clk : in STD_LOGIC;
--            rd_clk : in STD_LOGIC;
--            din : in STD_LOGIC_VECTOR ( PHYSICS_OBJECT_BIT_SIZE-1 downto 0 );
--            wr_en : in STD_LOGIC;
--            rd_en : in STD_LOGIC;
--            dout : out STD_LOGIC_VECTOR ( PHYSICS_OBJECT_BIT_SIZE-1 downto 0 );
--            full : out STD_LOGIC;
--            empty : out STD_LOGIC;
--            wr_rst_busy : out STD_LOGIC;
--            rd_rst_busy : out STD_LOGIC
            
            --one clock
            clk : in STD_LOGIC;
            srst : in STD_LOGIC;
            din : in STD_LOGIC_VECTOR ( 63 downto 0 );
            wr_en : in STD_LOGIC;
            rd_en : in STD_LOGIC;
            dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
            full : out STD_LOGIC;
            almost_full : out STD_LOGIC;
            empty : out STD_LOGIC;
            wr_rst_busy : out STD_LOGIC;
            rd_rst_busy : out STD_LOGIC
            );
    end component level1_fifo;
    
    
    signal read_overflow_error      : std_logic := '0';
    signal write_overflow_error     : std_logic := '0';
begin

    overflow_error <= read_overflow_error or write_overflow_error;
    
    --  This is a Level-1 FIFO-only buffer to hold objects from links before 
    --      sending to Level-2.
    --
    --
    -- =====
    -- Write behavior:
    --  Each link clock an object could arrive from link into
    --      one dual port fifo for initial buffer
    --      64b x 512    
    --  
    --  For each big-region keep a count of objects (need two counters),
    --      so that objects can be flushed when Level-2 indicates
    --      switch to next big-region.    
    --    
    -- 
    -- =====
    -- Read behavior:  
    --  Each Level-2 transfer clock, place object by small region into available
    --      opening in Level-2 shift register pipeline.
    --      e.g. PARALLEL_OBJECT_RAMS = 5, SMALL_REGIONS_PER_RAM = 3, SMALL_REGION_COUNT = 18
    --          then there are 18/3=6 Level-2 pipes. Each object out of the FIFO
    --          will map to one of the pipes; sit and wait until pipe opening, place, and
    --          read next from FIFO. 
    -- 
    
    
   
    
           
    -- ==========================================================================================
    gen_level1_handling : if TRUE generate 
      
        signal level1_din               : raw_physics_object_t;  
        signal level1_dout              : raw_physics_object_t;
        
        signal level1_w_en              : std_logic := '0';
        
        signal level1_r_en              : std_logic := '0';
        signal level1_empty             : std_logic;
        signal level1_full              : std_logic;
        signal level1_rd_object         : physics_object_t := null_physics_object;
        
        signal level1_has_event_data    : std_logic_vector(1 downto 0) := (others => '0'); --indicate data has been received for big-event
        
        
        signal level1_rd_big_region_end : std_logic;
        
        
    begin     
    
        level1_din(63)                        <= link_object_in.quality;
        level1_din(62)                        <= link_big_region_end; -- '0'; --FIXME(?) hijacked a bit
        --level1_din(52)                        <= link_object_in.lsEM;
        level1_din(61 downto 52)              <= std_logic_vector(link_object_in.z0);
        level1_din(51 downto 42)              <= std_logic_vector(link_object_in.phi);
        level1_din(41 downto 32)              <= std_logic_vector(link_object_in.eta);
        level1_din(31 downto 16)              <= std_logic_vector(link_object_in.otherPt);
        level1_din(15 downto 0)               <= std_logic_vector(link_object_in.pt);
       
        --insert end of big-event marker if occurs without we
        level1_w_en                           <= link_object_we_in or link_big_region_end;
       
        -- ==========================================================================================
        gen_level1_write_handling : if TRUE generate        
            signal debug_overflow_write_count : unsigned(15 downto 0) := (others => '0');
        begin
            write_process : process(clk_link_to_level1)
            begin
            
                if (rising_edge(clk_link_to_level1)) then
                                                                    
                                                        
                    if (reset = '1') then
                    
                        write_overflow_error        <= '0';
                        debug_overflow_write_count  <= (others => '0');
                        
                    elsif (level1_w_en = '1' and level1_full = '1') then -- else check for overflow
                    
                        write_overflow_error        <= '1';
                        debug_overflow_write_count  <= debug_overflow_write_count + 1;
                    
                    end if; --end primary reset if
                    
                end if; --rising edge if
            end process write_process;
        end generate gen_level1_write_handling;
        
        
        -- ==========================================================================================
        -- Level-1 buffer FIFO
        level1_fifo_inst: level1_fifo
            port map (
                -- dual clock interface
--                rst                             => reset,               --: in STD_LOGIC
--                wr_clk                          => clk_link_to_level1,  --: in STD_LOGIC
--                rd_clk                          => clk_level1_to_2,     --: in STD_LOGIC
                
--                din                             => level1_din,          --: in STD_LOGIC_VECTOR ( 63 downto 0 )
                
--                wr_en                           => level1_w_en,         --: in STD_LOGIC
--                rd_en                           => level1_r_en,         --: in STD_LOGIC 
                               
--                dout                            => level1_dout,         --: out STD_LOGIC_VECTOR ( 63 downto 0 )
                           
--                full                            => level1_full,         --: out STD_LOGIC
--                almost_full                     => open,                --: out STD_LOGIC
--                empty                           => level1_empty,        --: out STD_LOGIC
--                wr_rst_busy                     => open,                --: out STD_LOGIC
--                rd_rst_busy                     => open                 --: out STD_LOGIC
                
                -- one clock interface
                srst                            => reset,               --: in STD_LOGIC
                clk                             => clk_link_to_level1,  --: in STD_LOGIC
                                
                din                             => level1_din,          --: in STD_LOGIC_VECTOR ( 63 downto 0 )
                
                wr_en                           => level1_w_en,         --: in STD_LOGIC
                rd_en                           => level1_r_en,         --: in STD_LOGIC 
                               
                dout                            => level1_dout,         --: out STD_LOGIC_VECTOR ( 63 downto 0 )
                           
                full                            => level1_full,         --: out STD_LOGIC
                almost_full                     => open,
                empty                           => level1_empty,        --: out STD_LOGIC
                wr_rst_busy                     => open,                --: out STD_LOGIC
                rd_rst_busy                     => open                 --: out STD_LOGIC
                
            );    
        
        level1_rd_object.quality                <= level1_dout(63);
        
        level1_rd_big_region_end                <= level1_dout(62); --FIXME hijacked a bit!
        
        --level1_rd_object.lsEM                   <= level1_dout(52);    
        level1_rd_object.z0                     <= signed(level1_dout(61 downto 52));
        level1_rd_object.phi                    <= signed(level1_dout(51 downto 42));
        level1_rd_object.eta                    <= signed(level1_dout(41 downto 32));
        level1_rd_object.otherPt                <= signed(level1_dout(31 downto 16));
        level1_rd_object.pt                     <= signed(level1_dout(15 downto 0));
        
        level1_rd_object.source_fiber           <= SOURCE_FIBER_INDEX;


        -- ==========================================================================================
        gen_level1_read_handling : if TRUE generate
         
            signal robject_small_region     : get_eta_phi_small_region_t;
            signal sr_overlap_index         : integer range 0 to 3 := 0;
            
            signal empty_latch              : std_logic := '0';
            signal ready_to_handle          : std_logic; --delay by 1 clock handling of small region index
            signal ready_to_handle_latch    : std_logic := '0'; 
            signal level1_r_en_latch        : std_logic := '0'; --prevent next read for 1 clock after handling
            
            signal small_region_closed_latch: std_logic_vector(SMALL_REGION_COUNT-1 downto 0);
            
            signal done_with_big_region     : std_logic := '0';    
            signal need_to_drain            : std_logic := '0';  
            
            signal link_big_region_end_latch: std_logic;
            
            constant BX_COUNT_TO_DONE       : integer := 0;
            constant BX_SUBCOUNT_TO_DONE    : integer := 15;
            signal level1_fixed_end         : std_logic := '0';
            
            signal level2_next_latch        : std_logic := '0';
            signal level2_next_strobe       : std_logic := '0';
            
            -- for debugging
            signal debug_source_event_index : integer := 0; 
            signal debug_target_pipe_closed : std_logic;
            signal debug_target_pipe_entry  : std_logic;
            signal debug_target_pipe_drop   : std_logic;
            signal debug_roverflow_error_count : unsigned(15 downto 0) := (others => '0');
            
            
            constant LVL2_CLOCKS_PER_2BX    : integer := 15; --for 300MHz, 15 clocks in 2x 40MHz 
                       
            signal debug_bx_subcount        : unsigned(5 downto 0) := (others => '0'); 
            signal debug_bx_count           : unsigned(5 downto 0) := (others => '0');
            
        begin
                
            --=============
            --  check to see if big-regions finishing on time
            handle_fixed_end_process : process(clk_level1_to_2)
            begin
                if(rising_edge(clk_level1_to_2)) then
                 
                    --handle fixed end
                    if(level2_big_region_end = '1') then
                    
                        level1_fixed_end    <= '0';   
                        
                    elsif(debug_bx_count = BX_COUNT_TO_DONE and 
                        debug_bx_subcount = BX_SUBCOUNT_TO_DONE) then
                        
                        level1_fixed_end    <= '1';
                        
                    end if;
                     
                     
                    -- handle bx counting from link end
                    if (reset = '1') then
                    
                        debug_bx_subcount   <= (others => '1');
                        debug_bx_count      <= (others => '1');
                        level1_fixed_end    <= '0';
                        
                    elsif (link_big_region_end_latch = '1') then
                    
                        debug_bx_subcount   <= (others => '0');
                        debug_bx_count      <= (others => '0');
                    end if; 
                    
                    if(debug_bx_count < 19) then
                        if(debug_bx_subcount < LVL2_CLOCKS_PER_2BX) then
                            debug_bx_subcount <= debug_bx_subcount + 1;
                        else                        
                            debug_bx_subcount <= (others => '0');
                            
                            if(debug_bx_count < 30) then --18) then
                                debug_bx_count <= debug_bx_count + 2;
                            end if;                            
                        end if;
                                                    
                    end if;
                
                end if;            
            end process handle_fixed_end_process;
            
            
            ready_to_handle         <= (not level1_r_en) and (not empty_latch) and 
                (not level1_empty) and (not level1_r_en_latch) and (not ready_to_handle_latch);
            
            level1_big_region_end   <= level1_fixed_end;--done_with_big_region;
            
            level2_next_strobe      <= level2_big_region_end and (not level2_next_latch); --force to 1-clock strobe
            
            -- ============
            read_process : process(clk_level1_to_2)
                variable target_pipe_index      : integer range 0 to LEVEL1_TO_2_PIPE_COUNT-1 := 0;
                variable target_pipe_subindex   : integer range 0 to LEVEL2_SMALL_REGIONS_PER_RAM-1 := 0;
                variable target_pipe_closed     : std_logic;
            begin
            
                if (rising_edge(clk_level1_to_2)) then
                
                    link_big_region_end_latch       <= link_big_region_end;
                    level2_next_latch               <= level2_big_region_end;
                
                    empty_latch                     <= level1_empty;
                    level1_r_en                     <= '0';
                    level1_r_en_latch               <= level1_r_en;
                    ready_to_handle_latch           <= ready_to_handle;
                    
                    small_region_closed_latch       <= small_region_closed;
                    
                    robject_small_region            <= get_eta_phi_small_region(
                                                        level1_rd_object.eta,
                                                        level1_rd_object.phi,
                                                        sr_overlap_index
                                                        );
                                                        
                    target_pipe_index               := robject_small_region.small_region.phi_index;
                    target_pipe_subindex            := robject_small_region.small_region.eta_index; 
                    target_pipe_closed              := small_region_closed_latch(target_pipe_index*2 + target_pipe_subindex);
                    
                    debug_target_pipe_closed        <= target_pipe_closed;  --added to monitor pipe closed rejection in simulation
                    debug_target_pipe_entry         <= '0';                 --added to monitor pipe entry in simulation
                    debug_target_pipe_drop          <= '0';                 --added to monitor object drop in simulation
                    
                    --always pass pipe-in to pipe-out unless override below
                    level2_pipe_out                 <= level2_pipe_in;                                                        
                                                        
                    if (level2_reset = '1') then
                    
                        sr_overlap_index            <= 0;
                        done_with_big_region        <= '0';
                        read_overflow_error         <= '0';                        
                        
                        debug_source_event_index    <= 0;
                        debug_roverflow_error_count <= (others => '0');
                        
                    else -- else not reset
                    
                        if (ready_to_handle = '1' and done_with_big_region = '0') then
                        
                            if ((level1_rd_object.pt = 0 or target_pipe_closed = '1') and  --end of big-region without valid data
                                level1_rd_big_region_end = '1') then
                                
                                --done until next big-region reading
                                done_with_big_region <= '1';
                                
                                --pop end-of-big-region marker from FIFO
                                level1_r_en         <= '1';
                                
                            elsif(target_pipe_closed = '1') then 
                                
                                --have valid data for a closed small-region, so skip
                                --  AND do NOT wait for opening in pipe
                                
                                if (robject_small_region.is_another = '0') then
                                    --ready to pop object
                                    level1_r_en                 <= '1';
                                    sr_overlap_index            <= 0; --reset for next robject
                                    debug_target_pipe_drop      <= '1';
                                    
                                    --check if also end of big-region
                                    if (level1_rd_big_region_end = '1') then
                                        --done until next big-region reading
                                        done_with_big_region    <= '1';
                                    end if;
                                else
                                    sr_overlap_index            <= sr_overlap_index + 1;
                                end if;                                    
                                
                            elsif(level2_pipe_in(target_pipe_index).valid = '0') then
                            
                                --have valid data and opening in pipe
                                
                                debug_target_pipe_entry                             <= '1';
                                level2_pipe_out(target_pipe_index).valid            <= '1';
                                level2_pipe_out(target_pipe_index).object           <= level1_rd_object;
                                level2_pipe_out(target_pipe_index).object.source_event_index <= debug_source_event_index;
                                level2_pipe_out(target_pipe_index).object.small_region       <= robject_small_region.small_region;
                                level2_pipe_out(target_pipe_index).sr_ram_subindex  <= target_pipe_subindex;
                                
                                if (robject_small_region.is_another = '0') then
                                    --ready to pop object
                                    level1_r_en         <= '1';
                                    sr_overlap_index    <= 0; --reset for next robject
                                    
                                    --check if also end of big-region
                                    if (level1_rd_big_region_end = '1') then
                                        --done until next big-region reading
                                        done_with_big_region <= '1';
                                    end if;
                                    
                                else
                                    sr_overlap_index    <= sr_overlap_index + 1;
                                end if;
                                
                            end if; -- end of valid data for pipe if
                            
                        end if; -- end of ready to handle if
                        
                        --check if Level-2 is done reading big-region from Level-1
                        if (level2_next_strobe = '1') then
                        
                            debug_source_event_index    <= debug_source_event_index + 1;   
                                                        
                            if (need_to_drain = '1') then                            
                                read_overflow_error         <= '1';
                                debug_roverflow_error_count <= debug_roverflow_error_count + 1;                                
                            end if;
                            
                            if (done_with_big_region = '1') then                        
                                done_with_big_region        <= '0'; --release done for next big-region                             
                            else --need to drain!
                                need_to_drain               <= '1';
                            end if;
                            
                        end if;
                        
                        
                        if (need_to_drain = '1') then 
                        
                            --drain indiscriminately until Level-1 end-of-big-region marker found in FIFO data
                            level1_r_en         <= '1';
                            
                            if  (level1_rd_big_region_end = '1') then
                                done_with_big_region        <= '0'; --release done for next big-region
                                need_to_drain               <= '0'; --drain complete
                            end if;
                            
                        end if;
                    
                    end if; -- primary reset end if
                    
                end if; --end rising edge if
            
            end process read_process;
        end generate gen_level1_read_handling;
        

    end generate gen_level1_handling;
    
          
end Behavioral;
