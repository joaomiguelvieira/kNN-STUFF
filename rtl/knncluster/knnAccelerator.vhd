----------------------------------------------------------------------------------
-- Company: IST
-- Engineer: Joao Vieira
-- 
-- Create Date: 17.05.2017 17:07:50
-- Module Name: euclideanDistanceIP_v1_0 - Behavioral
-- Project Name: k nearest neighbors
-- Target Devices: Zynq 7000
-- Tool Versions: Vivado 2016.4
-- Description: IP that computes the k nearest neighbors for a given test point
--
-- Additional Comments: the expected inputs are:
--                      - one test sample composed of its parameters (first stream)
--                      - all control samples concatenated (second and last stream)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity knnAccelerator is
    port (
		-- Ports of Axi Slave Bus Interface SP_AXIS
		sp_axis_aclk	    : in std_logic;
		sp_axis_aresetn	: in std_logic;
		sp_axis_tready	: out std_logic;
		sp_axis_tdata	: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		sp_axis_tstrb	: in std_logic_vector((DATA_WIDTH / 8)-1 downto 0);
		sp_axis_tlast	: in std_logic;
		sp_axis_tvalid	: in std_logic;
		
		-- Ports of Axi Slave Bus Interface SB_AXIS
        sb_axis_aclk    : in std_logic;
        sb_axis_aresetn : in std_logic;
        sb_axis_tready  : out std_logic;
        sb_axis_tdata   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        sb_axis_tstrb   : in std_logic_vector((DATA_WIDTH / 8) - 1 downto 0);
        sb_axis_tlast   : in std_logic;
        sb_axis_tvalid  : in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS
		m_axis_aclk	    : in std_logic;
		m_axis_aresetn	: in std_logic;
		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		m_axis_tstrb	: out std_logic_vector((DATA_WIDTH / 8) - 1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end knnAccelerator;

architecture Behavioral of knnAccelerator is

-- components
component compute_distances is
	port (
		-- Ports of Axi Slave Bus Interface SP_AXIS
        sp_axis_aclk    : in std_logic;
        sp_axis_aresetn : in std_logic;
        sp_axis_tready  : out std_logic;
        sp_axis_tdata   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        sp_axis_tstrb   : in std_logic_vector((DATA_WIDTH / 8)-1 downto 0);
        sp_axis_tlast   : in std_logic;
        sp_axis_tvalid  : in std_logic;
        
        -- Ports of Axi Slave Bus Interface SB_AXIS
        sb_axis_aclk    : in std_logic;
        sb_axis_aresetn : in std_logic;
        sb_axis_tready  : out std_logic;
        sb_axis_tdata   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        sb_axis_tstrb   : in std_logic_vector((DATA_WIDTH / 8)-1 downto 0);
        sb_axis_tlast   : in std_logic;
        sb_axis_tvalid  : in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS
		m_axis_aclk	    : in std_logic;
		m_axis_aresetn	: in std_logic;
		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		m_axis_tstrb	: out std_logic_vector((DATA_WIDTH / 8) - 1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end component;

component cascade_comparator is
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
end component;

signal cascValid, cascLast, cascReady: std_logic;
signal cascData: std_logic_vector(DATA_WIDTH - 1 downto 0);
signal rst: std_logic;

begin

distanceComputation: compute_distances
    port map (
        -- Ports of Axi Slave Bus Interface SP_AXIS
        sp_axis_aclk	=> sp_axis_aclk,
        sp_axis_aresetn	=> sp_axis_aresetn,
        sp_axis_tready	=> sp_axis_tready,
        sp_axis_tdata	=> sp_axis_tdata,
        sp_axis_tstrb	=> sp_axis_tstrb,
        sp_axis_tlast	=> sp_axis_tlast,
        sp_axis_tvalid	=> sp_axis_tvalid,
        
        -- Ports of Axi Slave Bus Interface SB_AXIS
        sb_axis_aclk    => sb_axis_aclk,
        sb_axis_aresetn => sb_axis_aresetn,
        sb_axis_tready  => sb_axis_tready,
        sb_axis_tdata   => sb_axis_tdata,
        sb_axis_tstrb   => sb_axis_tstrb,
        sb_axis_tlast   => sb_axis_tlast,
        sb_axis_tvalid  => sb_axis_tvalid,
    
        -- Ports of Axi Master Bus Interface M_AXIS
        m_axis_aclk	    => m_axis_aclk,
        m_axis_aresetn	=> m_axis_aresetn,
        m_axis_tvalid	=> cascValid,
        m_axis_tdata	=> cascData,
        m_axis_tstrb	=> m_axis_tstrb,
        m_axis_tlast	=> cascLast,
        m_axis_tready	=> cascReady
    );

rst <= not sp_axis_aresetn;

minorValuesChooser: cascade_comparator
    port map (
        -- input signals
        clk       => sp_axis_aclk,
        rst       => rst,
        ready_in  => cascReady,
        new_nmr   => cascData,
        last_in   => cascLast,
        val_in    => cascValid,
        
        -- output signals
        val_out   => m_axis_tvalid,
        out_nmr   => m_axis_tdata,
        last_out  => m_axis_tlast,
        ready_out => m_axis_tready
    );

end Behavioral;
