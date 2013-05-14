
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


--* AND Memory with Accumulator: AND
--* A & M -> A
--* Flags: N, Z

entity alu_and is
    port (  a, b    : in std_logic_vector (7 downto 0);
            and_o     : out std_logic_vector (7 downto 0);
            n, z    : out std_logic
            );
end alu_and;

architecture rtl of alu_and is
signal and_work : std_logic_vector (7 downto 0);
begin

    and_work <= a and b;

    n <= '1' when (and_work(7) = '1') else
         '0';
    z <= '1' when (and_work(7 downto 0) = "00000000") else
         '0';
    and_o <= and_work;

end rtl;

