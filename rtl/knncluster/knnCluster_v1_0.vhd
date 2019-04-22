library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity knnCluster_v1_0 is
	generic (
		C_sp_axis_TDATA_WIDTH : integer	:= 32;
		C_sb_axis_TDATA_WIDTH : integer	:= 32;
		C_m_axis_TDATA_WIDTH  : integer	:= 32;
		C_m_axis_START_COUNT  : integer	:= 32
	);
	port (
		sp_axis_aclk	: in std_logic;
		sp_axis_aresetn	: in std_logic;
		sp_axis_tready	: out std_logic;
		sp_axis_tdata	: in std_logic_vector(C_sp_axis_TDATA_WIDTH-1 downto 0);
		sp_axis_tstrb	: in std_logic_vector((C_sp_axis_TDATA_WIDTH/8)-1 downto 0);
		sp_axis_tlast	: in std_logic;
		sp_axis_tvalid	: in std_logic;

		-- Ports of Axi Slave Bus Interface sb_axis
		sb_axis_aclk	: in std_logic;
		sb_axis_aresetn	: in std_logic;
		sb_axis_tready	: out std_logic;
		sb_axis_tdata	: in std_logic_vector(C_sb_axis_TDATA_WIDTH-1 downto 0);
		sb_axis_tstrb	: in std_logic_vector((C_sb_axis_TDATA_WIDTH/8)-1 downto 0);
		sb_axis_tlast	: in std_logic;
		sb_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface m_axis
		m_axis_aclk	    : in std_logic;
		m_axis_aresetn	: in std_logic;
		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(C_m_axis_TDATA_WIDTH-1 downto 0);
		m_axis_tstrb	: out std_logic_vector((C_m_axis_TDATA_WIDTH/8)-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end knnCluster_v1_0;

architecture arch_imp of knnCluster_v1_0 is

component knnAccelerator is
	port (
		-- Ports of Axi Slave Bus Interface SP_AXIS
		sp_axis_aclk	: in std_logic;
		sp_axis_aresetn	: in std_logic;
		sp_axis_tready	: out std_logic;
		sp_axis_tdata	: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		sp_axis_tstrb	: in std_logic_vector((DATA_WIDTH / 8) - 1 downto 0);
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
end component;

component routerDMA2IP is
	port (
		sp_axis, sb_axis : inout axis;
		mp_axis, mb_axis : inout axis_array
	);
end component;

component routerIP2DMA is
	port (
	    s_axis : inout axis_array;
	    m_axis : inout axis
	);
end component;

-- external interfaces wrappers
signal sp_axis, sb_axis, m_axis : axis;

-- internal interfaces wrappers
signal ir_mp_axis, or_s_axis, ir_mb_axis : axis_array;

signal tready_tmp : std_logic_vector((2 ** N_ACCELS) - 1 downto 0);

begin

-- private interface wrapper
sp_axis.aclk    <= sp_axis_aclk;
sp_axis.aresetn <= sp_axis_aresetn;
sp_axis_tready  <= sp_axis.tready;
sp_axis.tdata   <= sp_axis_tdata;
sp_axis.tstrb   <= sp_axis_tstrb;
sp_axis.tlast   <= sp_axis_tlast;
sp_axis.tvalid  <= sp_axis_tvalid;

-- broadcast interface wrapper
sb_axis.aclk    <= sb_axis_aclk;
sb_axis.aresetn <= sb_axis_aresetn;
sb_axis_tready  <= sb_axis.tready;
sb_axis.tdata   <= sb_axis_tdata;
sb_axis.tstrb   <= sb_axis_tstrb;
sb_axis.tlast   <= sb_axis_tlast;
sb_axis.tvalid  <= sb_axis_tvalid;

-- master interface wrapper
m_axis.aclk     <= m_axis_aclk;
m_axis.aresetn  <= m_axis_aresetn;
m_axis_tvalid   <= m_axis.tvalid;
m_axis_tdata    <= m_axis.tdata;
m_axis_tstrb    <= m_axis.tstrb;
m_axis_tlast    <= m_axis.tlast;
m_axis.tready   <= m_axis_tready;

router_in: routerDMA2IP
port map (
    sp_axis => sp_axis,
    sb_axis => sb_axis,
    mp_axis => ir_mp_axis,
    mb_axis => ir_mb_axis
);

router_out: routerIP2DMA
port map (
    s_axis => or_s_axis,
    m_axis => m_axis
);

cluster: for i in 0 to (2 ** N_ACCELS) - 1 generate
    -- generate clocks and resets
    or_s_axis(i).aclk     <= m_axis.aclk;
    or_s_axis(i).aresetn  <= m_axis.aresetn;
    ir_mp_axis(i).aclk    <= sp_axis.aclk;
    ir_mp_axis(i).aresetn <= sp_axis.aresetn;
    ir_mb_axis(i).aclk    <= m_axis.aclk;
    ir_mb_axis(i).aresetn <= m_axis.aresetn;

    -- generate accelerator cores
    accelerator: knnAccelerator
    port map (
        sp_axis_aclk    => sp_axis_aclk,
        sp_axis_aresetn => sp_axis_aresetn,
        sp_axis_tready  => ir_mp_axis(i).tready,
        sp_axis_tdata   => ir_mp_axis(i).tdata,
        sp_axis_tstrb   => ir_mp_axis(i).tstrb,
        sp_axis_tlast   => ir_mp_axis(i).tlast,
        sp_axis_tvalid  => ir_mp_axis(i).tvalid,
        
        sb_axis_aclk    => sb_axis_aclk,
        sb_axis_aresetn => sb_axis_aresetn,
        sb_axis_tready  => ir_mb_axis(i).tready,
        sb_axis_tdata   => ir_mb_axis(i).tdata,
        sb_axis_tstrb   => ir_mb_axis(i).tstrb, 
        sb_axis_tlast   => ir_mb_axis(i).tlast, 
        sb_axis_tvalid  => ir_mb_axis(i).tvalid, 
    
        m_axis_aclk     => m_axis_aclk,
        m_axis_aresetn  => m_axis_aresetn,
        m_axis_tvalid   => or_s_axis(i).tvalid, 
        m_axis_tdata    => or_s_axis(i).tdata,  
        m_axis_tstrb    => or_s_axis(i).tstrb,  
        m_axis_tlast    => or_s_axis(i).tlast,  
        m_axis_tready   => or_s_axis(i).tready 
    );
end generate;

end arch_imp;
