library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity euclideanDistanceFloat is
    port (
        clk, rst            : in  std_logic;
        cordCtrl, cordTest  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        valid, lastCord     : in  std_logic;
        validOut, lastOut   : out std_logic;
        distance            : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end euclideanDistanceFloat;

architecture Behavioral of euclideanDistanceFloat is

-- declaration of components
COMPONENT sub_float
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_a_tlast : IN STD_LOGIC;
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tlast : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT mul_float
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_a_tlast : IN STD_LOGIC;
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tlast : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT acc_float
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_a_tlast : IN STD_LOGIC;
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tlast : OUT STD_LOGIC
  );
END COMPONENT;

-- in
signal mulValid, accValid : std_logic;
signal mulData,  accData  : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal mulLast,  accLast  : std_logic;
signal lowRst             : std_logic;

begin

subtractor : sub_float
    PORT MAP (
        aclk => clk,
        s_axis_a_tvalid => valid,
        s_axis_a_tdata => cordCtrl,
        s_axis_a_tlast => lastCord,
        s_axis_b_tvalid => valid,
        s_axis_b_tdata => cordTest,
        m_axis_result_tvalid => mulValid,
        m_axis_result_tdata => mulData,
        m_axis_result_tlast => mulLast
    );
  
multiplier : mul_float
    PORT MAP (
        aclk => clk,
        s_axis_a_tvalid => mulValid,
        s_axis_a_tdata => mulData,
        s_axis_a_tlast => mulLast,
        s_axis_b_tvalid => mulValid,
        s_axis_b_tdata => mulData,
        m_axis_result_tvalid => accValid,
        m_axis_result_tdata => accData,
        m_axis_result_tlast => accLast
    );
    
lowRst <= not rst;

accumulator : acc_float
    PORT MAP (
        aclk => clk,
        aresetn => lowRst,
        s_axis_a_tvalid => accValid,
        s_axis_a_tdata => accData,
        s_axis_a_tlast => accLast,
        m_axis_result_tvalid => validOut,
        m_axis_result_tdata => distance,
        m_axis_result_tlast => lastOut
    );
    
end Behavioral;
