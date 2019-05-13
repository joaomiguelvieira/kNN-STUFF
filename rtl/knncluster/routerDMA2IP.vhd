library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity routerDMA2IP is
	port (
		sp_axis, sb_axis : inout axis;
		mp_axis, mb_axis : inout axis_array
	);
end routerDMA2IP;

architecture arch_imp of routerDMA2IP is

type stateType is (stReadTestCoords, stReadCtrlCoords);

signal counter : unsigned(N_ACCELS - 1 downto 0);
signal brdc : std_logic;
signal tready : std_logic_vector((2 ** N_ACCELS) - 1 downto 0);
signal inc_counter : std_logic;

signal state, nextState : stateType;

begin

changeState: process(sp_axis.aclk)
begin
    if rising_edge(sp_axis.aclk) then
        if sp_axis.aresetn = '0' then
            state <= stReadTestCoords;
        else
            state <= nextState;
        end if;
    end if;
end process;

counterProc: process(sp_axis.aclk)
begin
    if rising_edge(sp_axis.aclk) then
        if sp_axis.aresetn = '0' then
            counter <= (others => '0');
        elsif inc_counter = '1' then
            counter <= counter + 1;
        end if;
    end if;
end process;

fsmCombLogic: process(state, sp_axis.tlast, counter, sb_axis.tlast)
begin
    -- default values
    nextState   <= state;
    brdc        <= '0';
    inc_counter <= '0';
    
    case state is
        when stReadTestCoords =>
            if sp_axis.tlast = '1' then
                inc_counter <= '1';
                
                if counter = (2 ** N_ACCELS) - 1 then
                    nextState <= stReadCtrlCoords;
                end if;
            end if;
        when stReadCtrlCoords =>
            brdc <= '1';
            
            if sb_axis.tlast = '1' then
                nextState <= stReadTestCoords;
            end if;
    end case;
end process;

signals: for i in 0 to (2 ** N_ACCELS) - 1 generate
    mp_axis(i).tvalid <= sp_axis.tvalid when counter = i else '0';
    mp_axis(i).tdata  <= sp_axis.tdata;
    mp_axis(i).tstrb  <= sp_axis.tstrb;
    mp_axis(i).tlast  <= sp_axis.tlast when counter = i else '0';
    
    mb_axis(i).tvalid <= sb_axis.tvalid when brdc = '1' else '0';
    mb_axis(i).tdata  <= sb_axis.tdata;
    mb_axis(i).tstrb  <= sb_axis.tstrb;
    mb_axis(i).tlast  <= sb_axis.tlast when brdc = '1' else '0';
    
    tready(i) <= mb_axis(i).tready;
end generate;

sp_axis.tready <= mp_axis(to_integer(counter)).tready;

sb_axis.tready <= and_reduce(tready) when brdc = '1' else '1';

end arch_imp;
