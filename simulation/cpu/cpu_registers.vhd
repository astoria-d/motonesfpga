
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
--- normal data latch declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity latch is 
    generic (
            dsize : integer := 8
            );
    port (  
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end latch;

architecture rtl of latch is
signal val : std_logic_vector (dsize - 1 downto 0);
begin

    process (we_n, d)
    begin
        if ( we_n = '0') then
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
    oe_n <= (int_oe_n and ext_oe_n);
    we_n <= (int_we_n and ext_we_n);
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

----------------------------------------
--- input data latch register
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity input_dl is 
    generic (
            dsize : integer := 8
            );
    port (  
            we_n        : in std_logic;
            int_d_oe_n  : in std_logic;
            int_al_oe_n : in std_logic;
            int_ah_oe_n : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            int_abus_l  : out std_logic_vector (dsize - 1 downto 0);
            int_abus_h  : out std_logic_vector (dsize - 1 downto 0)
        );
end input_dl;

architecture rtl of input_dl is
component latch
    generic (
            dsize : integer := 8
            );
    port (  
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;
signal oe_n : std_logic;
signal q : std_logic_vector (dsize - 1 downto 0);
begin
    oe_n <= (int_d_oe_n and int_al_oe_n and int_ah_oe_n);
    int_dbus <= q when int_d_oe_n = '0' else
         (others =>'Z');
    int_abus_l <= q when int_al_oe_n = '0' else
         (others =>'Z');
    int_abus_h <= q when int_ah_oe_n = '0' else
         (others =>'Z');
    latch_inst : latch generic map (dsize) 
                    port map(we_n, oe_n, int_dbus, q);
end rtl;

----------------------------------------
--- stack pointer register
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sp is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            we_n        : in std_logic;
            int_d_oe_n  : in std_logic;
            int_a_oe_n  : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            int_abus_l  : out std_logic_vector (dsize - 1 downto 0);
            int_abus_h  : out std_logic_vector (dsize - 1 downto 0)
        );
end sp;

architecture rtl of sp is
component dff
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;
signal oe_n : std_logic;
signal q : std_logic_vector (dsize - 1 downto 0);
begin
    oe_n <= (int_d_oe_n and int_a_oe_n);
    int_dbus <= q when int_d_oe_n = '0' else
         (others =>'Z');
    int_abus_l <= q when int_a_oe_n = '0' else
         (others =>'Z');
    int_abus_h <= "00000001" when int_a_oe_n = '0' else
         (others =>'Z');
    dff_inst : dff generic map (dsize) 
                    port map(clk, we_n, oe_n, int_dbus, q);
end rtl;

