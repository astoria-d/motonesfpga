
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


--* Add Memory to Accumulator with Carry: ADC
--* A + M + C -> A
--* Flags: N, V, Z, C

entity alu_adc is
    port (  d1, d2      : in std_logic_vector (7 downto 0);
            q           : out std_logic_vector (7 downto 0);
            cry_in          : in std_logic;
            cry_out         : out std_logic;
            neg, ovf, zero  : out std_logic
            );
end alu_adc;

architecture rtl of alu_adc is
signal adc_work : std_logic_vector (8 downto 0);
begin
    adc_work <= ('0' & d1) + ('0' & d2) + ("0000000" & cry_in);

    q <= adc_work(7 downto 0);

    cry_out <= adc_work(8);
    ovf <= '1' when (d1(7) = '0' and d2(7) = '0' and adc_work(7) = '1') else
         '1' when (d1(7) = '1' and d2(7) = '1' and adc_work(7) = '0') else
         '0';

    neg <= '1' when (adc_work(7) = '1') else
         '0';
    zero <= '1' when (adc_work(7 downto 0) = "00000000") else
         '0';

end rtl;

