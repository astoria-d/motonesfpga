--------------------------------
----------shift registers -----
--------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity shift_register is 
    
    generic (
        dsize : integer := 8
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic
    );
end shift_register;

architecture rtl of shift_register is

component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;


begin

end rtl;

-------------------------------
------ count up registers -----
-------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity counter_register is 
    
    generic (
        dsize : integer := 8
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end counter_register;

architecture rtl of counter_register is

component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

use ieee.std_logic_unsigned.all;

signal d : std_logic_vector(dsize - 1 downto 0);
signal q_out : std_logic_vector(dsize - 1 downto 0);

begin
    q <= q_out;
    couter_inst : d_flip_flop generic map (dsize)
            port map (clk, rst_n, '1', ce_n, d, q_out);
        
    clk_p : process (clk) 
    begin
        if (ce_n = '0') then
            d <= q_out + 1;
        end if;
    end process;

end rtl;


