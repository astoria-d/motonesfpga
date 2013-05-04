-- HA: half addr

library IEEE;
use IEEE.std_logic_1164.all;

entity HA is 
    port (
            A, B : in std_logic;
            S, C : out std_logic
         );
end HA;


architecture rtl of HA is
signal x, y : std_logic;
begin
    x <= a or b;
    y <= not (a and b);
    s <= x and y;
    c <= not y;
end rtl;

