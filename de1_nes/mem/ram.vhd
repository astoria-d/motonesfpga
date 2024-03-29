-----------------------------------------------------
-----------------------------------------------------
-------------------- ram ---------------------------- 
-----------------------------------------------------
-----------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

----SRAM syncronous memory.
entity ram is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  
            clk              : in std_logic;
            ce_n, oe_n, we_n : in std_logic;   --select pin active low.
            addr             : in std_logic_vector (abus_size - 1 downto 0);
            d_io             : inout std_logic_vector (dbus_size - 1 downto 0)
        );
end ram;

architecture rtl of ram is

subtype ram_data is std_logic_vector (dbus_size -1 downto 0);
type ram_array is array (0 to 2**abus_size - 1) of ram_data;
--type ram_array is array (0 to 16#0800#) of ram_data;

---ram is initialized with 0.
signal work_ram : ram_array := (others => (others => '0'));

begin
    p_write : process (clk)
    begin
    if (rising_edge(clk)) then
        if (ce_n = '0' and we_n = '0') then
            work_ram(conv_integer(addr)) <= d_io;
        end if;
    end if;
    end process;

    p_read : process (clk)
    begin
    if (rising_edge(clk)) then
        if (ce_n= '0' and we_n = '1' and oe_n = '0') then
            d_io <= work_ram(conv_integer(addr));
        else
            d_io <= (others => 'Z');
        end if;
    end if;
    end process;
    
end rtl;

-----------------------------------------------------
-----------------------------------------------------
-------------------- tss ram ------------------------
-----------------------------------------------------
-----------------------------------------------------
----SRAM syncronous memory with tristate buffer.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

----SRAM syncronous memory.
entity tss_ram is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  
            clk              : in std_logic;
            ce_n, oe_n, we_n : in std_logic;   --select pin active low.
            addr             : in std_logic_vector (abus_size - 1 downto 0);
            d_io             : inout std_logic_vector (dbus_size - 1 downto 0)
        );
end tss_ram;

architecture rtl of tss_ram is

subtype ram_data is std_logic_vector (dbus_size -1 downto 0);
type ram_array is array (0 to 2**abus_size - 1) of ram_data;
--type ram_array is array (0 to 16#0800#) of ram_data;

---ram is initialized with 0.
signal work_ram : ram_array := (others => (others => '0'));

signal wk_d_io    : std_logic_vector (dbus_size - 1 downto 0);

begin
    p_write : process (clk)
    begin
    if (rising_edge(clk)) then
        if (ce_n = '0' and we_n = '0') then
            work_ram(conv_integer(addr)) <= d_io;
        end if;
    end if;
    end process;

    p_read : process (clk)
    begin
    if (rising_edge(clk)) then
        if (ce_n= '0' and we_n = '1' and oe_n = '0') then
            wk_d_io <= work_ram(conv_integer(addr));
        else
            wk_d_io <= (others => 'Z');
        end if;
    end if;
    end process;
    
    d_io <= wk_d_io when ce_n= '0' and we_n = '1' and oe_n = '0' else
            (others => 'Z');
end rtl;

-----------------------------------------------------
-----------------------------------------------------
-------------------- palette ram -------------------- 
-----------------------------------------------------
-----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity palette_ram is 
    generic (abus_size : integer := 16; dbus_size : integer := 8);
    port (  
            clk              : in std_logic;
            ce_n, oe_n, we_n : in std_logic;   --select pin active low.
            addr             : in std_logic_vector (abus_size - 1 downto 0);
            d_io             : inout std_logic_vector (dbus_size - 1 downto 0)
        );
end palette_ram;

architecture rtl of palette_ram is
component ram
    generic (abus_size : integer := 5; dbus_size : integer := 8);
    port (  
            clk               : in std_logic;
            ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
            addr              : in std_logic_vector (abus_size - 1 downto 0);
            d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
    );
end component;

signal plt_addr    : std_logic_vector (abus_size - 1 downto 0);
begin
    --palette ram is following characteristic.
    --Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C
    plt_addr <= "0" & addr(3 downto 0) when addr (4) = '1' and addr (1) = '0' and addr (0) = '0' else
                addr;
    palette_ram_inst : ram generic map (abus_size, dbus_size)
            port map (clk, ce_n, oe_n, we_n, plt_addr, d_io);

end rtl;
