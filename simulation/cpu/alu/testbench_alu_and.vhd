
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_alu_and is
end testbench_alu_and;

architecture stimulus of testbench_alu_and is 
    component alu_and
    port (  d1, d2      : in std_logic_vector (7 downto 0);
            q           : out std_logic_vector (7 downto 0);
            neg, zero        : out std_logic
            );
    end component;
    signal aa, bb, aand: std_logic_vector (7 downto 0);
    signal nn, zz : std_logic;
begin
end stimulus ;

