library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity cascade_comparator_tb is
    generic
    (
        N: integer:= 32;
        M: integer:= 5
    );
end cascade_comparator_tb;

architecture Behavioral of cascade_comparator_tb is

component cascade_comparator is
    generic
    (
        M: integer := 32;
        N: integer := 32
    );
    port
    (
        -- input signals
        clk       : in  std_logic;
        rst       : in  std_logic;
        ready_in  : out std_logic;
        new_nmr   : in  std_logic_vector(N - 1 downto 0);
        last_in   : in  std_logic;
        val_in    : in  std_logic;
        
        -- output signals
        val_out   : out std_logic;
        out_nmr   : out std_logic_vector(N - 1 downto 0);
        last_out  : out std_logic;
        ready_out : in  std_logic
    );
end component;

signal clk: std_logic:= '0';
signal rst: std_logic:= '1';
signal ready_in: std_logic;
signal val_in: std_logic:= '0';
signal last_in: std_logic:= '0';
signal new_nmr: std_logic_vector(N - 1 downto 0);
signal val_out: std_logic;
signal out_nmr: std_logic_vector(N - 1 downto 0);
signal int_new_nmr: integer;
signal last_out: std_logic;
signal ready_out: std_logic:= '1';

constant clk_per: time:= 10 ns;

begin

uut: cascade_comparator
    generic map
    (
        N => N,
        M => M
    )
    port map
    (
        clk => clk, rst => rst, val_in => val_in,
        ready_in => ready_in,
        new_nmr => new_nmr,
        last_in => last_in,
        val_out => val_out,
        out_nmr => out_nmr,
        last_out => last_out,
        ready_out => ready_out
    );
    
clk_process: process
begin
    clk <= '0';
    wait for clk_per / 2;
    clk <= '1';
    wait for clk_per / 2;
end process;

sim_process: process
begin
    wait for clk_per;

    rst <= '0' after clk_per;
    int_new_nmr <=  -16 after clk_per,
                    2 after clk_per * 2,
                    1 after clk_per * 3,
                    4 after clk_per * 4,
                    3 after clk_per * 5,
                    6 after clk_per * 6,
                    5 after clk_per * 7,
                    7 after clk_per * 8,
                    8 after clk_per * 9,
                    9 after clk_per * 10,
                    10 after clk_per * 11,
                    11 after clk_per * 12,
                    12 after clk_per * 13,
                    13 after clk_per * 14,
                    14 after clk_per * 15,
                    15 after clk_per * 16,
                    30 after clk_per * 17,
                    20 after clk_per * 18,
                    31 after clk_per * 19,
                    32 after clk_per * 20,
                    21 after clk_per * 31,
                    22 after clk_per * 32,
                    23 after clk_per * 33,
                    24 after clk_per * 34,
                    25 after clk_per * 35,
                    26 after clk_per * 36,
                    27 after clk_per * 37,
                    28 after clk_per * 38,
                    29 after clk_per * 39,
                    17 after clk_per * 40,
                    17 after clk_per * 41,
                    19 after clk_per * 42;
    val_in <=   '1' after clk_per,
                '0' after clk_per * 21,
                '1' after clk_per * 31,
                '0' after clk_per * 43;
    last_in <= '1' after clk_per * 20,
               '0' after clk_per * 21,
               '1' after clk_per * 42;

    wait;
end process;

new_nmr <= conv_std_logic_vector(int_new_nmr, N);

end Behavioral;
