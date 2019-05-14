-- ==============================================================
-- RTL generated by Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC
-- Version: 2018.1
-- Copyright (C) 1986-2018 Xilinx, Inc. All Rights Reserved.
-- 
-- ===========================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dr2_int_cap_10_s is
port (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    eta1_V : IN STD_LOGIC_VECTOR (9 downto 0);
    phi1_V : IN STD_LOGIC_VECTOR (9 downto 0);
    eta2_V : IN STD_LOGIC_VECTOR (9 downto 0);
    phi2_V : IN STD_LOGIC_VECTOR (9 downto 0);
    ap_return : OUT STD_LOGIC_VECTOR (8 downto 0);
    ap_ce : IN STD_LOGIC );
end;


architecture behav of dr2_int_cap_10_s is 
    constant ap_const_logic_1 : STD_LOGIC := '1';
    constant ap_const_logic_0 : STD_LOGIC := '0';
    constant ap_const_boolean_1 : BOOLEAN := true;
    constant ap_const_boolean_0 : BOOLEAN := false;
    constant ap_const_lv11_0 : STD_LOGIC_VECTOR (10 downto 0) := "00000000000";
    constant ap_const_lv10_0 : STD_LOGIC_VECTOR (9 downto 0) := "0000000000";
    constant ap_const_lv32_5 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000101";
    constant ap_const_lv32_9 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000001001";
    constant ap_const_lv5_0 : STD_LOGIC_VECTOR (4 downto 0) := "00000";
    constant ap_const_lv11_106 : STD_LOGIC_VECTOR (10 downto 0) := "00100000110";
    constant ap_const_lv9_106 : STD_LOGIC_VECTOR (8 downto 0) := "100000110";

    signal deta_V_fu_80_p3 : STD_LOGIC_VECTOR (9 downto 0);
    signal deta_V_reg_189 : STD_LOGIC_VECTOR (9 downto 0);
    signal ap_block_state1_pp0_stage0_iter0 : BOOLEAN;
    signal ap_block_state2_pp0_stage0_iter1 : BOOLEAN;
    signal ap_block_state3_pp0_stage0_iter2 : BOOLEAN;
    signal ap_block_state4_pp0_stage0_iter3 : BOOLEAN;
    signal ap_block_pp0_stage0_11001 : BOOLEAN;
    signal dphi_V_fu_118_p3 : STD_LOGIC_VECTOR (9 downto 0);
    signal dphi_V_reg_196 : STD_LOGIC_VECTOR (9 downto 0);
    signal icmp_fu_140_p2 : STD_LOGIC_VECTOR (0 downto 0);
    signal icmp_reg_203 : STD_LOGIC_VECTOR (0 downto 0);
    signal deta2_V_fu_181_p2 : STD_LOGIC_VECTOR (9 downto 0);
    signal deta2_V_reg_208 : STD_LOGIC_VECTOR (9 downto 0);
    signal dphi2_V_fu_185_p2 : STD_LOGIC_VECTOR (9 downto 0);
    signal dphi2_V_reg_213 : STD_LOGIC_VECTOR (9 downto 0);
    signal tmp_21_fu_165_p2 : STD_LOGIC_VECTOR (0 downto 0);
    signal tmp_21_reg_218 : STD_LOGIC_VECTOR (0 downto 0);
    signal tmp_2050_fu_171_p1 : STD_LOGIC_VECTOR (8 downto 0);
    signal tmp_2050_reg_223 : STD_LOGIC_VECTOR (8 downto 0);
    signal ap_block_pp0_stage0 : BOOLEAN;
    signal lhs_V_fu_50_p1 : STD_LOGIC_VECTOR (10 downto 0);
    signal rhs_V_fu_54_p1 : STD_LOGIC_VECTOR (10 downto 0);
    signal r_V_fu_58_p2 : STD_LOGIC_VECTOR (10 downto 0);
    signal tmp_2047_fu_64_p1 : STD_LOGIC_VECTOR (9 downto 0);
    signal tmp_fu_68_p2 : STD_LOGIC_VECTOR (0 downto 0);
    signal tmp_s_fu_74_p2 : STD_LOGIC_VECTOR (9 downto 0);
    signal lhs_V_5_fu_88_p1 : STD_LOGIC_VECTOR (10 downto 0);
    signal rhs_V_5_fu_92_p1 : STD_LOGIC_VECTOR (10 downto 0);
    signal r_V_5_fu_96_p2 : STD_LOGIC_VECTOR (10 downto 0);
    signal tmp_2048_fu_102_p1 : STD_LOGIC_VECTOR (9 downto 0);
    signal tmp_17_fu_106_p2 : STD_LOGIC_VECTOR (0 downto 0);
    signal tmp_18_fu_112_p2 : STD_LOGIC_VECTOR (9 downto 0);
    signal tmp_19_fu_126_p2 : STD_LOGIC_VECTOR (9 downto 0);
    signal tmp_2049_fu_130_p4 : STD_LOGIC_VECTOR (4 downto 0);
    signal rhs_V_6_fu_149_p1 : STD_LOGIC_VECTOR (10 downto 0);
    signal lhs_V_6_fu_146_p1 : STD_LOGIC_VECTOR (10 downto 0);
    signal r_V_6_fu_152_p2 : STD_LOGIC_VECTOR (10 downto 0);
    signal val_assign_fu_158_p3 : STD_LOGIC_VECTOR (10 downto 0);
    signal agg_result_V_fu_175_p3 : STD_LOGIC_VECTOR (8 downto 0);
    signal ap_ce_reg : STD_LOGIC;
    signal eta1_V_int_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal phi1_V_int_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal eta2_V_int_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal phi2_V_int_reg : STD_LOGIC_VECTOR (9 downto 0);
    signal ap_return_int_reg : STD_LOGIC_VECTOR (8 downto 0);

    component mp7wrapped_pfalgog8j IS
    generic (
        ID : INTEGER;
        NUM_STAGE : INTEGER;
        din0_WIDTH : INTEGER;
        din1_WIDTH : INTEGER;
        dout_WIDTH : INTEGER );
    port (
        din0 : IN STD_LOGIC_VECTOR (9 downto 0);
        din1 : IN STD_LOGIC_VECTOR (9 downto 0);
        dout : OUT STD_LOGIC_VECTOR (9 downto 0) );
    end component;



