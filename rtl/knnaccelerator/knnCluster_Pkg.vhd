library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package knnCluster_Pkg is
    
----------------------------------------------------------------------------------------------
-- CONSTANTS USED BY THE CLUSTER OF KNN ACCELERATORS
----------------------------------------------------------------------------------------------    
constant DATA_WIDTH     : integer := 32; -- do not change
constant KNN            : integer := 5;  -- change to configure the K in KNN
constant TEST_DEPTH     : integer := 10; -- change to log2(M) where M is the number of features
constant N_ACCELS       : integer := 2;  -- change the log2(C), where C is the number of accelerators

----------------------------------------------------------------------------------------------
-- DEFINITION OF TYPES
----------------------------------------------------------------------------------------------
type axis is record
    aclk    : std_logic;
    aresetn : std_logic;
    tready  : std_logic;
    tdata   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    tstrb   : std_logic_vector((DATA_WIDTH / 8) - 1 downto 0);
    tlast   : std_logic;
    tvalid  : std_logic;
end record;

type axis_array is array((2 ** N_ACCELS) - 1 downto 0) of axis;

end knnCluster_Pkg;
