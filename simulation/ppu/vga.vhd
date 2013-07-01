library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;

entity vga_ctl is 
    port (  vga_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : in std_logic_vector (8 downto 0);
            pos_y       : in std_logic_vector (8 downto 0);
            nes_r       : in std_logic_vector (3 downto 0);
            nes_g       : in std_logic_vector (3 downto 0);
            nes_b       : in std_logic_vector (3 downto 0);
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)
    );
end vga_ctl;

architecture rtl of vga_ctl is

component counter_register
    generic (
        dsize       : integer := 8
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            set_n       : in std_logic;
            ce_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

function conv_hex8(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := (ival mod 16 ** 2) / 16 ** 1;
    tmp1 := ival mod 16 ** 1;
    return hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;

function conv_hex16(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := ival / 256;
    tmp1 := ival mod 256;
    return conv_hex8(tmp2) & conv_hex8(tmp1);
end;

constant COLOR_SIZE         : integer := 12;
constant VGA_SIZE           : integer := 10;

constant VGA_W    : integer := 640;
constant VGA_H    : integer := 480;
constant VGA_W_MAX    : integer := 800;
constant VGA_H_MAX    : integer := 525;
constant H_FP    : integer := 16;
constant H_SP    : integer := 96;
constant H_BP    : integer := 48;
constant V_FP    : integer := 10;
constant V_SP    : integer := 2;
constant V_BP    : integer := 33;

subtype bit_data is std_logic_vector (COLOR_SIZE -1 downto 0);
type bit_array is array (0 to 256*256 - 1) of bit_data;
signal nes_screen : bit_array := (others => (others => '0'));

signal vga_x_en_n    : std_logic;
signal vga_x_res_n   : std_logic;
signal vga_y_en_n    : std_logic;
signal vga_y_res_n   : std_logic;
signal vga_x         : std_logic_vector(VGA_SIZE - 1 downto 0);
signal vga_y         : std_logic_vector(VGA_SIZE - 1 downto 0);

begin

    p_write : process (pos_x, pos_y)
    begin
        --draw pixel on the virtual screen only when x,y is in the screen pos.
        if (pos_x(8) = '0' and pos_y(8) = '0') then
            nes_screen(conv_integer(pos_x(7 downto 0) & pos_y(7 downto 0))) <= 
                nes_r & nes_g & nes_b;
        end if;
    end process;

    vga_x_en_n <= '0';
    vga_x_inst : counter_register generic map (VGA_SIZE)
            port map (vga_clk, vga_x_res_n, '1', vga_x_en_n, (others => '0'), vga_x);
    ---test dummy value...
    vga_y_inst : counter_register generic map (VGA_SIZE)
            port map (vga_clk, vga_y_res_n, rst_n, vga_y_en_n, 
                        conv_std_logic_vector(VGA_H - 2, VGA_SIZE), vga_y);

    p_vga_out : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            vga_x_res_n <= '0';
            --for dummy init value set.
            --vga_y_res_n <= '0';
            vga_y_res_n <= '1';
        else
            if (vga_clk'event) then
                --x pos reset.
                if (vga_clk = '1' and 
                        vga_x = conv_std_logic_vector(VGA_W_MAX - 1, VGA_SIZE)) then
                    vga_x_res_n <= '0';

                    --y pos reset.
                    if (vga_y = conv_std_logic_vector(VGA_H_MAX - 1, VGA_SIZE)) then
                        vga_y_res_n <= '0';
                    else
                        vga_y_res_n <= '1';
                    end if;
                else
                    vga_x_res_n <= '1';
                    vga_y_res_n <= '1';
                end if;
            end if; --if (vga_clk'event) then

            if (vga_clk'event and vga_clk = '0') then
                d_print("c");

                --y pos increment.
                if (vga_x = conv_std_logic_vector(VGA_W_MAX - 1, VGA_SIZE)) then
                    vga_y_en_n <= '0';
                else
                    vga_y_en_n <= '1';
                end if;
            end if; --if (vga_clk'event) then

            if (vga_clk'event and vga_clk = '1') then
                if (vga_x < conv_std_logic_vector(VGA_W, VGA_SIZE) and 
                    vga_y < conv_std_logic_vector(VGA_H, VGA_SIZE)) then

                    d_print("vga_ctl: rgb out. x:" & conv_hex16(conv_integer(vga_x)));

                    r <= nes_screen(conv_integer(
                                vga_x(7 downto 0) & vga_y(7 downto 0)))(11 downto 8);
                    g <= nes_screen(conv_integer(
                                vga_x(7 downto 0) & vga_y(7 downto 0)))(7 downto 4);
                    b <= nes_screen(conv_integer(
                                vga_x(7 downto 0) & vga_y(7 downto 0)))(3 downto 0);
                else
                    r <= (others => '0');
                    g <= (others => '0');
                    b <= (others => '0');
                end if;

                --sync signal assert.
                if (vga_x >= conv_std_logic_vector(VGA_W + H_FP, VGA_SIZE) and 
                    vga_x < conv_std_logic_vector(VGA_W + H_FP + H_SP, VGA_SIZE)) then
                    h_sync_n <= '0';

                    d_print("vga_ctl: h_sync.");
                else
                    h_sync_n <= '1';
                end if;

                if (vga_y >= conv_std_logic_vector(VGA_H + V_FP, VGA_SIZE) and 
                    vga_y < conv_std_logic_vector(VGA_H + V_FP + V_SP, VGA_SIZE)) then
                    v_sync_n <= '0';

                    d_print("vga_ctl: v_sync.");
                else
                    v_sync_n <= '1';
                end if;
            end if; --if (vga_clk'event and vga_clk = '1') then

        end if;--if (rst_n = '0') then
    end process;
end rtl;




-------------------------------------------------------
-------------------------------------------------------
-----------  dummy vga outpu device. ------------------
-------------------------------------------------------
-------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

entity vga_device is 
    port (  vga_clk     : in std_logic;
            rst_n       : in std_logic;
            h_sync_n    : in std_logic;
            v_sync_n    : in std_logic;
            r           : in std_logic_vector(3 downto 0);
            g           : in std_logic_vector(3 downto 0);
            b           : in std_logic_vector(3 downto 0)
            );
end vga_device;

architecture rtl of vga_device is

constant VGA_W    : integer := 640;
constant VGA_H    : integer := 480;
constant VGA_W_MAX    : integer := 800;
constant VGA_H_MAX    : integer := 525;
constant H_FP    : integer := 16;
constant H_SP    : integer := 96;
constant H_BP    : integer := 48;
constant V_FP    : integer := 10;
constant V_SP    : integer := 2;
constant V_BP    : integer := 33;

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

function conv_hex8(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := (ival mod 16 ** 2) / 16 ** 1;
    tmp1 := ival mod 16 ** 1;
    return hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;

function conv_hex16(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := ival / 256;
    tmp1 := ival mod 256;
    return conv_hex8(tmp2) & conv_hex8(tmp1);
end;

function conv_color_hex (
            r           : in std_logic_vector(3 downto 0);
            g           : in std_logic_vector(3 downto 0);
            b           : in std_logic_vector(3 downto 0)
        ) return string is
variable tmp1, tmp2, tmp3 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp1 := conv_integer(r);
    tmp2 := conv_integer(g);
    tmp3 := conv_integer(b);
    return  hex_chr(tmp3 + 1) & hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;

procedure write_vga_pipe(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
file vga_file: TEXT open write_mode is "vga-port";
begin
    write(out_l, msg);
    writeline(vga_file, out_l);
    --d_print("pipe: " & msg);
end  procedure;


---ival : 0x0000 - 0xffff
begin

    clk_p : process (rst_n, vga_clk, h_sync_n, v_sync_n)
    variable x, y : integer;

    begin
        if (rst_n = '0') then
            x := 0;
            y := 0;
            d_print("vga_device: ****");
        else
            if (vga_clk'event and vga_clk = '1') then
                if ( x < VGA_W and y < VGA_H) then
                    --d_print(conv_color_hex(r, g, b));
                    write_vga_pipe(conv_color_hex(r, g, b));
                    --write_vga_pipe("0" & conv_hex8(x));
                    d_print("vga_device: rgb out x:" & conv_hex16(x));
                end if;

                if (x = VGA_W_MAX - 1) then
                    x := 0;
                    y := y + 1;
                else
                    x := x + 1;
                end if;

                if (y = VGA_H_MAX - 1) then
                    y := 0;
                end if;
            end if;

            if (h_sync_n'event and h_sync_n = '0') then
                d_print("vga_device: h_sync");
                write_vga_pipe("---");
                x := VGA_W + H_FP + 1;
            end if;
            if (v_sync_n'event and v_sync_n = '0') then
                d_print("vga_device: v_sync");
                write_vga_pipe("___");
                y := VGA_H + V_FP + 1;
            end if;
        end if;
    end process;

end rtl;

