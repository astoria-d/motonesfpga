
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
--- normal d-flipflop declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

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

----------------------------------------
--- data bus buffer register
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity dbus_buf is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            int_we_n    : in std_logic;
            ext_we_n    : in std_logic;
            int_oe_n    : in std_logic;
            ext_oe_n    : in std_logic;
            int_dbus : inout std_logic_vector (dsize - 1 downto 0);
            ext_dbus : inout std_logic_vector (dsize - 1 downto 0)
        );
end dbus_buf;

architecture rtl of dbus_buf is
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
signal we_n : std_logic;
signal oe_n : std_logic;
signal d : std_logic_vector (dsize - 1 downto 0);
signal q : std_logic_vector (dsize - 1 downto 0);
begin
    oe_n <= not (int_oe_n nand ext_oe_n);
    we_n <= not (int_we_n nand ext_we_n);
    d <= int_dbus when int_we_n = '0' else
         ext_dbus when ext_we_n = '0' else
         (others => 'Z');
    int_dbus <= q when int_oe_n = '0' else
         (others =>'Z');
    ext_dbus <= q when ext_oe_n = '0' else
         (others =>'Z');
    dff_inst : dff generic map (dsize) 
                    port map(clk, we_n, oe_n, d, q);
end rtl;

