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

signal counter, prev_counter : unsigned(N_ACCELS - 1 downto 0);
signal brdc : std_logic;
signal tready : std_logic_vector((2 ** N_ACCELS) - 1 downto 0);

begin

round_robin: process(mp_axis(0).aclk)
begin
    -- all processes are synchronous
    if mp_axis(0).aclk'event and mp_axis(0).aclk = '1' then
        -- reset
        if mp_axis(0).aresetn = '0' then
            prev_counter <= (others => '0');
            counter      <= (others => '0');
            brdc         <= '0';
        else
            -- switch channel if received tlast (unless when broadcasting)
            if sp_axis.tlast = '1' or (brdc = '1' and sb_axis.tlast = '1') then
                if (counter = 0 and prev_counter /= 0) then
                    prev_counter <= counter;
                    counter      <= counter;
                    brdc         <= '1';
                else
                    prev_counter <= counter;
                    counter      <= counter + 1;
                    brdc         <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

signals: for i in 0 to (2 ** N_ACCELS) - 1 generate
    mp_axis(i).tvalid <= sp_axis.tvalid when counter = i else '0';
    mp_axis(i).tdata  <= sp_axis.tdata;
    mp_axis(i).tstrb  <= sp_axis.tstrb;
    mp_axis(i).tlast  <= sp_axis.tlast when counter = i else '0';
    
    mb_axis(i).tvalid <= sb_axis.tvalid when counter = 0 and brdc = '0' else '0';
    mb_axis(i).tdata  <= sb_axis.tdata;
    mb_axis(i).tstrb  <= sb_axis.tstrb;
    mb_axis(i).tlast  <= sb_axis.tlast when counter = 0 and brdc = '0' else '0';
    
    tready(i) <= mb_axis(i).tready;
end generate;

sp_axis.tready <= mp_axis(to_integer(counter)).tready;

sb_axis.tready <= and_reduce(tready) when counter = 0 and brdc = '0' else '1';

end arch_imp;
