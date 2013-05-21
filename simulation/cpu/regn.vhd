library ieee;
use ieee.std_logic_1164.all;

entity regn is 
    generic (dsize : integer := 8);
    port (  clk, en     : in std_logic;
            d           : in std_logic_vector (dsize - 1 downto 0);
            q           : out std_logic_vector (dsize - 1 downto 0)
        );
end regn;

architecture rtl of regn is
begin
    p : process (clk)
    begin
    if (clk'event and clk = '1') then
        if (en = '1') then
            q <= d;
        end if;
    end if;
    end process;
end rtl;

