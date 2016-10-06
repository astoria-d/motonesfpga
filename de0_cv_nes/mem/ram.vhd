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
    generic (abus_size : integer := 16; dbus_size : integer := 8; debug_mem : string := "null-file.bin");
    port (
            pi_base_clk     : in std_logic;
            pi_ce_n         : in std_logic;
            pi_oe_n         : in std_logic;
            pi_we_n         : in std_logic;
            pi_addr         : in std_logic_vector (abus_size - 1 downto 0);
            pio_d_io        : inout std_logic_vector (dbus_size - 1 downto 0)
        );
end ram;

architecture rtl of ram is

subtype ram_data is std_logic_vector (dbus_size -1 downto 0);
type ram_array is array (0 to 2**abus_size - 1) of ram_data;

function ram_fill return ram_array is 
use ieee.std_logic_arith.conv_std_logic_vector;
type binary_file is file of character;
FILE bin_file : binary_file OPEN read_mode IS debug_mem;
variable read_data : character;
variable i : integer;
variable ret : ram_array;
begin
    if (debug_mem = "null-file.bin") then
        for i in ret'range loop
            ret(i) := (others => '0');
        end loop;
    else
        for i in ret'range loop
            read(bin_file, read_data);
            ret(i) :=
                conv_std_logic_vector(character'pos(read_data), 8);
        end loop;
    end if;
    return ret;
end ram_fill;


---ram is initialized with 0.
signal work_ram : ram_array := ram_fill;

begin
    p_write : process (pi_base_clk)
    begin
    if (rising_edge(pi_base_clk)) then
        if (pi_ce_n = '0' and pi_we_n = '0') then
            work_ram(conv_integer(pi_addr)) <= pio_d_io;
        end if;
    end if;
    end process;

    p_read : process (pi_base_clk)
    begin
    if (rising_edge(pi_base_clk)) then
        if (pi_ce_n= '0' and pi_we_n = '1' and pi_oe_n = '0') then
            pio_d_io <= work_ram(conv_integer(pi_addr));
        else
            pio_d_io <= (others => 'Z');
        end if;
    end if;
    end process;
    
end rtl;


-------------------------------------------------------
-------------------------------------------------------
---------------------- palette ram -------------------- 
-------------------------------------------------------
-------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity palette_ram is
    port (
            pi_base_clk     : in std_logic;
            pi_ce_n         : in std_logic;
            pi_oe_n         : in std_logic;
            pi_we_n         : in std_logic;
            pi_addr         : in std_logic_vector (4 downto 0);
            pio_d_io        : inout std_logic_vector (7 downto 0)
        );
end palette_ram;

architecture rtl of palette_ram is
component ram
    generic (abus_size : integer := 16; dbus_size : integer := 8; debug_mem : string := "null-file.bin");
    port (
            pi_base_clk     : in std_logic;
            pi_ce_n         : in std_logic;
            pi_oe_n         : in std_logic;
            pi_we_n         : in std_logic;
            pi_addr         : in std_logic_vector (abus_size - 1 downto 0);
            pio_d_io        : inout std_logic_vector (dbus_size - 1 downto 0)
        );
end component;

signal reg_plt_addr    : std_logic_vector (4 downto 0);

begin
    --palette ram is following characteristic.
    --Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C
    pl_addr_dec_p : process (pi_base_clk)
    begin
        if (rising_edge(pi_base_clk)) then
            if (pi_addr (4) = '1' and pi_addr (1) = '0' and pi_addr (0) = '0') then
                reg_plt_addr <= "0" & pi_addr(3 downto 0);
            else
                reg_plt_addr <= pi_addr;
            end if;
        end if;
    end process;
    
    palette_ram_inst : ram generic map (5, 8) port map (
            pi_base_clk,
            pi_ce_n,
            pi_oe_n,
            pi_we_n,
            reg_plt_addr,
            pio_d_io
            );

end rtl;
