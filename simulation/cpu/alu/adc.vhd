
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


--* Add Memory to Accumulator with Carry: ADC
--* A + M + C -> A
--* Flags: N, V, Z, C

entity adc is
    port (  a, b    : in std_logic_vector (7 downto 0);
            s       : out std_logic_vector (7 downto 0);
            cin         : in std_logic;
            cout        : out std_logic;
            n, v, z : out std_logic
            );
end adc;

architecture rtl of adc is
signal adc : std_logic_vector (8 downto 0);
begin
    adc <= ('0' & a) + ('0' & b) + ("0000" & cin);
    s <= adc(7 downto 0);
    cout <= adc(8);
    n <= '0';
    v <= '0';
    z <= '0';
end rtl;

