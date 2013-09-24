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
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
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

