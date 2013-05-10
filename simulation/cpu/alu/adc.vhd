
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


--* Add Memory to Accumulator with Carry: ADC
--* A + M + C -> A
--* Flags: N, V, Z, C

entity adc is
    port (  a, b    : in std_logic_vector (7 downto 0);
            sum       : out std_logic_vector (7 downto 0);
            cin         : in std_logic;
            cout        : out std_logic;
            n, v, z : out std_logic
            );
end adc;

architecture rtl of adc is
signal adc_work : std_logic_vector (8 downto 0);
begin
    adc_work <= ('0' & a) + ('0' & b) + ("0000000" & cin);

    sum <= adc_work(7 downto 0);

    cout <= adc_work(8);
    v <= '1' when (a(7) = '0' and b(7) = '0' and adc_work(7) = '1') else
         '1' when (a(7) = '1' and b(7) = '1' and adc_work(7) = '0') else
         '0';

    n <= '1' when (adc_work(7) = '1') else
         '0';
    z <= '1' when (adc_work(7 downto 0) = "00000000") else
         '0';

end rtl;

