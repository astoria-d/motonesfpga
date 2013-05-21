
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


--* AND Memory with Accumulator: AND
--* A & M -> A
--* Flags: N, Z

entity alu_and is
    port (  d1, d2      : in std_logic_vector (7 downto 0);
            q           : out std_logic_vector (7 downto 0);
            neg, zero        : out std_logic
            );
end alu_and;

architecture rtl of alu_and is
signal and_work : std_logic_vector (7 downto 0);
begin

    and_work <= d1 and d2;

    neg <= '1' when (and_work(7) = '1') else
         '0';
    zero <= '1' when (and_work(7 downto 0) = "00000000") else
         '0';
    q <= and_work;

end rtl;

