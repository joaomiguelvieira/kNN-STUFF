library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity cascade_comparator_unit is
    port
    (
        clk, rst: in std_logic;
        frc_ld, seq, prv_evl: in std_logic;
        prv_nmr, new_nmr: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        val_out: out std_logic;
        cur_evl_out: out std_logic;
        cur_nmr_out: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        -- info about the index
        prv_idx, new_idx: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        cur_idx_out: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end cascade_comparator_unit;

architecture Behavioral of cascade_comparator_unit is

signal mux_sel: std_logic;
signal w_en: std_logic;

signal mux_val: std_logic_vector(DATA_WIDTH - 1 downto 0);
signal cur_evl: std_logic;

signal w_ctrl: std_logic_vector(3 downto 0);

signal cur_nmr: std_logic_vector(DATA_WIDTH - 1 downto 0);

-- info about the index
signal mux_idx: std_logic_vector(DATA_WIDTH - 1 downto 0);
signal cur_idx: std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

-- data control: 0 for previous; 1 for new. FSPC
mux_sel <=  '0' when w_ctrl = "0000" else   -- both previous and current are less
            '1' when w_ctrl = "0001" else   -- the current is greater
            '0' when w_ctrl = "0010" else   -- just the previous is greater (impossible)
            '0' when w_ctrl = "0011" else   -- both previous and current are greater
            '0' when w_ctrl = "0100" else   -- sequence
            '0' when w_ctrl = "0101" else
            '0' when w_ctrl = "0110" else
            '0' when w_ctrl = "0111" else
            '1' when w_ctrl = "1000" else   -- force load and the previous was less
            '1' when w_ctrl = "1001" else
            '0' when w_ctrl = "1010" else   -- force load and the previous was greater
            '0' when w_ctrl = "1011" else
            '0' when w_ctrl = "1100" else   -- force load and sequence at once has no meaning
            '0' when w_ctrl = "1101" else
            '0' when w_ctrl = "1110" else       
            '0';

-- write control: FSPC
w_en <= '0' when w_ctrl = "0000" else   -- none are greater, thus keep the value
        '1' when w_ctrl = "0001" else   -- the current is greater, thus write and load
        '0' when w_ctrl = "0010" else   -- the previous is greater but the current is not (impossible)
        '1' when w_ctrl = "0011" else   -- both previous and current are greater, thus write
        '1' when w_ctrl = "0100" else   -- sequence
        '1' when w_ctrl = "0101" else
        '1' when w_ctrl = "0110" else
        '1' when w_ctrl = "0111" else
        '1' when w_ctrl = "1000" else   -- force load
        '1' when w_ctrl = "1001" else
        '1' when w_ctrl = "1010" else
        '1' when w_ctrl = "1011" else
        '0' when w_ctrl = "1100" else   -- force load and sequence at once has no meaning
        '0' when w_ctrl = "1101" else
        '0' when w_ctrl = "1110" else
        '0';
        
-- previous is selected by default or new otherwise
mux_val <= prv_nmr when mux_sel = '0' else new_nmr;
mux_idx <= prv_idx when mux_sel = '0' else new_idx;

-- evaluates whether the current number is greater than the new one
cur_evl <= '1' when new_nmr < cur_nmr else '0';

-- just an auxiliar signal that joins the controls
w_ctrl <= frc_ld & seq & prv_evl & cur_evl;

process(clk, rst)
begin
    if clk'event and clk = '1' then
        if rst = '1' then
            cur_nmr <= (others => '0');
            cur_idx <= (others => '0');
        elsif w_en = '1' then
            cur_nmr <= mux_val;
            cur_idx <= mux_idx;
        end if;
    end if;
end process;

cur_evl_out <= cur_evl;

cur_nmr_out <= cur_nmr;
cur_idx_out <= cur_idx;

end Behavioral;
