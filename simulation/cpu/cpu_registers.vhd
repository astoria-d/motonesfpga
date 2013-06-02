
----------------------------------------
--- program counter register declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity pc is 
    generic (
            dsize : integer := 8;
            reset_addr : integer := 0
            );
    port (  
            trig_clk        : in std_logic;
            res_n           : in std_logic;
            we_n            : in std_logic;
            dbus_oe_n       : in std_logic;
            abus_oe_n       : in std_logic;
            addr_inc_n      : in std_logic;
            addr_carry_n    : out std_logic;
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            int_a_bus       : out std_logic_vector (dsize - 1 downto 0)
        );
end pc;

architecture rtl of pc is

signal val : std_logic_vector (dsize - 1 downto 0);

begin
    int_a_bus <= val when abus_oe_n = '0' else
                (others => 'Z');
    int_d_bus <= val when (dbus_oe_n = '0' and we_n /= '0') else
                (others => 'Z');

    set_p : process (trig_clk, res_n)
    variable add_val : std_logic_vector(dsize downto 0);
    begin
        if ( trig_clk'event and trig_clk = '1') then
            if (addr_inc_n = '0') then
                add_val := ('0' & val) + 1;
                addr_carry_n <= not add_val(dsize);
                val <= add_val(dsize - 1 downto 0);
            end if;
            if (we_n = '0') then
                val <= int_d_bus;
            end if;
        elsif (res_n'event and res_n = '0') then
            val <= conv_std_logic_vector(reset_addr, dsize);
        end if;
    end process;
end rtl;

----------------------------------------
--- instruction register declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity dff is 
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
end dff;

architecture rtl of dff is
signal val : std_logic_vector (dsize - 1 downto 0);
begin

    process (clk)
    begin
        if ( clk'event and clk = '1'and we_n = '0') then
            val <= d;
        end if;
    end process;

    q <= val when oe_n = '0' else
        (others => 'Z');
end rtl;

