library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library ieee_proposed;
use ieee_proposed.float_pkg.all;

entity euclideanDistance_tb is
    generic (
        C_S_AXIS_TDATA_WIDTH : integer := 32;
        C_M_AXIS_TDATA_WIDTH : integer := 32
    );
end euclideanDistance_tb;

architecture Behavioral of euclideanDistance_tb is

component euclideanDistanceIP_v1_0 is
	generic (
		-- Users to add parameters here
        DATA_WIDTH : integer := 32;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXIS
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface M_AXIS
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S_AXIS
		s_axis_aclk	    : in std_logic;
		s_axis_aresetn	: in std_logic;
		s_axis_tready	: out std_logic;
		s_axis_tdata	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_tstrb	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tvalid	: in std_logic;

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
signal clk         : std_logic := '0';
signal rstn        : std_logic := '0';
signal dataIn      : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others=>'0');
signal dataLast    : std_logic := '0';
signal dataValid   : std_logic := '0';
signal masterReady : std_logic := '1';

-- output signals
signal ipReady             : std_logic;
signal resLast, resValid   : std_logic;
signal resOut              : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);

constant clkPeriod : time := 10 ns;

begin

uut: euclideanDistanceIP_v1_0
port map (
    s_axis_aclk    => clk,
    s_axis_aresetn => rstn,
    s_axis_tready  => ipReady,
    s_axis_tdata   => dataIn,
    s_axis_tstrb   => (others=>'1'),
    s_axis_tlast   => dataLast,
    s_axis_tvalid  => dataValid,
    m_axis_aclk    => clk,
    m_axis_aresetn => rstn,
    m_axis_tvalid  => resValid,
    m_axis_tdata   => resOut,
    m_axis_tstrb   => open,
    m_axis_tlast   => resLast,
    m_axis_tready  => masterReady
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
    
    dataIn <= to_slv(to_float(5.1)) after clkPeriod * 2,
              to_slv(to_float(3.5)) after clkPeriod * 3,
              to_slv(to_float(1.4)) after clkPeriod * 4,
              to_slv(to_float(0.2)) after clkPeriod * 5,
              to_slv(to_float(4.7)) after clkPeriod * 6,
              to_slv(to_float(3.2)) after clkPeriod * 7,
              to_slv(to_float(1.3)) after clkPeriod * 8,
              to_slv(to_float(0.2)) after clkPeriod * 9;
              
    dataValid <= '0',
                 '1' after clkPeriod * 2,
                 '0' after clkPeriod * 10;
                 
    dataLast  <= '0',
                 '1' after clkPeriod * 5,
                 '0' after clkPeriod * 6,
                 '1' after clkPeriod * 9;
                 
    wait for clkPeriod * 50;
              
    dataIn <= to_slv(to_float(4.9)) after clkPeriod * 10,
              to_slv(to_float(3.0)) after clkPeriod * 11,
              to_slv(to_float(1.4)) after clkPeriod * 12,
              to_slv(to_float(0.2)) after clkPeriod * 13,
              to_slv(to_float(5.1)) after clkPeriod * 14,
              to_slv(to_float(3.5)) after clkPeriod * 15,
              to_slv(to_float(1.4)) after clkPeriod * 16,
              to_slv(to_float(0.2)) after clkPeriod * 17;
                 
    dataValid <= '0',
                 '1' after clkPeriod * 10,
                 '0' after clkPeriod * 18;
    
    dataLast  <= '0' after clkPeriod * 10,
                 '1' after clkPeriod * 13,
                 '0' after clkPeriod * 14,
                 '1' after clkPeriod * 17;
    wait;
end process;

end Behavioral;
