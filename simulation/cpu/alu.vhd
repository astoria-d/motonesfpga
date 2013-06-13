----------------------------
---- 6502 ALU implementation
----------------------------
library ieee;
use ieee.std_logic_1164.all;

entity alu is 
    generic (   dsize : integer := 8
            );
    port (  alu_sel         : in std_logic_vector (2 downto 0);
            d_we_n          : in std_logic;
            d_oe_n          : in std_logic;
            ah_we_n         : in std_logic;
            ah_oe_n         : in std_logic;
            al_we_n         : in std_logic;
            al_oe_n         : in std_logic;
            acc_we_n        : in std_logic;
            acc_oe_n        : in std_logic;
            carry_in        : in std_logic;
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            int_ah_bus      : inout std_logic_vector (dsize - 1 downto 0);
            int_al_bus      : inout std_logic_vector (dsize - 1 downto 0);
            acc             : inout std_logic_vector (dsize - 1 downto 0);
            negative        : out std_logic;
            zero            : out std_logic;
            carry_out       : out std_logic;
            overflow        : out std_logic
    );
end alu;

architecture rtl of alu is
signal d1 : std_logic_vector (dsize - 1 downto 0);
signal d2 : std_logic_vector (dsize - 1 downto 0);
signal d_out : std_logic_vector (dsize - 1 downto 0);
begin

end rtl;


----------------------------------------
---- 6502 effective address calucurator
----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity effective_adder is 
    generic (   dsize : integer := 8
            );
    port (  
            ea_calc_n       : in std_logic;
            zp_n            : in std_logic;
            pg_next_n       : in std_logic;
            base_l          : in std_logic_vector (dsize - 1 downto 0);
            base_h          : in std_logic_vector (dsize - 1 downto 0);
            index           : in std_logic_vector (dsize - 1 downto 0);
            ah_bus          : out std_logic_vector (dsize - 1 downto 0);
            al_bus          : out std_logic_vector (dsize - 1 downto 0);
            carry           : out std_logic
    );
end effective_adder;

architecture rtl of effective_adder is

signal adc_work : std_logic_vector (dsize downto 0);

begin
    adc_work <= ('0' & base_l) + ('0' & index);
    carry <= adc_work(dsize) when ea_calc_n = '0' else
            'Z';
    --if not calc effective adder, pass through input.
    al_bus <= adc_work(dsize - 1 downto 0) when ea_calc_n = '0' else
            base_l;

    ah_bus <= "00000000" when ea_calc_n = '0' and zp_n = '0' else
            base_h + '1' when ea_calc_n = '0' and pg_next_n = '0' else
            base_h;

end rtl;

