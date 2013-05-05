
library ieee;
--use ieee.std_logic_1164.std_logic;
--use ieee.std_logic_1164.std_logic_vector;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity adder8 is
    generic (N : integer := 8);
    port (  a, b    : in std_logic_vector (N - 1 downto 0);
            s       : out std_logic_vector (N - 1 downto 0);
            c       : out std_logic
            );
end adder8;

architecture rtl of adder8 is
signal add : std_logic_vector (N downto 0);
begin
    add <= ('0' & a) + ('0' & b);
    s <= add(N - 1 downto 0);
    c <= add(N);
end rtl;

