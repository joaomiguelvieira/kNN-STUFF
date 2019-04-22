library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity compute_distances is
	port (
		-- Ports of Axi Slave Bus Interface SP_AXIS
		sp_axis_aclk	: in std_logic;
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
        sb_axis_tstrb   : in std_logic_vector((DATA_WIDTH / 8)-1 downto 0);
        sb_axis_tlast   : in std_logic;
        sb_axis_tvalid  : in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS
		m_axis_aclk	    : in std_logic;
		m_axis_aresetn	: in std_logic;
		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		m_axis_tstrb	: out std_logic_vector((DATA_WIDTH / 8)-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end compute_distances;

architecture arch_imp of compute_distances is

-- components declaration
component euclideanDistanceFloat is
    port (
        clk, rst            : in  std_logic;
        cordCtrl, cordTest  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        valid, lastCord     : in  std_logic;
        validOut, lastOut   : out std_logic;
        distance            : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end component;

component singlePortMemory is
    port ( 
        clka  : in  std_logic;
        wea   : in  std_logic_vector(0             downto 0);
        addra : in  std_logic_vector(TEST_DEPTH - 1 downto 0);
        dina  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        douta : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end component;

component fifoOut
    port (
        clk   : in  std_logic;
        srst  : in  std_logic;
        din   : in  std_logic_vector(31 DOWNTO 0);
        wr_en : in  std_logic;
        rd_en : in  std_logic;
        dout  : out std_logic_vector(31 DOWNTO 0);
        full  : out std_logic;
        empty : out std_logic
    );
end component;

-- definition of types
type stateTypeIn  is (stIdle, stReadTestCoords, stReadCtrlCoords);
type stateTypeOut is (stIdle, stWriteDistance);

-- control signals
signal IPCanWrite, IPCanRead : std_logic;
signal stateIn, nextStateIn : stateTypeIn;
signal lastAcc : std_logic;
signal enReadCounter, incCtrlCounter, decCtrlCounter : std_logic;
signal ramWE : std_logic_vector(0 downto 0);
signal rstReadCounter, rstCtrlCounter : std_logic;
signal ctrlCoordValid, lastCtrlCoord : std_logic;
signal readCounter, sampleSize : unsigned(TEST_DEPTH - 1 downto 0);
signal ctrlCounter : unsigned(25 downto 0);
signal stSampleSize, lastDistance : std_logic;
signal rst : std_logic;
signal cordTest : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal dlCordCtrl : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal distance : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal dlLastCtrlCoord, dlCtrlCoordValid : std_logic;
signal fifoWE, fifoRE, fifoFull, fifoEmpty : std_logic;
signal fifoDataOut : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal stateOut, nextStateOut : stateTypeOut;
signal IPIsReady : std_logic;

begin

m_axis_tvalid <= IPCanWrite;
sp_axis_tready <= IPCanRead;
sb_axis_tready <= IPCanRead;
m_axis_tlast  <= lastDistance;
m_axis_tstrb  <= (others=>'1');

-- define next state of both fsm
changeState: process(sp_axis_aclk)
begin
    if rising_edge(sp_axis_aclk) then
        if sp_axis_aresetn='0' then
            stateIn  <= stReadTestCoords;
            stateOut <= stIdle;
        else
            stateIn  <= nextStateIn;
            stateOut <= nextStateOut;
        end if;
    end if;
end process;

-- input fsm
fsmInCombLogic: process(stateIn, stateOut, sp_axis_tvalid, sb_axis_tvalid, sp_axis_tlast, sb_axis_tlast, sampleSize, readCounter)
begin
    -- initialize control signals to avoid latches
    nextStateIn      <= stateIn;
    IPCanRead        <= '0';
    ramWE(0)         <= '0';
    lastCtrlCoord    <= '0';
    ctrlCoordValid   <= '0';
    enReadCounter    <= '0';
    rstReadCounter   <= '0';
    stSampleSize     <= '0';
    incCtrlCounter   <= '0';

    case stateIn is
        when stIdle =>
            -- leave idle state if the previous computing session is complete
            if IPIsReady='1' then
                nextStateIn <= stReadTestCoords;
            end if;
        when stReadTestCoords =>
            IPCanRead <= '1'; -- ip is ready
        
            -- there is a test coordinate to read
            if sp_axis_tvalid='1'then
                enReadCounter <= '1'; -- enable test coordinates counter
                ramWE(0)      <= '1'; -- enable write in ram memory
                
                -- last test coordinate
                if sp_axis_tlast='1' then
                    nextStateIn    <= stReadCtrlCoords; -- start reading control coordinates
                    rstReadCounter <= '1';              -- reset read counter
                    stSampleSize   <= '1';              -- store the number of parameters
                end if;
            end if;
        when stReadCtrlCoords =>
            IPCanRead <= '1'; -- ip is ready
        
            -- there is a control coordinate to read
            if sb_axis_tvalid='1' then
                ctrlCoordValid <= '1'; -- set to '1' the valid signal of inner IP
                enReadCounter  <= '1'; -- enable the read counter to get next test stored feature
                
                -- marks the end of a control sample and the begin of another
                if sampleSize=readCounter then
                    rstReadCounter <= '1'; -- reset the read counter to start reading again the test sample
                    incCtrlCounter <= '1'; -- increment the counter of control coordinates
                    lastCtrlCoord  <= '1'; -- set to '1' the last signal of inner IP
                end if;
                
                -- all control coordinates were read thus wait until pipeline is empty
                if sb_axis_tlast='1' then
                    nextStateIn    <= stIdle;
                end if;
            end if;
    end case;
end process;

-- output fsm
fsmOutCombLogic: process(stateOut, m_axis_tready, fifoEmpty)
begin
    -- initialize control signals to avoid latches
    nextStateOut   <= stateOut;
    IPCanWrite     <= '0';
    fifoRE         <= '0';
    decCtrlCounter <= '0';
    lastDistance   <= '0';
    IPIsReady      <= '0';
    
    case stateOut is
        when stIdle =>
            -- there are results to dispatch, so leave the idle state
            if fifoEmpty='0' then
                nextStateOut <= stWriteDistance;
            end if;
        when stWriteDistance =>
            -- there are results to write and axi-stream is ready
            if fifoEmpty='0' and m_axis_tready='1' then
                IPCanWrite     <= '1'; -- write one result
                fifoRE         <= '1'; -- get the next result if there is any
                decCtrlCounter <= '1'; -- one less to write
                
                -- if this result is the last one to be written
                if std_match(ctrlCounter, "00000000000000000000000001") and stateIn=stIdle then
                    nextStateOut <= stIdle; -- switch to idle mode allowing another computing session to start
                    IPIsReady    <= '1';    -- IP is ready to start another computing session
                    lastDistance <= '1';    -- set to '1' the last signal of outer IP
                end if;
            end if;
    end case;
end process;

-- read counter
readCounterProcess: process(sp_axis_aclk)
begin
    if rising_edge(sp_axis_aclk) then
        if sp_axis_aresetn='0' or rstReadCounter='1' then
            readCounter <= (others=>'0');
        elsif enReadCounter='1' then
            readCounter <= readCounter + 1;
        end if;
    end if;
end process;

-- control samples counter
ctrlCounterProcess: process(sp_axis_aclk)
begin
    if rising_edge(sp_axis_aclk) then
        if sp_axis_aresetn='0' or rstCtrlCounter='1' then
            ctrlCounter <= (others=>'0');
        elsif incCtrlCounter='1' and decCtrlCounter='0' then
            ctrlCounter <= ctrlCounter + 1;
        elsif incCtrlCounter='0' and decCtrlCounter='1' then
            ctrlCounter <= ctrlCounter - 1;
        end if;
    end if;
end process;

-- size of test sample storage
stSampleSizeProcess: process(sp_axis_aclk)
begin
    if rising_edge(sp_axis_aclk) then
        if sp_axis_aresetn='0' then
            sampleSize <= (others=>'0');
        elsif stSampleSize='1' then
            sampleSize <= readCounter;
        end if;
    end if;
end process;

-- delay the input of the control coordinates because the RAM where the test coordinates were stored takes one cycle to read
delayProcess: process(sp_axis_aclk)
begin
    if rising_edge(sp_axis_aclk) then
        if sp_axis_aresetn='0' then
            dlCordCtrl       <= (others=>'0');
            dlCtrlCoordValid <= '0';
            dlLastCtrlCoord  <= '0';
        else
            dlCordCtrl       <= sb_axis_tdata;
            dlCtrlCoordValid <= ctrlCoordValid;
            dlLastCtrlCoord  <= lastCtrlCoord;
        end if;
    end if;
end process;

-- some IPs have reset active in high
rst <= not sp_axis_aresetn;

-- mega components of the datapath
euclideanDistance: euclideanDistanceFloat
    port map (
        clk      => sp_axis_aclk,
        rst      => rst,
        cordCtrl => dlCordCtrl,
        cordTest => cordTest,
        valid    => dlCtrlCoordValid,
        lastCord => dlLastCtrlCoord,
        validOut => open,
        lastOut  => lastAcc,
        distance => distance
    );

testCoordsMem: singlePortMemory
    port map (
        clka  => sp_axis_aclk,
        wea   => ramWE,
        addra => std_logic_vector(readCounter),
        dina  => sp_axis_tdata,
        douta => cordTest
    );

-- fifo is meant to relax the comunication
auxCommunication: fifoOut
    port map (
        clk   => sp_axis_aclk,
        srst  => rst,
        din   => distance,
        wr_en => fifoWE,
        rd_en => fifoRE,
        dout  => fifoDataOut,
        full  => fifoFull,
        empty => fifoEmpty
    );

fifoWE <= lastAcc;
m_axis_tdata <= fifoDataOut;

end arch_imp;
