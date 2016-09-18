library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use std.textio.all;

entity prg_rom is 
    port (  
            pi_base_clk     : in std_logic;
            pi_ce_n         : in std_logic;
            pi_addr         : in std_logic_vector (14 downto 0);
            po_data         : out std_logic_vector (7 downto 0)
        );
end prg_rom;

architecture rtl of prg_rom is

--PROG ROM is 32k
subtype rom_data is std_logic_vector (7 downto 0);
type rom_array is array (0 to 2**15 - 1) of rom_data;

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
        return ret;
    end rom_fill;

--for GHDL environment
--itinialize with the rom_fill function.
--signal p_rom : rom_array := rom_fill;

--for Quartus II environment
signal p_rom : rom_array;
attribute ram_init_file : string;
attribute ram_init_file of p_rom : signal is "sample1-prg.hex";

begin
    
    p : process (pi_base_clk)
    begin
    if (rising_edge(pi_base_clk)) then
        if (pi_ce_n = '0') then
            po_data <= p_rom(conv_integer(pi_addr));
        else
            po_data <= (others => 'Z');
        end if;
    end if;
    end process;
end rtl;
