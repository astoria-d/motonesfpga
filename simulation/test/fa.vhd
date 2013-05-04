
--ha: full adder

library ieee;
use ieee.std_logic_1164.all;

entity fa is
    port (
            a, b, c : in std_logic;
            s, cout : out std_logic
         );
end ha;

architecture structure of fa is
    component ha
        port (  a, b : in std_logic;
                s, c : out std_logic
             );
    end component;
signal s0, cout0, cout1 : std_logic;
begin
    ha0 : ha port map a, b, s0, cout0;
    ha1 : ha port map s0, c, s, cout1;
    cout <= cout0 or cout1;
end structure;



