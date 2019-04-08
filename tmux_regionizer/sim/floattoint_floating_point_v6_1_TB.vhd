library ieee;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity floattoint_floating_point_v6_1_tb is
end floattoint_floating_point_v6_1_tb;

architecture TB_ARCHITECTURE of floattoint_floating_point_v6_1_tb is
	-- Component declaration of the tested unit
	component floattoint_floating_point_v6_1
	port(
		aclk : in STD_LOGIC;
		s_axis_a_tvalid : in STD_LOGIC;
		s_axis_a_tready : out STD_LOGIC;
		s_axis_a_tdata : in STD_LOGIC_VECTOR(15 downto 0);
		m_axis_result_tvalid : out STD_LOGIC;
		m_axis_result_tready : in STD_LOGIC;
		m_axis_result_tdata : out STD_LOGIC_VECTOR(15 downto 0) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal aclk : STD_LOGIC := '0';
	signal s_axis_a_tvalid : STD_LOGIC := '0';
	signal s_axis_a_tdata : STD_LOGIC_VECTOR(15 downto 0);
	signal m_axis_result_tready : STD_LOGIC := '0';
	-- Observed signals - signals mapped to the output ports of tested entity
	signal s_axis_a_tready : STD_LOGIC;
	signal m_axis_result_tvalid : STD_LOGIC;
	signal m_axis_result_tdata : STD_LOGIC_VECTOR(15 downto 0);

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : floattoint_floating_point_v6_1
		port map (
			aclk => aclk,
			s_axis_a_tvalid => s_axis_a_tvalid,
			s_axis_a_tready => s_axis_a_tready,
			s_axis_a_tdata => s_axis_a_tdata,
			m_axis_result_tvalid => m_axis_result_tvalid,
			m_axis_result_tready => m_axis_result_tready,
			m_axis_result_tdata => m_axis_result_tdata
		);

	-- Add your stimulus here ...
	aclk <= not aclk after 2.083ns;	
   
	s_axis_a_tvalid <= '1' after 9 ns;
	--s_axis_a_tready : out STD_LOGIC;
	-- s_axis_a_tdata <= "0011111100000000"; -- 1.5
	s_axis_a_tdata <= "0011111011001100"; -- 1.4
	--s_axis_a_tdata <= "1111111111111111";
	--m_axis_result_tvalid : out STD_LOGIC;
	m_axis_result_tready <= '1' after 9 ns;
	--m_axis_result_tdata : out STD_LOGIC_VECTOR(15 downto 0);
	--m_axis_result_tuser : out STD_LOGIC_VECTOR(1 downto 0) );
	
	
end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_floattoint_floating_point_v6_1 of floattoint_floating_point_v6_1_tb is
	for TB_ARCHITECTURE
		for UUT : floattoint_floating_point_v6_1
			use entity work.floattoint_floating_point_v6_1(floattoint_floating_point_v6_1_a);
		end for;
	end for;
end TESTBENCH_FOR_floattoint_floating_point_v6_1;

