
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_decoder is
end testbench_decoder;

architecture stimulus of testbench_decoder is 
    component decoder
        generic (dsize : integer := 8);
        port (  trig_clk    : in std_logic;
                instruction     : in std_logic_vector (dsize - 1 downto 0);
                status_reg      : in std_logic_vector (dsize - 1 downto 0);
                pcl_d_i_n       : out std_logic;
                pcl_d_o_n       : out std_logic;
                pcl_a_o_n       : out std_logic
            );
    end component;

    constant interval : time := 15 ns;
    constant dsize8 : integer := 8;
    signal cclk: std_logic;
    signal id_bus, ia_bus    : std_logic_vector (dsize8 - 1 downto 0);

begin

    p1 : process
    begin
        cclk <= '1';
        wait for interval / 2;
        cclk <= '0';
        wait for interval / 2;
    end process;

end stimulus ;

