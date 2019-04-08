library s1calol2algo;
use s1calol2algo.algorithm_constants.all;
library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity mergesortblock_tb is
end mergesortblock_tb;

architecture TB_ARCHITECTURE of mergesortblock_tb is
	-- Component declaration of the tested unit
	component mergesortblock
	port(
		reset                 : in STD_LOGIC;
		slow_clk              : in STD_LOGIC; 
		clk_enable            : in STD_LOGIC;
		pileupsubtractor_done : in STD_LOGIC;
		data_out              : in STD_LOGIC_VECTOR(PHI_SLICES*CENTRAL_ETA_SLICES*ENERGY_BITS-1 downto 0);
		hfm_energy_matrix_in  : in STD_LOGIC_VECTOR(PHI_SLICES*HFM_ETA_SLICES*ENERGY_BITS-1 downto 0);
		hfp_energy_matrix_in  : in STD_LOGIC_VECTOR(PHI_SLICES*HFP_ETA_SLICES*ENERGY_BITS-1 downto 0);
		--for simulation testing				   	
		--test_presort : out STD_LOGIC_VECTOR(PRESORT_DEPTH*(ENERGY_BITS+POSITION_BITS)-1 downto 0);
		--energies_matrix           : out energies_matrix_t(PHI_SLICES-1 downto 0, CENTRAL_ETA_SLICES-1 downto 0);
		--presorted_energies_matrix : out energy_positions_matrix_t(N_PRESORTED_ROWS_CENTRAL-1 downto 0, PRESORT_DEPTH-1 downto 0);
		--row_presorted_energies_matrix : out energy_positions_matrix_t(N_PRESORTED_ROWS_CENTRAL-1 downto 0, PRESORT_DEPTH-1 downto 0);
		--sorted_eta_slices_energies_matrix : out energy_positions_matrix_t(CENTRAL_ETA_SLICES -1 downto 0, N_KEEP_CENTRAL -1 downto 0);
		--row_presorted_eta_slices_energies_matrix : out energy_positions_matrix_t(CENTRAL_ETA_SLICES + (CENTRAL_ETA_SLICES mod N_ETA_GROUPS_CENTRAL) -1 downto 0, N_KEEP_CENTRAL -1 downto 0);
		--sorted_eta_groups_energies_matrix : out energy_positions_matrix_t(N_ETA_GROUP_SIZE_CENTRAL-1 downto 0, N_KEEP_CENTRAL -1 downto 0);
   		--end for simulation testing			   	
		sort_done           : out STD_LOGIC;
		sorted_central_jets : out energy_positions_array_t(N_KEEP_CENTRAL-1 downto 0);	 
		sorted_forward_jets : out energy_positions_array_t(N_KEEP_FORWARD-1 downto 0)
		);
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal reset : STD_LOGIC;
	signal data_clk : STD_LOGIC := '0';	
	signal clk_enable : STD_LOGIC := '0';
	signal pileupsubtractor_done : STD_LOGIC;
	signal data_out : STD_LOGIC_VECTOR(PHI_SLICES*CENTRAL_ETA_SLICES*ENERGY_BITS-1 downto 0);
	signal hfm_energy_matrix_in : STD_LOGIC_VECTOR(PHI_SLICES*HFM_ETA_SLICES*ENERGY_BITS-1 downto 0);
	signal hfp_energy_matrix_in : STD_LOGIC_VECTOR(PHI_SLICES*HFP_ETA_SLICES*ENERGY_BITS-1 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	--for simulation testing				   	
	--signal test_presort : STD_LOGIC_VECTOR(PRESORT_DEPTH*(ENERGY_BITS+POSITION_BITS)-1 downto 0);
	--signal energies_matrix           : energies_matrix_t(PHI_SLICES-1 downto 0, CENTRAL_ETA_SLICES-1 downto 0);
	--signal presorted_energies_matrix : energy_positions_matrix_t(N_PRESORTED_ROWS_CENTRAL-1 downto 0, PRESORT_DEPTH-1 downto 0);
	--signal row_presorted_energies_matrix : energy_positions_matrix_t(N_PRESORTED_ROWS_CENTRAL-1 downto 0, PRESORT_DEPTH-1 downto 0);
	--signal sorted_eta_slices_energies_matrix : energy_positions_matrix_t(CENTRAL_ETA_SLICES -1 downto 0, N_KEEP_CENTRAL -1 downto 0);
	--signal sorted_eta_groups_energies_matrix : energy_positions_matrix_t(N_ETA_GROUP_SIZE_CENTRAL-1 downto 0, N_KEEP_CENTRAL -1 downto 0);
    --signal row_presorted_eta_slices_energies_matrix : energy_positions_matrix_t(CENTRAL_ETA_SLICES + (CENTRAL_ETA_SLICES mod N_ETA_GROUPS_CENTRAL) -1 downto 0, N_KEEP_CENTRAL -1 downto 0); 
    --end for simulation testing			   	
	signal sort_done : STD_LOGIC;
	signal sorted_central_jets : energy_positions_array_t(N_KEEP_CENTRAL-1 downto 0);
	signal sorted_forward_jets : energy_positions_array_t(N_KEEP_FORWARD-1 downto 0);
	
	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : mergesortblock
		port map (
			reset => reset,
			slow_clk => data_clk, 
			clk_enable => clk_enable,
			pileupsubtractor_done => pileupsubtractor_done,
			data_out => data_out,
			hfm_energy_matrix_in => hfm_energy_matrix_in,
			hfp_energy_matrix_in => hfp_energy_matrix_in,
			--for simulation testing				   	
			--test_presort => test_presort,
			--energies_matrix => energies_matrix,
			--presorted_energies_matrix => presorted_energies_matrix,
			--row_presorted_energies_matrix => row_presorted_energies_matrix,
			--sorted_eta_slices_energies_matrix => sorted_eta_slices_energies_matrix,
			--sorted_eta_groups_energies_matrix => sorted_eta_groups_energies_matrix,
			--row_presorted_eta_slices_energies_matrix => row_presorted_eta_slices_energies_matrix,
		    --end for simulation testing			   	
			sort_done => sort_done,
			sorted_central_jets => sorted_central_jets,
			sorted_forward_jets => sorted_forward_jets
		);

	-- Add your stimulus here ...
	data_clk <= not data_clk after 2.083ns;	 
	clk_enable <= '1'; -- need to change this to simulate half frequency
    reset <= '0', '1' after 10 ns, '0' after 19.4 ns;
	pileupsubtractor_done <= '0', '1' after 25 ns, '0' after 30 ns;
	--data_out(PHI_SLICES*CENTRAL_ETA_SLICES*ENERGY_BITS-1 downto 0) <= (others =>'0');
	
	data_out(PHI_SLICES*CENTRAL_ETA_SLICES*ENERGY_BITS-1 downto PHI_SLICES*1*ENERGY_BITS) <= (others =>'0');
	data_out(PHI_SLICES*1*ENERGY_BITS-1 downto 0) <= (others =>'1');
	
	--data_out(PHI_SLICES*CENTRAL_ETA_SLICES*ENERGY_BITS-1 downto 1*CENTRAL_ETA_SLICES*ENERGY_BITS) <= (others =>'0');
	--data_out(1*CENTRAL_ETA_SLICES*ENERGY_BITS-1 downto 0) <= (others =>'1');
	
	
end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_mergesortblock of mergesortblock_tb is
	for TB_ARCHITECTURE
		for UUT : mergesortblock
			use entity work.mergesortblock(mergesortblock);
		end for;
	end for;
end TESTBENCH_FOR_mergesortblock;