begin
    mp7wrapped_pfalgog8j_U1205 : component mp7wrapped_pfalgog8j
    generic map (
        ID => 1,
        NUM_STAGE => 1,
        din0_WIDTH => 10,
        din1_WIDTH => 10,
        dout_WIDTH => 10)
    port map (
        din0 => deta_V_reg_189,
        din1 => deta_V_reg_189,
        dout => deta2_V_fu_181_p2);

    mp7wrapped_pfalgog8j_U1206 : component mp7wrapped_pfalgog8j
    generic map (
        ID => 1,
        NUM_STAGE => 1,
        din0_WIDTH => 10,
        din1_WIDTH => 10,
        dout_WIDTH => 10)
    port map (
        din0 => dphi_V_reg_196,
        din1 => dphi_V_reg_196,
        dout => dphi2_V_fu_185_p2);





    ap_ce_reg_assign_proc : process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            ap_ce_reg <= ap_ce;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((ap_const_logic_1 = ap_ce_reg)) then
                ap_return_int_reg <= agg_result_V_fu_175_p3;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if (((ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_const_logic_1 = ap_ce_reg))) then
                deta2_V_reg_208 <= deta2_V_fu_181_p2;
                deta_V_reg_189 <= deta_V_fu_80_p3;
                dphi2_V_reg_213 <= dphi2_V_fu_185_p2;
                dphi_V_reg_196 <= dphi_V_fu_118_p3;
                icmp_reg_203 <= icmp_fu_140_p2;
                tmp_2050_reg_223 <= tmp_2050_fu_171_p1;
                tmp_21_reg_218 <= tmp_21_fu_165_p2;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((ap_const_logic_1 = ap_ce)) then
                eta1_V_int_reg <= eta1_V;
                eta2_V_int_reg <= eta2_V;
                phi1_V_int_reg <= phi1_V;
                phi2_V_int_reg <= phi2_V;
            end if;
        end if;
    end process;
    agg_result_V_fu_175_p3 <= 
        tmp_2050_reg_223 when (tmp_21_reg_218(0) = '1') else 
        ap_const_lv9_106;
        ap_block_pp0_stage0 <= not((ap_const_boolean_1 = ap_const_boolean_1));
        ap_block_pp0_stage0_11001 <= not((ap_const_boolean_1 = ap_const_boolean_1));
        ap_block_state1_pp0_stage0_iter0 <= not((ap_const_boolean_1 = ap_const_boolean_1));
        ap_block_state2_pp0_stage0_iter1 <= not((ap_const_boolean_1 = ap_const_boolean_1));
        ap_block_state3_pp0_stage0_iter2 <= not((ap_const_boolean_1 = ap_const_boolean_1));
        ap_block_state4_pp0_stage0_iter3 <= not((ap_const_boolean_1 = ap_const_boolean_1));

    ap_return_assign_proc : process(agg_result_V_fu_175_p3, ap_ce_reg, ap_return_int_reg)
    begin
        if ((ap_const_logic_0 = ap_ce_reg)) then 
            ap_return <= ap_return_int_reg;
        elsif ((ap_const_logic_1 = ap_ce_reg)) then 
            ap_return <= agg_result_V_fu_175_p3;
        end if; 
    end process;

    deta_V_fu_80_p3 <= 
        tmp_2047_fu_64_p1 when (tmp_fu_68_p2(0) = '1') else 
        tmp_s_fu_74_p2;
    dphi_V_fu_118_p3 <= 
        tmp_2048_fu_102_p1 when (tmp_17_fu_106_p2(0) = '1') else 
        tmp_18_fu_112_p2;
    icmp_fu_140_p2 <= "1" when (tmp_2049_fu_130_p4 = ap_const_lv5_0) else "0";
        lhs_V_5_fu_88_p1 <= std_logic_vector(IEEE.numeric_std.resize(signed(phi1_V_int_reg),11));

    lhs_V_6_fu_146_p1 <= std_logic_vector(IEEE.numeric_std.resize(unsigned(deta2_V_reg_208),11));
        lhs_V_fu_50_p1 <= std_logic_vector(IEEE.numeric_std.resize(signed(eta1_V_int_reg),11));

    r_V_5_fu_96_p2 <= std_logic_vector(signed(lhs_V_5_fu_88_p1) - signed(rhs_V_5_fu_92_p1));
    r_V_6_fu_152_p2 <= std_logic_vector(unsigned(rhs_V_6_fu_149_p1) + unsigned(lhs_V_6_fu_146_p1));
    r_V_fu_58_p2 <= std_logic_vector(signed(lhs_V_fu_50_p1) - signed(rhs_V_fu_54_p1));
        rhs_V_5_fu_92_p1 <= std_logic_vector(IEEE.numeric_std.resize(signed(phi2_V_int_reg),11));

    rhs_V_6_fu_149_p1 <= std_logic_vector(IEEE.numeric_std.resize(unsigned(dphi2_V_reg_213),11));
        rhs_V_fu_54_p1 <= std_logic_vector(IEEE.numeric_std.resize(signed(eta2_V_int_reg),11));

    tmp_17_fu_106_p2 <= "1" when (signed(r_V_5_fu_96_p2) > signed(ap_const_lv11_0)) else "0";
    tmp_18_fu_112_p2 <= std_logic_vector(unsigned(ap_const_lv10_0) - unsigned(tmp_2048_fu_102_p1));
    tmp_19_fu_126_p2 <= (dphi_V_reg_196 or deta_V_reg_189);
    tmp_2047_fu_64_p1 <= r_V_fu_58_p2(10 - 1 downto 0);
    tmp_2048_fu_102_p1 <= r_V_5_fu_96_p2(10 - 1 downto 0);
    tmp_2049_fu_130_p4 <= tmp_19_fu_126_p2(9 downto 5);
    tmp_2050_fu_171_p1 <= val_assign_fu_158_p3(9 - 1 downto 0);
    tmp_21_fu_165_p2 <= "1" when (unsigned(val_assign_fu_158_p3) < unsigned(ap_const_lv11_106)) else "0";
    tmp_fu_68_p2 <= "1" when (signed(r_V_fu_58_p2) > signed(ap_const_lv11_0)) else "0";
    tmp_s_fu_74_p2 <= std_logic_vector(unsigned(ap_const_lv10_0) - unsigned(tmp_2047_fu_64_p1));
    val_assign_fu_158_p3 <= 
        r_V_6_fu_152_p2 when (icmp_reg_203(0) = '1') else 
        ap_const_lv11_106;
end behav;
