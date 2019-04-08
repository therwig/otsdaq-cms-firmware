library ieee;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity intint_multiplier_tb is
end intint_multiplier_tb;

architecture TB_ARCHITECTURE of intint_multiplier_tb is
	-- Component declaration of the tested unit
	component intint_multiplier
	port(
		clk : in STD_LOGIC;
		a : in STD_LOGIC_VECTOR(5 downto 0);
		b : in STD_LOGIC_VECTOR(9 downto 0);
		p : out STD_LOGIC_VECTOR(15 downto 0) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal a : STD_LOGIC_VECTOR(5 downto 0) := "000000";
	signal b : STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
	-- Observed signals - signals mapped to the output ports of tested entity
	signal p : STD_LOGIC_VECTOR(15 downto 0);

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : intint_multiplier
		port map (
			clk => clk,
			a => a,
			b => b,
			p => p
		);

	-- Add your stimulus here ...
   	clk <= not clk after 2.083ns;	
	a <= "000111" after 9.2 ns;
	b <= "1110000000" after 9.2 ns;
	
end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_intint_multiplier of intint_multiplier_tb is
	for TB_ARCHITECTURE
		for UUT : intint_multiplier
			use entity work.intint_multiplier(intint_multiplier_a);
		end for;
	end for;
end TESTBENCH_FOR_intint_multiplier;

