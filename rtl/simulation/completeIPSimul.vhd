library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library ieee_proposed;
use ieee_proposed.float_pkg.all;

entity completeIPSimul is
    generic (
        C_S_AXIS_TDATA_WIDTH : integer := 32;
        C_M_AXIS_TDATA_WIDTH : integer := 32
    );
end completeIPSimul;

architecture Behavioral of completeIPSimul is

component euclideanDistanceIP_v1_0 is
    generic (
        -- User parameters
        DATA_WIDTH : integer := 32;
        
        -- Parameters of Axi Slave Bus Interface S_AXIS
        C_SP_AXIS_TDATA_WIDTH	: integer	:= 32;
        C_SB_AXIS_TDATA_WIDTH	: integer	:= 32;
        
        -- Parameters of Axi Master Bus Interface M_AXIS
        C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
        C_M_AXIS_START_COUNT	: integer	:= 32
    );
	port (
		-- Ports of Axi Slave Bus Interface SP_AXIS
		sp_axis_aclk	    : in std_logic;
		sp_axis_aresetn	: in std_logic;
		sp_axis_tready	: out std_logic;
		sp_axis_tdata	: in std_logic_vector(C_SP_AXIS_TDATA_WIDTH-1 downto 0);
		sp_axis_tstrb	: in std_logic_vector((C_SP_AXIS_TDATA_WIDTH/8)-1 downto 0);
		sp_axis_tlast	: in std_logic;
		sp_axis_tvalid	: in std_logic;
		
		-- Ports of Axi Slave Bus Interface SB_AXIS
        sb_axis_aclk    : in std_logic;
        sb_axis_aresetn : in std_logic;
        sb_axis_tready  : out std_logic;
        sb_axis_tdata   : in std_logic_vector(C_SB_AXIS_TDATA_WIDTH-1 downto 0);
        sb_axis_tstrb   : in std_logic_vector((C_SB_AXIS_TDATA_WIDTH/8)-1 downto 0);
        sb_axis_tlast   : in std_logic;
        sb_axis_tvalid  : in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS
		m_axis_aclk	    : in std_logic;
		m_axis_aresetn	: in std_logic;
		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		m_axis_tstrb	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end component;

-- input signals
signal clk             : std_logic := '0';
signal rstn            : std_logic := '0';
signal dataTest        : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others=>'0');
signal dataCtrl        : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others=>'0');
signal dataTestLast    : std_logic := '0';
signal dataCtrlLast    : std_logic := '0';
signal dataTestValid   : std_logic := '0';
signal dataCtrlValid   : std_logic := '0';
signal masterReady     : std_logic := '1';

-- output signals
signal ipReadyTest, ipReadyCtrl : std_logic;
signal resLast, resValid        : std_logic;
signal resOut                   : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);

constant clkPeriod : time := 10 ns;

begin

uut: euclideanDistanceIP_v1_0
port map (
    -- Ports of Axi Slave Bus Interface SP_AXIS
    sp_axis_aclk    => clk,
    sp_axis_aresetn => rstn,
    sp_axis_tready  => ipReadyTest,
    sp_axis_tdata   => dataTest,
    sp_axis_tstrb   => (others=>'1'),
    sp_axis_tlast   => dataTestLast,
    sp_axis_tvalid  => dataTestValid,
    
    -- Ports of Axi Slave Bus Interface SB_AXIS
    sb_axis_aclk    => clk,
    sb_axis_aresetn => rstn,
    sb_axis_tready  => ipReadyCtrl,
    sb_axis_tdata   => dataCtrl,
    sb_axis_tstrb   => (others=>'1'),
    sb_axis_tlast   => dataCtrlLast,
    sb_axis_tvalid  => dataCtrlValid,

    -- Ports of Axi Master Bus Interface M_AXIS
    m_axis_aclk     => clk,
    m_axis_aresetn  => rstn,
    m_axis_tvalid   => resValid,
    m_axis_tdata    => resOut,
    m_axis_tstrb    => open,
    m_axis_tlast    => resLast,
    m_axis_tready   => masterReady
);

