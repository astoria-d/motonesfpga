library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
--use std.textio.all;

----SRAM asyncronous memory.
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

constant RAM_TAOE : time := 25 ns;      --OE access time
constant RAM_TOH : time := 10 ns;       --write data hold time

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

-----------------------------------------------------
-----------------------------------------------------
--------------- ram timing adjuster -----------------
-----------------------------------------------------
-----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity ram_ctrl is 
    generic (wr_en_timing : integer);
    port (  
            clk              : in std_logic;
            ce_n, oe_n, we_n : in std_logic;
            sync_ce_n        : out std_logic
        );
end ram_ctrl;

architecture rtl of ram_ctrl is
component counter_register
    generic (
        dsize       : integer := 8;
        inc         : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

signal cnt_clk      : std_logic;
signal cnt_rst_n    : std_logic;
signal clk_cnt      : std_logic_vector(5 downto 0);

--cpu clock = base clock / 24 = 2.08 MHz (480 ns / cycle)
--ppu clock = base clock / 8
--vga clock = base clock / 2
--mem clock = base clock

begin

    cnt_clk <= not clk;
    cnt_rst_n <= '1' when ce_n = '0' and we_n = '0' else
                 '0';
--counter grows at most 0 .to 23
--counter width=6 is enough.
    counter_inst : counter_register generic map (6, 1)
            port map (cnt_clk, cnt_rst_n, '0', '1', (others => '0'), clk_cnt);

    sync_ce_n <= '0' when ce_n = '0' and oe_n = '0' and we_n = '1' else
                 '0' when ce_n = '0' and oe_n = '1' and we_n = '0' and clk_cnt = conv_std_logic_vector(wr_en_timing, 6) else
                 '1';

end rtl;

