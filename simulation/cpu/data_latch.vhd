library ieee;
use ieee.std_logic_1164.all;

entity data_latch is 
    generic (dsize : integer := 8);
    port (  clk, en     : in std_logic;
            d           : in std_logic_vector (dsize - 1 downto 0);
            q           : out std_logic_vector (dsize - 1 downto 0)
        );
end data_latch;

architecture rtl of data_latch is
begin
    p : process (clk, d)
    begin
    if (clk= '1' and en = '1') then
        q <= d;
    end if;
    end process;
end rtl;