clk_process: process
begin
    clk <= '1';
    wait for clkPeriod / 2;
    clk <= '0';
    wait for clkPeriod / 2;
end process;

stim_process: process
begin
    wait for 100 ns;

    rstn   <= '1' after clkPeriod * 2;
    
    wait for clkPeriod / 2;
    
    dataTest <= to_slv(to_float(6.9)) after clkPeriod * 2,
    to_slv(to_float(3.2)) after clkPeriod * 3,
    to_slv(to_float(5.7)) after clkPeriod * 4,
    to_slv(to_float(2.3)) after clkPeriod * 5;
    
    dataCtrl <= to_slv(to_float(5.1)) after clkPeriod * 6,
    to_slv(to_float(3.5)) after clkPeriod * 7,
    to_slv(to_float(1.4)) after clkPeriod * 8,
    to_slv(to_float(0.2)) after clkPeriod * 9,
    to_slv(to_float(4.9)) after clkPeriod * 10,
    to_slv(to_float(3.0)) after clkPeriod * 11,
    to_slv(to_float(1.4)) after clkPeriod * 12,
    to_slv(to_float(0.2)) after clkPeriod * 13,
    to_slv(to_float(4.7)) after clkPeriod * 14,
    to_slv(to_float(3.2)) after clkPeriod * 15,
    to_slv(to_float(1.3)) after clkPeriod * 16,
    to_slv(to_float(0.2)) after clkPeriod * 17,
    to_slv(to_float(4.6)) after clkPeriod * 18,
    to_slv(to_float(3.1)) after clkPeriod * 19,
    to_slv(to_float(1.5)) after clkPeriod * 20,
    to_slv(to_float(0.2)) after clkPeriod * 21,
    to_slv(to_float(5.0)) after clkPeriod * 22,
    to_slv(to_float(3.6)) after clkPeriod * 23,
    to_slv(to_float(1.4)) after clkPeriod * 24,
    to_slv(to_float(0.2)) after clkPeriod * 25,
    to_slv(to_float(5.4)) after clkPeriod * 26,
    to_slv(to_float(3.9)) after clkPeriod * 27,
    to_slv(to_float(1.7)) after clkPeriod * 28,
    to_slv(to_float(0.4)) after clkPeriod * 29,
    to_slv(to_float(4.6)) after clkPeriod * 30,
    to_slv(to_float(3.4)) after clkPeriod * 31,
    to_slv(to_float(1.4)) after clkPeriod * 32,
    to_slv(to_float(0.3)) after clkPeriod * 33,
    to_slv(to_float(5.0)) after clkPeriod * 34,
    to_slv(to_float(3.4)) after clkPeriod * 35,
    to_slv(to_float(1.5)) after clkPeriod * 36,
    to_slv(to_float(0.2)) after clkPeriod * 37,
    to_slv(to_float(4.4)) after clkPeriod * 38,
    to_slv(to_float(2.9)) after clkPeriod * 39,
    to_slv(to_float(1.4)) after clkPeriod * 40,
    to_slv(to_float(0.2)) after clkPeriod * 41,
    to_slv(to_float(4.9)) after clkPeriod * 42,
    to_slv(to_float(3.1)) after clkPeriod * 43,
    to_slv(to_float(1.5)) after clkPeriod * 44,
    to_slv(to_float(0.1)) after clkPeriod * 45,
    to_slv(to_float(5.4)) after clkPeriod * 46,
    to_slv(to_float(3.7)) after clkPeriod * 47,
    to_slv(to_float(1.5)) after clkPeriod * 48,
    to_slv(to_float(0.2)) after clkPeriod * 49,
    to_slv(to_float(4.8)) after clkPeriod * 50,
    to_slv(to_float(3.4)) after clkPeriod * 51,
    to_slv(to_float(1.6)) after clkPeriod * 52,
    to_slv(to_float(0.2)) after clkPeriod * 53,
    to_slv(to_float(4.8)) after clkPeriod * 54,
    to_slv(to_float(3.0)) after clkPeriod * 55,
    to_slv(to_float(1.4)) after clkPeriod * 56,
    to_slv(to_float(0.1)) after clkPeriod * 57,
    to_slv(to_float(4.3)) after clkPeriod * 58,
    to_slv(to_float(3.0)) after clkPeriod * 59,
    to_slv(to_float(1.1)) after clkPeriod * 60,
    to_slv(to_float(0.1)) after clkPeriod * 61,
    to_slv(to_float(5.8)) after clkPeriod * 62,
    to_slv(to_float(4.0)) after clkPeriod * 63,
    to_slv(to_float(1.2)) after clkPeriod * 64,
    to_slv(to_float(0.2)) after clkPeriod * 65,
    to_slv(to_float(5.7)) after clkPeriod * 66,
    to_slv(to_float(4.4)) after clkPeriod * 67,
    to_slv(to_float(1.5)) after clkPeriod * 68,
    to_slv(to_float(0.4)) after clkPeriod * 69,
    to_slv(to_float(5.4)) after clkPeriod * 70,
    to_slv(to_float(3.9)) after clkPeriod * 71,
    to_slv(to_float(1.3)) after clkPeriod * 72,
    to_slv(to_float(0.4)) after clkPeriod * 73,
    to_slv(to_float(5.1)) after clkPeriod * 74,
    to_slv(to_float(3.5)) after clkPeriod * 75,
    to_slv(to_float(1.4)) after clkPeriod * 76,
    to_slv(to_float(0.3)) after clkPeriod * 77,
    to_slv(to_float(5.7)) after clkPeriod * 78,
    to_slv(to_float(3.8)) after clkPeriod * 79,
    to_slv(to_float(1.7)) after clkPeriod * 80,
    to_slv(to_float(0.3)) after clkPeriod * 81,
    to_slv(to_float(5.1)) after clkPeriod * 82,
    to_slv(to_float(3.8)) after clkPeriod * 83,
    to_slv(to_float(1.5)) after clkPeriod * 84,
    to_slv(to_float(0.3)) after clkPeriod * 85,
    to_slv(to_float(5.4)) after clkPeriod * 86,
    to_slv(to_float(3.4)) after clkPeriod * 87,
    to_slv(to_float(1.7)) after clkPeriod * 88,
    to_slv(to_float(0.2)) after clkPeriod * 89,
    to_slv(to_float(5.1)) after clkPeriod * 90,
    to_slv(to_float(3.7)) after clkPeriod * 91,
    to_slv(to_float(1.5)) after clkPeriod * 92,
    to_slv(to_float(0.4)) after clkPeriod * 93,
    to_slv(to_float(4.6)) after clkPeriod * 94,
    to_slv(to_float(3.6)) after clkPeriod * 95,
    to_slv(to_float(1.0)) after clkPeriod * 96,
    to_slv(to_float(0.2)) after clkPeriod * 97,
    to_slv(to_float(5.1)) after clkPeriod * 98,
    to_slv(to_float(3.3)) after clkPeriod * 99,
    to_slv(to_float(1.7)) after clkPeriod * 100,
    to_slv(to_float(0.5)) after clkPeriod * 101,
    to_slv(to_float(4.8)) after clkPeriod * 102,
    to_slv(to_float(3.4)) after clkPeriod * 103,
    to_slv(to_float(1.9)) after clkPeriod * 104,
    to_slv(to_float(0.2)) after clkPeriod * 105,
    to_slv(to_float(5.0)) after clkPeriod * 106,
    to_slv(to_float(3.0)) after clkPeriod * 107,
    to_slv(to_float(1.6)) after clkPeriod * 108,
    to_slv(to_float(0.2)) after clkPeriod * 109,
    to_slv(to_float(5.0)) after clkPeriod * 110,
    to_slv(to_float(3.4)) after clkPeriod * 111,
    to_slv(to_float(1.6)) after clkPeriod * 112,
    to_slv(to_float(0.4)) after clkPeriod * 113,
    to_slv(to_float(5.2)) after clkPeriod * 114,
    to_slv(to_float(3.5)) after clkPeriod * 115,
    to_slv(to_float(1.5)) after clkPeriod * 116,
    to_slv(to_float(0.2)) after clkPeriod * 117,
    to_slv(to_float(5.2)) after clkPeriod * 118,
    to_slv(to_float(3.4)) after clkPeriod * 119,
    to_slv(to_float(1.4)) after clkPeriod * 120,
    to_slv(to_float(0.2)) after clkPeriod * 121,
    to_slv(to_float(4.7)) after clkPeriod * 122,
    to_slv(to_float(3.2)) after clkPeriod * 123,
    to_slv(to_float(1.6)) after clkPeriod * 124,
    to_slv(to_float(0.2)) after clkPeriod * 125,
    to_slv(to_float(4.8)) after clkPeriod * 126,
    to_slv(to_float(3.1)) after clkPeriod * 127,
    to_slv(to_float(1.6)) after clkPeriod * 128,
    to_slv(to_float(0.2)) after clkPeriod * 129,
    to_slv(to_float(5.4)) after clkPeriod * 130,
    to_slv(to_float(3.4)) after clkPeriod * 131,
    to_slv(to_float(1.5)) after clkPeriod * 132,
    to_slv(to_float(0.4)) after clkPeriod * 133,
    to_slv(to_float(5.2)) after clkPeriod * 134,
    to_slv(to_float(4.1)) after clkPeriod * 135,
    to_slv(to_float(1.5)) after clkPeriod * 136,
    to_slv(to_float(0.1)) after clkPeriod * 137,
    to_slv(to_float(5.5)) after clkPeriod * 138,
    to_slv(to_float(4.2)) after clkPeriod * 139,
    to_slv(to_float(1.4)) after clkPeriod * 140,
    to_slv(to_float(0.2)) after clkPeriod * 141,
    to_slv(to_float(4.9)) after clkPeriod * 142,
    to_slv(to_float(3.1)) after clkPeriod * 143,
    to_slv(to_float(1.5)) after clkPeriod * 144,
    to_slv(to_float(0.1)) after clkPeriod * 145,
    to_slv(to_float(5.0)) after clkPeriod * 146,
    to_slv(to_float(3.2)) after clkPeriod * 147,
    to_slv(to_float(1.2)) after clkPeriod * 148,
    to_slv(to_float(0.2)) after clkPeriod * 149,
    to_slv(to_float(5.5)) after clkPeriod * 150,
    to_slv(to_float(3.5)) after clkPeriod * 151,
    to_slv(to_float(1.3)) after clkPeriod * 152,
    to_slv(to_float(0.2)) after clkPeriod * 153,
    to_slv(to_float(4.9)) after clkPeriod * 154,
    to_slv(to_float(3.1)) after clkPeriod * 155,
    to_slv(to_float(1.5)) after clkPeriod * 156,
    to_slv(to_float(0.1)) after clkPeriod * 157,
    to_slv(to_float(4.4)) after clkPeriod * 158,
    to_slv(to_float(3.0)) after clkPeriod * 159,
    to_slv(to_float(1.3)) after clkPeriod * 160,
    to_slv(to_float(0.2)) after clkPeriod * 161,
    to_slv(to_float(5.1)) after clkPeriod * 162,
    to_slv(to_float(3.4)) after clkPeriod * 163,
    to_slv(to_float(1.5)) after clkPeriod * 164,
    to_slv(to_float(0.2)) after clkPeriod * 165,
    to_slv(to_float(7.0)) after clkPeriod * 166,
    to_slv(to_float(3.2)) after clkPeriod * 167,
    to_slv(to_float(4.7)) after clkPeriod * 168,
    to_slv(to_float(1.4)) after clkPeriod * 169,
    to_slv(to_float(6.4)) after clkPeriod * 170,
    to_slv(to_float(3.2)) after clkPeriod * 171,
    to_slv(to_float(4.5)) after clkPeriod * 172,
    to_slv(to_float(1.5)) after clkPeriod * 173,
    to_slv(to_float(6.9)) after clkPeriod * 174,
    to_slv(to_float(3.1)) after clkPeriod * 175,
    to_slv(to_float(4.9)) after clkPeriod * 176,
    to_slv(to_float(1.5)) after clkPeriod * 177,
    to_slv(to_float(5.5)) after clkPeriod * 178,
    to_slv(to_float(2.3)) after clkPeriod * 179,
    to_slv(to_float(4.0)) after clkPeriod * 180,
    to_slv(to_float(1.3)) after clkPeriod * 181,
    to_slv(to_float(6.5)) after clkPeriod * 182,
    to_slv(to_float(2.8)) after clkPeriod * 183,
    to_slv(to_float(4.6)) after clkPeriod * 184,
    to_slv(to_float(1.5)) after clkPeriod * 185,
    to_slv(to_float(5.7)) after clkPeriod * 186,
    to_slv(to_float(2.8)) after clkPeriod * 187,
    to_slv(to_float(4.5)) after clkPeriod * 188,
    to_slv(to_float(1.3)) after clkPeriod * 189,
    to_slv(to_float(6.3)) after clkPeriod * 190,
    to_slv(to_float(3.3)) after clkPeriod * 191,
    to_slv(to_float(4.7)) after clkPeriod * 192,
    to_slv(to_float(1.6)) after clkPeriod * 193,
    to_slv(to_float(4.9)) after clkPeriod * 194,
    to_slv(to_float(2.4)) after clkPeriod * 195,
    to_slv(to_float(3.3)) after clkPeriod * 196,
    to_slv(to_float(1.0)) after clkPeriod * 197,
    to_slv(to_float(6.6)) after clkPeriod * 198,
    to_slv(to_float(2.9)) after clkPeriod * 199,
    to_slv(to_float(4.6)) after clkPeriod * 200,
    to_slv(to_float(1.3)) after clkPeriod * 201,
    to_slv(to_float(5.2)) after clkPeriod * 202,
    to_slv(to_float(2.7)) after clkPeriod * 203,
    to_slv(to_float(3.9)) after clkPeriod * 204,
    to_slv(to_float(1.4)) after clkPeriod * 205,
    to_slv(to_float(5.0)) after clkPeriod * 206,
    to_slv(to_float(2.0)) after clkPeriod * 207,
    to_slv(to_float(3.5)) after clkPeriod * 208,
    to_slv(to_float(1.0)) after clkPeriod * 209,
    to_slv(to_float(5.9)) after clkPeriod * 210,
    to_slv(to_float(3.0)) after clkPeriod * 211,
    to_slv(to_float(4.2)) after clkPeriod * 212,
    to_slv(to_float(1.5)) after clkPeriod * 213,
    to_slv(to_float(6.0)) after clkPeriod * 214,
    to_slv(to_float(2.2)) after clkPeriod * 215,
    to_slv(to_float(4.0)) after clkPeriod * 216,
    to_slv(to_float(1.0)) after clkPeriod * 217,
    to_slv(to_float(6.1)) after clkPeriod * 218,
    to_slv(to_float(2.9)) after clkPeriod * 219,
    to_slv(to_float(4.7)) after clkPeriod * 220,
    to_slv(to_float(1.4)) after clkPeriod * 221,
    to_slv(to_float(5.6)) after clkPeriod * 222,
    to_slv(to_float(2.9)) after clkPeriod * 223,
    to_slv(to_float(3.6)) after clkPeriod * 224,
    to_slv(to_float(1.3)) after clkPeriod * 225,
    to_slv(to_float(6.7)) after clkPeriod * 226,
    to_slv(to_float(3.1)) after clkPeriod * 227,
    to_slv(to_float(4.4)) after clkPeriod * 228,
    to_slv(to_float(1.4)) after clkPeriod * 229,
    to_slv(to_float(5.6)) after clkPeriod * 230,
    to_slv(to_float(3.0)) after clkPeriod * 231,
    to_slv(to_float(4.5)) after clkPeriod * 232,
    to_slv(to_float(1.5)) after clkPeriod * 233,
    to_slv(to_float(5.8)) after clkPeriod * 234,
    to_slv(to_float(2.7)) after clkPeriod * 235,
    to_slv(to_float(4.1)) after clkPeriod * 236,
    to_slv(to_float(1.0)) after clkPeriod * 237,
    to_slv(to_float(6.2)) after clkPeriod * 238,
    to_slv(to_float(2.2)) after clkPeriod * 239,
    to_slv(to_float(4.5)) after clkPeriod * 240,
    to_slv(to_float(1.5)) after clkPeriod * 241,
    to_slv(to_float(5.6)) after clkPeriod * 242,
    to_slv(to_float(2.5)) after clkPeriod * 243,
    to_slv(to_float(3.9)) after clkPeriod * 244,
    to_slv(to_float(1.1)) after clkPeriod * 245,
    to_slv(to_float(5.9)) after clkPeriod * 246,
    to_slv(to_float(3.2)) after clkPeriod * 247,
    to_slv(to_float(4.8)) after clkPeriod * 248,
    to_slv(to_float(1.8)) after clkPeriod * 249,
    to_slv(to_float(6.1)) after clkPeriod * 250,
    to_slv(to_float(2.8)) after clkPeriod * 251,
    to_slv(to_float(4.0)) after clkPeriod * 252,
    to_slv(to_float(1.3)) after clkPeriod * 253,
    to_slv(to_float(6.3)) after clkPeriod * 254,
    to_slv(to_float(2.5)) after clkPeriod * 255,
    to_slv(to_float(4.9)) after clkPeriod * 256,
    to_slv(to_float(1.5)) after clkPeriod * 257,
    to_slv(to_float(6.1)) after clkPeriod * 258,
    to_slv(to_float(2.8)) after clkPeriod * 259,
    to_slv(to_float(4.7)) after clkPeriod * 260,
    to_slv(to_float(1.2)) after clkPeriod * 261,
    to_slv(to_float(6.4)) after clkPeriod * 262,
    to_slv(to_float(2.9)) after clkPeriod * 263,
    to_slv(to_float(4.3)) after clkPeriod * 264,
    to_slv(to_float(1.3)) after clkPeriod * 265,
    to_slv(to_float(6.6)) after clkPeriod * 266,
    to_slv(to_float(3.0)) after clkPeriod * 267,
    to_slv(to_float(4.4)) after clkPeriod * 268,
    to_slv(to_float(1.4)) after clkPeriod * 269,
    to_slv(to_float(6.8)) after clkPeriod * 270,
    to_slv(to_float(2.8)) after clkPeriod * 271,
    to_slv(to_float(4.8)) after clkPeriod * 272,
    to_slv(to_float(1.4)) after clkPeriod * 273,
    to_slv(to_float(6.7)) after clkPeriod * 274,
    to_slv(to_float(3.0)) after clkPeriod * 275,
    to_slv(to_float(5.0)) after clkPeriod * 276,
    to_slv(to_float(1.7)) after clkPeriod * 277,
    to_slv(to_float(6.0)) after clkPeriod * 278,
    to_slv(to_float(2.9)) after clkPeriod * 279,
    to_slv(to_float(4.5)) after clkPeriod * 280,
    to_slv(to_float(1.5)) after clkPeriod * 281,
    to_slv(to_float(5.7)) after clkPeriod * 282,
    to_slv(to_float(2.6)) after clkPeriod * 283,
    to_slv(to_float(3.5)) after clkPeriod * 284,
    to_slv(to_float(1.0)) after clkPeriod * 285,
    to_slv(to_float(5.5)) after clkPeriod * 286,
    to_slv(to_float(2.4)) after clkPeriod * 287,
    to_slv(to_float(3.8)) after clkPeriod * 288,
    to_slv(to_float(1.1)) after clkPeriod * 289,
    to_slv(to_float(5.5)) after clkPeriod * 290,
    to_slv(to_float(2.4)) after clkPeriod * 291,
    to_slv(to_float(3.7)) after clkPeriod * 292,
    to_slv(to_float(1.0)) after clkPeriod * 293,
    to_slv(to_float(5.8)) after clkPeriod * 294,
    to_slv(to_float(2.7)) after clkPeriod * 295,
    to_slv(to_float(3.9)) after clkPeriod * 296,
    to_slv(to_float(1.2)) after clkPeriod * 297,
    to_slv(to_float(6.0)) after clkPeriod * 298,
    to_slv(to_float(2.7)) after clkPeriod * 299,
    to_slv(to_float(5.1)) after clkPeriod * 300,
    to_slv(to_float(1.6)) after clkPeriod * 301,
    to_slv(to_float(5.4)) after clkPeriod * 302,
    to_slv(to_float(3.0)) after clkPeriod * 303,
    to_slv(to_float(4.5)) after clkPeriod * 304,
    to_slv(to_float(1.5)) after clkPeriod * 305,
    to_slv(to_float(6.0)) after clkPeriod * 306,
    to_slv(to_float(3.4)) after clkPeriod * 307,
    to_slv(to_float(4.5)) after clkPeriod * 308,
    to_slv(to_float(1.6)) after clkPeriod * 309,
    to_slv(to_float(6.7)) after clkPeriod * 310,
    to_slv(to_float(3.1)) after clkPeriod * 311,
    to_slv(to_float(4.7)) after clkPeriod * 312,
    to_slv(to_float(1.5)) after clkPeriod * 313,
    to_slv(to_float(6.3)) after clkPeriod * 314,
    to_slv(to_float(2.3)) after clkPeriod * 315,
    to_slv(to_float(4.4)) after clkPeriod * 316,
    to_slv(to_float(1.3)) after clkPeriod * 317,
    to_slv(to_float(5.6)) after clkPeriod * 318,
    to_slv(to_float(3.0)) after clkPeriod * 319,
    to_slv(to_float(4.1)) after clkPeriod * 320,
    to_slv(to_float(1.3)) after clkPeriod * 321,
    to_slv(to_float(5.5)) after clkPeriod * 322,
    to_slv(to_float(2.5)) after clkPeriod * 323,
    to_slv(to_float(4.0)) after clkPeriod * 324,
    to_slv(to_float(1.3)) after clkPeriod * 325,
    to_slv(to_float(6.3)) after clkPeriod * 326,
    to_slv(to_float(3.3)) after clkPeriod * 327,
    to_slv(to_float(6.0)) after clkPeriod * 328,
    to_slv(to_float(2.5)) after clkPeriod * 329,
    to_slv(to_float(5.8)) after clkPeriod * 330,
    to_slv(to_float(2.7)) after clkPeriod * 331,
    to_slv(to_float(5.1)) after clkPeriod * 332,
    to_slv(to_float(1.9)) after clkPeriod * 333,
    to_slv(to_float(7.1)) after clkPeriod * 334,
    to_slv(to_float(3.0)) after clkPeriod * 335,
    to_slv(to_float(5.9)) after clkPeriod * 336,
    to_slv(to_float(2.1)) after clkPeriod * 337,
    to_slv(to_float(6.3)) after clkPeriod * 338,
    to_slv(to_float(2.9)) after clkPeriod * 339,
    to_slv(to_float(5.6)) after clkPeriod * 340,
    to_slv(to_float(1.8)) after clkPeriod * 341,
    to_slv(to_float(6.5)) after clkPeriod * 342,
    to_slv(to_float(3.0)) after clkPeriod * 343,
    to_slv(to_float(5.8)) after clkPeriod * 344,
    to_slv(to_float(2.2)) after clkPeriod * 345,
    to_slv(to_float(7.6)) after clkPeriod * 346,
    to_slv(to_float(3.0)) after clkPeriod * 347,
    to_slv(to_float(6.6)) after clkPeriod * 348,
    to_slv(to_float(2.1)) after clkPeriod * 349,
    to_slv(to_float(4.9)) after clkPeriod * 350,
    to_slv(to_float(2.5)) after clkPeriod * 351,
    to_slv(to_float(4.5)) after clkPeriod * 352,
    to_slv(to_float(1.7)) after clkPeriod * 353,
    to_slv(to_float(7.3)) after clkPeriod * 354,
    to_slv(to_float(2.9)) after clkPeriod * 355,
    to_slv(to_float(6.3)) after clkPeriod * 356,
    to_slv(to_float(1.8)) after clkPeriod * 357,
    to_slv(to_float(6.7)) after clkPeriod * 358,
    to_slv(to_float(2.5)) after clkPeriod * 359,
    to_slv(to_float(5.8)) after clkPeriod * 360,
    to_slv(to_float(1.8)) after clkPeriod * 361,
    to_slv(to_float(7.2)) after clkPeriod * 362,
    to_slv(to_float(3.6)) after clkPeriod * 363,
    to_slv(to_float(6.1)) after clkPeriod * 364,
    to_slv(to_float(2.5)) after clkPeriod * 365,
    to_slv(to_float(6.5)) after clkPeriod * 366,
    to_slv(to_float(3.2)) after clkPeriod * 367,
    to_slv(to_float(5.1)) after clkPeriod * 368,
    to_slv(to_float(2.0)) after clkPeriod * 369,
    to_slv(to_float(6.4)) after clkPeriod * 370,
    to_slv(to_float(2.7)) after clkPeriod * 371,
    to_slv(to_float(5.3)) after clkPeriod * 372,
    to_slv(to_float(1.9)) after clkPeriod * 373,
    to_slv(to_float(6.8)) after clkPeriod * 374,
    to_slv(to_float(3.0)) after clkPeriod * 375,
    to_slv(to_float(5.5)) after clkPeriod * 376,
    to_slv(to_float(2.1)) after clkPeriod * 377,
    to_slv(to_float(5.7)) after clkPeriod * 378,
    to_slv(to_float(2.5)) after clkPeriod * 379,
    to_slv(to_float(5.0)) after clkPeriod * 380,
    to_slv(to_float(2.0)) after clkPeriod * 381,
    to_slv(to_float(5.8)) after clkPeriod * 382,
    to_slv(to_float(2.8)) after clkPeriod * 383,
    to_slv(to_float(5.1)) after clkPeriod * 384,
    to_slv(to_float(2.4)) after clkPeriod * 385,
    to_slv(to_float(6.4)) after clkPeriod * 386,
    to_slv(to_float(3.2)) after clkPeriod * 387,
    to_slv(to_float(5.3)) after clkPeriod * 388,
    to_slv(to_float(2.3)) after clkPeriod * 389,
    to_slv(to_float(6.5)) after clkPeriod * 390,
    to_slv(to_float(3.0)) after clkPeriod * 391,
    to_slv(to_float(5.5)) after clkPeriod * 392,
    to_slv(to_float(1.8)) after clkPeriod * 393,
    to_slv(to_float(7.7)) after clkPeriod * 394,
    to_slv(to_float(3.8)) after clkPeriod * 395,
    to_slv(to_float(6.7)) after clkPeriod * 396,
    to_slv(to_float(2.2)) after clkPeriod * 397,
    to_slv(to_float(7.7)) after clkPeriod * 398,
    to_slv(to_float(2.6)) after clkPeriod * 399,
    to_slv(to_float(6.9)) after clkPeriod * 400,
    to_slv(to_float(2.3)) after clkPeriod * 401,
    to_slv(to_float(6.0)) after clkPeriod * 402,
    to_slv(to_float(2.2)) after clkPeriod * 403,
    to_slv(to_float(5.0)) after clkPeriod * 404,
    to_slv(to_float(1.5)) after clkPeriod * 405;
              
    dataTestValid <= '0',
                 '1' after clkPeriod * 2,
                 '0' after clkPeriod * 6;
    
    dataCtrlValid <= '0',
                 '1' after clkPeriod * 6,
                 '0' after clkPeriod * 406;
                 
    dataTestLast <= '0',
                 '1' after clkPeriod * 5;
    
    dataCtrlLast <= '0',
                 '1' after clkPeriod * 405;
                 
    wait;
end process;

end Behavioral;
