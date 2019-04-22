library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library knnCluster;
use knnCluster.knnCluster_Pkg.all;

entity singlePortMemory is
    port ( 
        clka  : in  std_logic;
        wea   : in  std_logic_vector(0             downto 0);
        addra : in  std_logic_vector(TEST_DEPTH - 1 downto 0);
        dina  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        douta : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end singlePortMemory;

architecture Behavioral of singlePortMemory is

-- declare type of memory
type mem_type is array (0 to (2 ** TEST_DEPTH) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

-- initialize memory with zeros (only for simulation purposes)
shared variable ram : mem_type := (others => (others => '0'));

begin

-- port a
process (clka)
begin
    -- all events have to be synchronous and ram protocol is write first
    if clka'event and clka = '1' then
        -- if write is enabled
        if wea(0) = '1' then
            -- write input to selected address
            ram(conv_integer(addra)) := dina;
        end if;

        -- otherwise just read
        douta <= ram(conv_integer(addra));
    end if;
end process;
         
end Behavioral;

