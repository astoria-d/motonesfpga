library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu_test is 
    port (  
        d1    : in std_logic_vector(7 downto 0);
        d2    : in std_logic_vector(7 downto 0);
        d_out    : out std_logic_vector(7 downto 0);
        carry_clr_n : in std_logic;
        ea_carry : out std_logic
        );
end alu_test;

architecture rtl of alu_test is

begin

    alu_p : process (d1, d2, carry_clr_n )
    variable d_tmp : std_logic_vector(8 downto 0);
    begin
        d_tmp := ("0" & d1) + ("0" & d2);
        d_out <= d_tmp (7 downto 0);
        if (carry_clr_n = '0') then
            ea_carry <= '0';
        else
            ea_carry <= d_tmp(8);
        end if;
    end process;

end rtl;

