library ieee;
use ieee.std_logic_1164.all;


entity alu is 
    generic (NN : integer := 8);
    port (  a, b    : in std_logic_vector (NN - 1 downto 0);
            o       : out std_logic_vector (NN - 1 downto 0);
            n, v, z, c   :   out std_logic
        );
end alu;

architecture rtl of alu is
signal alu : std_logic_vector (NN downto 0);
begin

end rtl;

