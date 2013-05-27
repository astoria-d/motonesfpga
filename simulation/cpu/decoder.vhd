library ieee;
use ieee.std_logic_1164.all;

entity decoder is 
    generic (dsize : integer := 8);
    port (  trig_clk        : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            status_reg      : in std_logic_vector (dsize - 1 downto 0);
            pcl_d_i_n       : out std_logic;
            pcl_d_o_n       : out std_logic;
            pcl_a_o_n       : out std_logic
        );
end decoder;

architecture rtl of decoder is

begin
end rtl;

