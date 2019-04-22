library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity cascade_comparator is
    port (
        -- input signals
        clk       : in  std_logic;
        rst       : in  std_logic;
        ready_in  : out std_logic;
        new_nmr   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        last_in   : in  std_logic;
        val_in    : in  std_logic;
        
        -- output signals
        val_out   : out std_logic;
        out_nmr   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        last_out  : out std_logic;
        ready_out : in  std_logic
    );
end cascade_comparator;

architecture Behavioral of cascade_comparator is

-- control related signals
type stateType is (stRecvNumbers, stWriteNumbers);

signal state, nextState: stateType;
signal enChains, rstChains: std_logic;
signal UnitCanRead, ValidNmr, LastNmr: std_logic;
signal forceLoadCtrl, sequenceCtrl: std_logic_vector(KNN - 1 downto 0);
signal forceLoadSR, validSR, lastSR: std_logic_vector(KNN - 1 downto 0);

-- info about the index
signal new_idx: unsigned(DATA_WIDTH - 1 downto 0);
signal enIdxCounter, rstIdxCounter: std_logic;

-- datapath components
component cascade_comparator_unit is
    port (
        clk, rst: in std_logic;
        frc_ld, seq, prv_evl: in std_logic;
        prv_nmr, new_nmr: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        cur_evl_out: out std_logic;
        cur_nmr_out: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        -- info about the index
        prv_idx, new_idx: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        cur_idx_out: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end component;

type con is array(KNN downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);

signal prv_nmr, prv_idx: con;
signal prv_evl: std_logic_vector(KNN downto 0);

begin

ready_in <= UnitCanRead;
val_out  <= ValidNmr;
out_nmr  <= prv_idx(KNN);
last_out <= LastNmr;

-- define next state
changeState: process(clk)
begin
    if rising_edge(clk) then
        if rst='1' then
            state <= stRecvNumbers;
        else
            state <= nextState;
        end if;
    end if;
end process;

fsmCombLogic: process(clk, state, val_in, last_in, ready_out, lastSR(KNN - 1))
begin
    -- initialize control signals to avoid latches
    nextState     <= state;
    enChains      <= '0';
    rstChains     <= '0';
    UnitCanRead   <= '0';
    ValidNmr      <= '0';
    LastNmr       <= '0';
    forceLoadCtrl <= (others=>'1');
    sequenceCtrl  <= (others=>'1');
    enIdxCounter  <= '0';
    rstIdxCounter <= '0';
    
    case state is
        when stRecvNumbers =>
            UnitCanRead <= '1'; -- receive the number
        
            -- there is a valid number to receive
            if val_in='1' then
                enChains      <= '1';           -- enable control chains
                forceLoadCtrl <= forceLoadSR;   -- control force load is default
                sequenceCtrl  <= (others=>'0'); -- there is no sequence to keep
                enIdxCounter  <= '1';           -- enable increment of index counter
                
                -- if it is the last number the state will change to write
                if last_in='1' then
                    nextState <= stWriteNumbers;
                end if;
            end if;
        when stWriteNumbers =>
            -- if master is ready to receive data
            if ready_out='1' then
                enChains      <= '1';            -- enable control chains
                ValidNmr      <= validSR(KNN - 1); -- the output number has its respective valid associated with it
                forceLoadCtrl <= (others=>'0');  -- nothing will be forced and the sequence will be kept
                
                -- if it is the last number to write
                if lastSR(KNN - 1)='1' then
                    nextState     <= stRecvNumbers; -- state will change to read data again
                    rstChains     <= '1';           -- control chains will be reset
                    LastNmr       <= '1';           -- last number to send
                    rstIdxCounter <= '1';           -- reset index counter for next serie
                end if;
            end if;
    end case;
end process;

chainsProcess: process(clk)
begin
    if rising_edge(clk) then
        if rst='1' or rstChains='1' then
            forceLoadSR <= (0=>'1', others=>'0');
            validSR     <= (others=>'0');
            lastSR      <= (others=>'0');
        elsif enChains='1' then
            forceLoadSR <= forceLoadSR(KNN - 2 downto 0) & '0';
            validSR     <= validSR(KNN - 2 downto 0) & val_in;
            lastSR      <= lastSR(KNN - 2 downto 0) & last_in;
        end if;
    end if;
end process;

indexCounterProcess: process(clk)
begin
    if rising_edge(clk) then
        if rst='1' or rstIdxCounter='1' then
            new_idx <= (others=>'0');
        elsif enIdxCounter='1' then
            new_idx <= new_idx + 1;
        end if;
    end if;
end process;

-- datapath of the IP
cascade: for i in 0 to KNN - 1 generate
    unit: cascade_comparator_unit
        port map (
            clk => clk, rst => rst,
            frc_ld => forceLoadCtrl(i), seq => sequenceCtrl(i), prv_evl => prv_evl(i),
            prv_nmr => prv_nmr(i), new_nmr => new_nmr,
            cur_evl_out => prv_evl(i + 1),
            cur_nmr_out => prv_nmr(i + 1),
            
            -- info about the index
            prv_idx => prv_idx(i), new_idx => std_logic_vector(new_idx),
            cur_idx_out => prv_idx(i + 1)
        );
end generate;

-- first and last units are a little different
prv_evl(0) <= '0';
prv_nmr(0) <= new_nmr;
prv_idx(0) <= std_logic_vector(new_idx);

end Behavioral;
