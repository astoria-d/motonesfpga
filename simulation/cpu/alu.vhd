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
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            int_ah_bus      : inout std_logic_vector (dsize - 1 downto 0);
            int_al_bus      : inout std_logic_vector (dsize - 1 downto 0);
            acc             : inout std_logic_vector (dsize - 1 downto 0);
            carry           : inout std_logic;
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
            clk         : in std_logic;
            ah_oe_n         : in std_logic;
            al_oe_n         : in std_logic;
            base            : in std_logic_vector (dsize - 1 downto 0);
            index           : in std_logic_vector (dsize - 1 downto 0);
            ah_bus          : out std_logic_vector (dsize - 1 downto 0);
            al_bus          : out std_logic_vector (dsize - 1 downto 0);
            carry           : out std_logic
    );
end effective_adder;

architecture rtl of effective_adder is
    component dff
        generic (
                dsize : integer := 8
                );
        port (  
                clk     : in std_logic;
                we_n    : in std_logic;
                oe_n    : in std_logic;
                d       : in std_logic_vector (dsize - 1 downto 0);
                q       : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

signal al_out : std_logic_vector (dsize - 1 downto 0);
signal ah_out : std_logic_vector (dsize - 1 downto 0);
signal old_al : std_logic_vector (dsize - 1 downto 0);
signal adc_work : std_logic_vector (dsize downto 0);

begin
    adc_work <= ('0' & base) + ('0' & index);
    carry <= adc_work(dsize);
    al_out <= adc_work(dsize - 1 downto 0);
    ---always remory adl.
    al_buf : dff generic map (dsize)
        port map (clk, '0', '0', al_out, old_al);

    --both output means, page boundary crossed.
    --output old effective addr low.
    al_bus <= old_al when al_oe_n = '0' and ah_oe_n = '0' else
            al_out when al_oe_n = '0' else
            (others => 'Z');

    --ah output means, page boundary crossed.
    ah_bus <= base + '1' when ah_oe_n = '0' else
            (others => 'Z');

end rtl;

