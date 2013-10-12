library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dummy_ppu is 
    port (  ppu_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : buffer std_logic_vector (8 downto 0);
            pos_y       : buffer std_logic_vector (8 downto 0);
            nes_r       : buffer std_logic_vector (3 downto 0);
            nes_g       : buffer std_logic_vector (3 downto 0);
            nes_b       : buffer std_logic_vector (3 downto 0)
    );
end dummy_ppu;


architecture rtl of dummy_ppu is

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

signal x_res_n, y_res_n, y_en_n : std_logic;
signal cnt_clk : std_logic;
signal frame_en_n : std_logic;


signal frame_cnt : std_logic_vector(7 downto 0);

begin

    cnt_clk <= not ppu_clk;
    x_inst : counter_register generic map (9, 1)
            port map (cnt_clk , x_res_n, '0', '1', (others => '0'), pos_x);
    y_inst : counter_register generic map (9, 1)
            port map (cnt_clk , y_res_n, y_en_n, '1', (others => '0'), pos_y);

    frame_cnt_inst : counter_register generic map (8, 1)
            port map (cnt_clk , rst_n, frame_en_n, '1', (others => '0'), frame_cnt);

    
    p_write : process (rst_n, ppu_clk)
    begin
        if (rst_n = '0') then
            x_res_n <= '0';
            y_res_n <= '0';
            frame_en_n <= '1';
            nes_r <= (others => '0');
            nes_g <= (others => '0');
            nes_b <= (others => '0');
        elsif (rising_edge(ppu_clk)) then
            --xmax = 340
            if (pos_x = "101010100") then
                x_res_n <= '0';
                y_en_n <= '0';
                --ymax=261
                if (pos_y = "100000101") then
                    y_res_n <= '0';
                    frame_en_n <= '0';
                    nes_r <= nes_r + '1';
                    nes_g <= nes_g + '1';
                    nes_b <= nes_b + '1';
                else
                    frame_en_n <= '1';
                    y_res_n <= '1';
                end if;
            else
                frame_en_n <= '1';
                x_res_n <= '1';
                y_en_n <= '1';
                y_res_n <= '1';
            end if;
        end if;
    end process;
end rtl;



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use work.motonesfpga_common.all;

entity vga_ctl is 
    port (  ppu_clk     : in std_logic;
            vga_clk     : in std_logic;
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

constant VGA_W    : integer := 640;
constant VGA_H    : integer := 480;
constant VGA_W_MAX    : integer := 800;
constant VGA_H_MAX    : integer := 525;
constant H_SP    : integer := 95;
constant H_BP    : integer := 48;
constant H_FP    : integer := 15;

constant V_SP    : integer := 2;
constant V_BP    : integer := 33;
constant V_FP    : integer := 10;

signal vga_x       :  std_logic_vector (9 downto 0);
signal vga_y       :  std_logic_vector (9 downto 0);
signal x_res_n, y_res_n, y_en_n : std_logic;
signal cnt_clk : std_logic;

begin

--    ppu_clk_p : process (rst_n, ppu_clk)
--    begin
--        if (rst_n = '0') then
--            h_sync_n <= '1';
--            v_sync_n <= '1';
--        elsif (rising_edge(ppu_clk)) then
--
--            --sync signal assert.
--            if (pos_x >= conv_std_logic_vector((VGA_W + H_FP) * 341/800, 9) and 
--                    pos_x < conv_std_logic_vector((VGA_W + H_FP + H_SP) * 341/800, 9)) then
--                h_sync_n <= '0';
--
--                --d_print("vga_ctl: h_sync.");
--            else
--                h_sync_n <= '1';
--            end if;
--
--            if (pos_y >= conv_std_logic_vector((VGA_H + V_FP) * 262/525, 9) and 
--                    pos_y < conv_std_logic_vector((VGA_H + V_FP + V_SP) * 262/525, 9)) then
--                v_sync_n <= '0';
--
--                --d_print("vga_ctl: v_sync.");
--            else
--                v_sync_n <= '1';
--            end if;
--        end if;
--    end process;

    cnt_clk <= not vga_clk;
    x_inst : counter_register generic map (10, 1)
            port map (cnt_clk , x_res_n, '0', '1', (others => '0'), vga_x);
    y_inst : counter_register generic map (10, 1)
            port map (cnt_clk , y_res_n, y_en_n, '1', (others => '0'), vga_y);

    
    p_vga : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            h_sync_n <= '0';
            v_sync_n <= '0';
            x_res_n <= '0';
            y_res_n <= '0';
            r<=(others => '0');
            g<=(others => '0');
            b<=(others => '0');
        elsif (rising_edge(vga_clk)) then
            --xmax = 799
            if (vga_x = "1100011111") then
                x_res_n <= '0';
                y_en_n <= '0';
                --ymax=524
                if (vga_y = "1000001100") then
                    y_res_n <= '0';
                else
                    y_res_n <= '1';
                end if;
            else
                x_res_n <= '1';
                y_en_n <= '1';
                y_res_n <= '1';
            end if;
            
            --sync signal assert.
            if (vga_x >= conv_std_logic_vector(VGA_W + H_FP, 10) and 
                vga_x < conv_std_logic_vector(VGA_W + H_FP + H_SP , 10)) then
                h_sync_n <= '0';
            else
                h_sync_n <= '1';
            end if;

            if (vga_y >= conv_std_logic_vector(VGA_H + V_FP, 10) and 
                vga_y < conv_std_logic_vector(VGA_H + V_FP + V_SP, 10)) then
                v_sync_n <= '0';
            else
                v_sync_n <= '1';
            end if;


            if (vga_y <=conv_std_logic_vector(VGA_H, 10)) then
                if (vga_x < conv_std_logic_vector(VGA_W, 10)) then
--                    r<=nes_r;
--                    g<=nes_g;
--                    b<=nes_b;
                    r<=(others => '1');
                    g<=(others => '1');
                    b<=(others => '1');
                else
                    r<=(others => '0');
                    g<=(others => '0');
                    b<=(others => '0');
                end if;
            else
                r<=(others => '0');
                g<=(others => '0');
                b<=(others => '0');
            end if;
    
    
            
            
        end if;
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
use work.motonesfpga_common.all;

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
--use std.textio.all;
--use ieee.std_logic_textio.all;
--variable out_l : line;
--file vga_file: TEXT open write_mode is "vga-port";
begin
--    write(out_l, msg);
--    writeline(vga_file, out_l);
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
            --d_print("vga_device: ****");
        else
            if (vga_clk'event and vga_clk = '1') then
                if ( x < VGA_W and y < VGA_H) then
                    --d_print(conv_color_hex(r, g, b));
                    write_vga_pipe(conv_color_hex(b, g, r));
                    --write_vga_pipe("0" & conv_hex8(x));
                    --d_print("vga_device: rgb out x:" & conv_hex16(x));
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
                --d_print("vga_device: h_sync");
                write_vga_pipe("---");
                x := VGA_W + H_FP + 1;
            end if;
            if (v_sync_n'event and v_sync_n = '0') then
                --d_print("vga_device: v_sync");
                write_vga_pipe("___");
                y := VGA_H + V_FP + 1;
            end if;
        end if;
    end process;

end rtl;

