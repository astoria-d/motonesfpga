library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use std.textio.all;
use work.motonesfpga_common.all;

--asyncronous rom
entity prg_rom is 
    generic (abus_size : integer := 15; dbus_size : integer := 8);
    port (
            clk             : in std_logic;
            ce_n            : in std_logic;     --active low.
            addr            : in std_logic_vector (abus_size - 1 downto 0);
            data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
end prg_rom;

architecture rtl of prg_rom is

--32k ROM
subtype rom_data is std_logic_vector (dbus_size -1 downto 0);
type rom_array is array (0 to 2**abus_size - 1) of rom_data;

--not used...
constant ROM_TACE : time := 100 ns;      --output enable access time
constant ROM_TOH : time := 10 ns;      --output hold time

--function is called only once at the array initialize.
function rom_fill return rom_array is 
    type binary_file is file of character;
    FILE nes_file : binary_file OPEN read_mode IS "rom-file.nes" ;
    variable read_data : character;
    variable i : integer;
    variable ret : rom_array;
    begin
        --skip first 16 bit data(NES cardridge header part.)
        for i in 0 to 15 loop
            read(nes_file, read_data);
        end loop;

        for i in ret'range loop
            read(nes_file, read_data);
            ret(i) :=
                conv_std_logic_vector(character'pos(read_data), 8);
        end loop;
        d_print("file load success.");
        return ret;
    end rom_fill;

function init_rom
    return rom_array is 
    variable tmp : rom_array := (others => (others => '0'));
    use ieee.numeric_std.to_unsigned;
begin 
    for addr_pos in 0 to 2**abus_size - 1 loop 
        -- Initialize each address with the address itself
        tmp(addr_pos) := std_logic_vector(to_unsigned(addr_pos, dbus_size));
    end loop;
    return tmp;
end init_rom;

-- Declare the ROM signal and specify a default value.	Quartus II
-- will create a memory initialization file (.mif) based on the 
-- default value.

--itinialize with the rom_fill function.
signal p_rom : rom_array := rom_fill;

--signal p_rom : rom_array := init_rom;
--attribute ram_init_file : string;
--attribute ram_init_file of p_rom : signal is "sample1-prg.hex";

begin

    p : process (ce_n, addr)
    begin
    if(rising_edge(clk)) then
    if (ce_n = '0') then
        data <= p_rom(conv_integer(addr));
    else
        data <= (others => 'Z');
    end if;
    end if;
    end process;
end rtl;







-- Quartus II VHDL Template
-- Single-Port ROM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_port_rom is

    generic 
    (
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 8
    );

    port 
    (
        clk		: in std_logic;
        ce		: in std_logic;
        addr            : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
        q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
    );

end entity;

architecture rtl of single_port_rom is

    -- Build a 2-D array type for the RoM
    subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
    type memory_t is array(2**ADDR_WIDTH-1 downto 0) of word_t;

    signal rom : memory_t;

attribute ram_init_file : string;
attribute ram_init_file of rom:
signal is "sample1-prg.hex";
    
    begin

    process(clk)
use ieee.std_logic_unsigned.conv_integer;
    begin
    if(rising_edge(clk)) then
        if (ce = '0') then
        q <= rom(conv_integer(addr));
        else
            q <= (others => 'Z');
        end if;
    end if;
    end process;

end rtl;

