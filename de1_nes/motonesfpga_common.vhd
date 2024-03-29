--  
--   MOTO NES FPGA Common Routines
--  

-------------------------------------------------------------
-------------------------------------------------------------
-------------------- package declaration --------------------
-------------------------------------------------------------
-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package motonesfpga_common is

procedure d_print(msg : string);

function conv_hex8(ival : integer) return string;

function conv_hex8(ival : std_logic_vector) return string;

function conv_hex16(ival : integer) return string;

function conv_hex16(ival : std_logic_vector) return string;

end motonesfpga_common;


-------------------------------------------------------------
-------------------------------------------------------------
----------------------- package body ------------------------
-------------------------------------------------------------
-------------------------------------------------------------

package body motonesfpga_common is

use ieee.std_logic_unsigned.conv_integer;

procedure d_print(msg : string) is
--use std.textio.all;
--use ieee.std_logic_textio.all;
--variable out_l : line;
begin
--    write(out_l, msg);
--    writeline(output, out_l);
end  procedure;

---ival : 0x0000 - 0xffff
function conv_hex8(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := (ival mod 16 ** 2) / 16 ** 1;
    tmp1 := ival mod 16 ** 1;
    return hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;

function conv_hex8(ival : std_logic_vector) return string is
begin
    return conv_hex8(conv_integer(ival));
end;

function conv_hex16(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := ival / 256;
    tmp1 := ival mod 256;
    return conv_hex8(tmp2) & conv_hex8(tmp1);
end;

function conv_hex16(ival : std_logic_vector) return string is
begin
    return conv_hex16(conv_integer(ival));
end;

end motonesfpga_common;

-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
------------------ other common modules ---------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------

----------------------------------------
--- d-flipflop with set/reset
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity d_flip_flop is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end d_flip_flop;

architecture rtl of d_flip_flop is
begin

    process (clk, res_n, set_n, d)
    begin
        if (res_n = '0') then
            q <= (others => '0');
        elsif (set_n = '0') then
            q <= d;
        elsif (rising_edge(clk)) then
            if (we_n = '0') then
                q <= d;
            end if;
        end if;
    end process;
end rtl;


--------- 1 bit d-flipflop.
library ieee;
use ieee.std_logic_1164.all;

entity d_flip_flop_bit is 
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic;
            q       : out std_logic
        );
end d_flip_flop_bit;

architecture rtl of d_flip_flop_bit is
begin

    process (clk, res_n, set_n, d)
    begin
        if (res_n = '0') then
            q <= '0';
        elsif (set_n = '0') then
            q <= d;
        elsif (rising_edge(clk)) then
            if (we_n = '0') then
                q <= d;
            end if;
        end if;
    end process;
end rtl;

----------------------------------------
--- tri-state buffer
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tri_state_buffer is 
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end tri_state_buffer;

architecture rtl of tri_state_buffer is
begin
    q <= d when oe_n = '0' else
        (others => 'Z');
end rtl;

-------------------------------
------ count up registers -----
-------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity counter_register is 
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
end counter_register;

architecture rtl of counter_register is

use ieee.std_logic_unsigned.all;


begin
        
    clk_p : process (clk, rst_n)
    variable q_out : std_logic_vector(dsize - 1 downto 0);
    begin
        if (rst_n = '0') then
            q_out := (others => '0');
        elsif (rising_edge(clk)) then
            if (we_n = '0') then
                q_out := d;
            elsif (ce_n = '0') then
                q_out := q_out + inc;
            end if;
        end if;
        
        --output data...
        q <= q_out;
    end process;

end rtl;

