
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
            dbus_in_n       : in std_logic;
            dbus_out_n      : in std_logic;
            abus_out_n      : in std_logic;
            addr_inc_n      : in std_logic;
            addr_page_nxt_n : out std_logic;
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            int_a_bus       : out std_logic_vector (dsize - 1 downto 0)
        );
end pc;

architecture rtl of pc is

signal val : std_logic_vector (dsize - 1 downto 0);

begin
    int_a_bus <= val when abus_out_n = '0' else
                (others => 'Z');
    int_d_bus <= val when (dbus_out_n = '0' and dbus_in_n /= '0') else
                (others => 'Z');

    set_p : process (trig_clk, res_n)
    variable add_val : std_logic_vector(dsize downto 0);
    begin
        if ( trig_clk'event and trig_clk = '1') then
            if (addr_inc_n = '0') then
                add_val := ('0' & val) + 1;
                addr_page_nxt_n <= not add_val(dsize);
                val <= add_val(dsize - 1 downto 0);
            end if;
            if (dbus_in_n = '0') then
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

entity instruction_reg is 
    generic (
            dsize : integer := 8
            );
    port (  
            set_clk         : in std_logic;
            cpu_d_bus       : in std_logic_vector (dsize - 1 downto 0);
            to_decoder      : out std_logic_vector (dsize - 1 downto 0)
        );
end instruction_reg;

architecture rtl of instruction_reg is
begin
    process (set_clk)
    begin
        if ( set_clk'event and set_clk = '1') then
            to_decoder <= cpu_d_bus;
        end if;
    end process;
end rtl;

