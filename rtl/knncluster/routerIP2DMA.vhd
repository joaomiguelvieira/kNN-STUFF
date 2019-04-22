library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity routerIP2DMA is
	port (
	    s_axis : inout axis_array;
	    m_axis : inout axis
	);
end routerIP2DMA;

architecture arch_imp of routerIP2DMA is

signal counter : unsigned(N_ACCELS - 1 downto 0);
signal tlast : std_logic;

begin

round_robin: process(m_axis.aclk)
begin
    -- all processes are synchronous
    if m_axis.aclk'event and m_axis.aclk = '1' then
        -- reset
        if m_axis.aresetn = '0' then
            counter <= (others => '0');
        else
            -- switch channel if received tlast
            if tlast = '1' then
                counter <= counter + 1;
            end if;
        end if;
    end if;
end process;

m_axis.tvalid <= s_axis(to_integer(counter)).tvalid;
m_axis.tdata  <= s_axis(to_integer(counter)).tdata;
m_axis.tstrb  <= s_axis(to_integer(counter)).tstrb;
tlast         <= s_axis(to_integer(counter)).tlast;

signals: for i in 0 to (2 ** N_ACCELS) - 1 generate
    s_axis(i).tready <= m_axis.tready when counter = i else '0';
end generate;

m_axis.tlast <= tlast;

end arch_imp;
