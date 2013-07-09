library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;

entity ppu_render is 
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            vblank_n    : out std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);
            pos_x       : out std_logic_vector (8 downto 0);
            pos_y       : out std_logic_vector (8 downto 0);
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0);
            ppu_ctrl        : in std_logic_vector (7 downto 0);
            ppu_mask        : in std_logic_vector (7 downto 0);
            ppu_status      : out std_logic_vector (7 downto 0);
            ppu_scroll_x    : in std_logic_vector (7 downto 0);
            ppu_scroll_y    : in std_logic_vector (7 downto 0);
            r_nw            : in std_logic;
            oam_bus_ce_n    : in std_logic;
            oam_addr        : in std_logic_vector (7 downto 0);
            oam_data        : inout std_logic_vector (7 downto 0);
            plt_bus_ce_n    : in std_logic;
            plt_addr        : in std_logic_vector (4 downto 0);
            plt_data        : inout std_logic_vector (5 downto 0)
    );
end ppu_render;

architecture rtl of ppu_render is

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

component shift_register
    generic (
        dsize : integer := 8;
        shift : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : buffer std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

component d_flip_flop
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
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
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

constant X_SIZE       : integer := 9;
constant dsize        : integer := 8;
constant asize        : integer := 14;
constant HSCAN_MAX    : integer := 341;
constant VSCAN_MAX    : integer := 262;
constant HSCAN        : integer := 256;
constant VSCAN        : integer := 240;
constant HSCAN_NEXT_START    : integer := 320;
constant HSCAN_NEXT_EXTRA    : integer := 336;


constant PPUBNA    : integer := 1;  --base name address
constant PPUVAI    : integer := 2;  --vram address increment
constant PPUSPA    : integer := 3;  --sprite pattern table address
constant PPUBPA    : integer := 4;  --background pattern table address
constant PPUSPS    : integer := 5;  --sprite size
constant PPUMS     : integer := 6;  --ppu master/slave
constant PPUNEN    : integer := 7;  --nmi enable

constant PPUGS     : integer := 0;  --grayscale
constant PPUSBL    : integer := 1;  --show 8 left most bg pixel
constant PPUSSL    : integer := 2;  --show 8 left most sprite pixel
constant PPUSBG    : integer := 3;  --show bg
constant PPUSSP    : integer := 4;  --show sprie
constant PPUIR     : integer := 5;  --intensify red
constant PPUIG     : integer := 6;  --intensify green
constant PPUIB     : integer := 7;  --intensify blue

subtype palette_data    is std_logic_vector (dsize -1 downto 0);
type palette_array      is array (0 to 15) of palette_data;
signal bg_palatte       : palette_array := (others => (others => '0'));
signal sprite_palatte   : palette_array := (others => (others => '0'));

subtype nes_color_data  is std_logic_vector (11 downto 0);
type nes_color_array    is array (0 to 63) of nes_color_data;
--ref: http://hlc6502.web.fc2.com/NesPal2.htm
constant nes_color_palette : nes_color_array := (
        conv_std_logic_vector(16#777#, 12), 
        conv_std_logic_vector(16#20b#, 12), 
        conv_std_logic_vector(16#20b#, 12), 
        conv_std_logic_vector(16#61a#, 12), 
        conv_std_logic_vector(16#927#, 12), 
        conv_std_logic_vector(16#b13#, 12), 
        conv_std_logic_vector(16#a30#, 12), 
        conv_std_logic_vector(16#740#, 12), 
        conv_std_logic_vector(16#450#, 12), 
        conv_std_logic_vector(16#360#, 12), 
        conv_std_logic_vector(16#360#, 12), 
        conv_std_logic_vector(16#364#, 12), 
        conv_std_logic_vector(16#358#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12),
        conv_std_logic_vector(16#bbb#, 12), 
        conv_std_logic_vector(16#46f#, 12), 
        conv_std_logic_vector(16#44f#, 12), 
        conv_std_logic_vector(16#94f#, 12), 
        conv_std_logic_vector(16#d4c#, 12), 
        conv_std_logic_vector(16#d46#, 12), 
        conv_std_logic_vector(16#e50#, 12), 
        conv_std_logic_vector(16#c70#, 12), 
        conv_std_logic_vector(16#880#, 12), 
        conv_std_logic_vector(16#5a0#, 12), 
        conv_std_logic_vector(16#4a1#, 12), 
        conv_std_logic_vector(16#4a6#, 12), 
        conv_std_logic_vector(16#49c#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12),
        conv_std_logic_vector(16#fff#, 12), 
        conv_std_logic_vector(16#6af#, 12), 
        conv_std_logic_vector(16#58f#, 12), 
        conv_std_logic_vector(16#a7f#, 12), 
        conv_std_logic_vector(16#f6f#, 12), 
        conv_std_logic_vector(16#f6b#, 12), 
        conv_std_logic_vector(16#f73#, 12), 
        conv_std_logic_vector(16#fa0#, 12), 
        conv_std_logic_vector(16#ed2#, 12), 
        conv_std_logic_vector(16#9e0#, 12), 
        conv_std_logic_vector(16#7f4#, 12), 
        conv_std_logic_vector(16#7e9#, 12), 
        conv_std_logic_vector(16#6de#, 12), 
        conv_std_logic_vector(16#777#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12),
        conv_std_logic_vector(16#fff#, 12), 
        conv_std_logic_vector(16#9df#, 12), 
        conv_std_logic_vector(16#abf#, 12), 
        conv_std_logic_vector(16#cbf#, 12), 
        conv_std_logic_vector(16#ebf#, 12), 
        conv_std_logic_vector(16#fbe#, 12), 
        conv_std_logic_vector(16#fcb#, 12), 
        conv_std_logic_vector(16#fda#, 12), 
        conv_std_logic_vector(16#ff9#, 12), 
        conv_std_logic_vector(16#cf8#, 12), 
        conv_std_logic_vector(16#afa#, 12), 
        conv_std_logic_vector(16#afc#, 12), 
        conv_std_logic_vector(16#aff#, 12), 
        conv_std_logic_vector(16#aaa#, 12), 
        conv_std_logic_vector(16#000#, 12), 
        conv_std_logic_vector(16#000#, 12)
        );

signal rst              : std_logic;
signal clk_n            : std_logic;

signal io_cnt           : std_logic_vector(0 downto 0);
signal io_oe_n          : std_logic;
signal d_oe_n           : std_logic;

signal cnt_x_en_n    : std_logic;
signal cnt_x_res_n   : std_logic;
signal cnt_y_en_n    : std_logic;
signal cnt_y_res_n   : std_logic;

signal cur_x            : std_logic_vector(X_SIZE - 1 downto 0);
signal cur_y            : std_logic_vector(X_SIZE - 1 downto 0);
signal next_x           : std_logic_vector(X_SIZE - 1 downto 0);
signal next_y           : std_logic_vector(X_SIZE - 1 downto 0);

signal nt_next_we_n     : std_logic;
signal nt_val           : std_logic_vector (dsize - 1 downto 0);
signal nt_next_val      : std_logic_vector (dsize - 1 downto 0);

signal attr_ce_n        : std_logic;
signal attr_we_n        : std_logic;
signal attr_in          : std_logic_vector (dsize - 1 downto 0);
signal attr_val         : std_logic_vector (dsize - 1 downto 0);
signal disp_attr_we_n   : std_logic;
signal disp_attr        : std_logic_vector (dsize - 1 downto 0);

signal ptn_en_n         : std_logic;

signal ptn_l_we_n       : std_logic;
signal ptn_l_in         : std_logic_vector (dsize - 1 downto 0);
signal ptn_l_in_rev     : std_logic_vector (dsize - 1 downto 0);
signal ptn_l_val        : std_logic_vector (dsize - 1 downto 0);
signal disp_ptn_l_in    : std_logic_vector (dsize * 2 - 1 downto 0);
signal disp_ptn_l       : std_logic_vector (dsize * 2 - 1 downto 0);

signal ptn_h_we_n       : std_logic;
signal ptn_h_in         : std_logic_vector (dsize * 2 - 1 downto 0);
signal ptn_h_in_rev     : std_logic_vector (dsize * 2 - 1 downto 0);
signal disp_ptn_h       : std_logic_vector (dsize * 2 - 1 downto 0);

signal vram_addr        : std_logic_vector (asize - 1 downto 0);

begin

    rst <= not rst_n;
    clk_n <= not clk;

    cnt_x_en_n <= '0';

    ale <= io_cnt(0) when ppu_mask(PPUSBG) = '1'    else 'Z';
    rd_n <= io_cnt(0) when ppu_mask(PPUSBG) = '1'   else 'Z';
    wr_n <= '1' when ppu_mask(PPUSBG) = '1'         else 'Z';
    io_oe_n <= not io_cnt(0) when ppu_mask(PPUSBG) = '1' else '1';
    d_oe_n <= '0' when ppu_mask(PPUSBG) = '1'       else '1';

    io_cnt_inst : counter_register generic map (1)
            port map (clk, cnt_x_res_n, '1', '0', (others => '0'), io_cnt);

    ---x pos is 8 cycle ahead of current pos.
    next_x <= cur_x + "000010000" 
                    when cur_x <  conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE) else
              cur_x + "011000000";
    next_y <= cur_y 
                    when cur_x <  conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE) else
              "000000000" 
                    when cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE) else
              cur_y + "000000001";

    --current x,y pos
    cur_x_inst : counter_register generic map (X_SIZE)
            port map (clk_n, cnt_x_res_n, '1', 
                    cnt_x_en_n, (others => '0'), cur_x);
    cur_y_inst : counter_register generic map (X_SIZE)
            port map (clk_n, cnt_y_res_n, '1', 
                    cnt_y_en_n, (others => '0'), cur_y);

    nt_next_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', nt_next_we_n, vram_ad, nt_next_val);
    nt_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', nt_next_we_n, nt_next_val, nt_val);

    attr_in <= vram_ad;
    at_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', attr_we_n, attr_in, attr_val);

    disp_at_inst : shift_register generic map(dsize, 2)
            port map (clk_n, rst_n, attr_ce_n, disp_attr_we_n, attr_val, disp_attr);

    --chr rom data's bit is stored in opposite direction.
    --reverse bit when loading...
    ptn_l_in_rev <= vram_ad;
    ptn_h_in_rev <= vram_ad & disp_ptn_h (dsize downto 1);
    bit_rev: for cnt in 0 to 7 generate
        ptn_l_in(dsize - 1 - cnt) <= ptn_l_in_rev(cnt);
        ptn_h_in(dsize * 2 - 1 - cnt) <= ptn_h_in_rev(dsize + cnt);
    end generate;
    ptn_h_in(dsize - 1 downto 0) <= ptn_h_in_rev(dsize - 1 downto 0);

    ptn_en_n <= '0' when cur_x < conv_std_logic_vector(HSCAN_NEXT_EXTRA, X_SIZE) else
                '1';

    ptn_l_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ptn_l_we_n, ptn_l_in, ptn_l_val);

    disp_ptn_l_in <= ptn_l_val & disp_ptn_l (dsize downto 1);
    disp_ptn_l_inst : shift_register generic map(dsize * 2, 1)
            port map (clk_n, rst_n, ptn_en_n, ptn_h_we_n, disp_ptn_l_in, disp_ptn_l);

    ptn_h_inst : shift_register generic map(dsize * 2, 1)
            port map (clk_n, rst_n, ptn_en_n, ptn_h_we_n, ptn_h_in, disp_ptn_h);

    vram_io_buf : tri_state_buffer generic map (dsize)
            port map (io_oe_n, vram_addr(dsize - 1 downto 0), vram_ad);

    vram_a_buf : tri_state_buffer generic map (6)
            port map (d_oe_n, vram_addr(asize - 1 downto dsize), vram_a);

    pos_x <= cur_x;
    pos_y <= cur_y;

    clk_p : process (rst_n, clk) 

procedure output_bg_rgb is
variable plt_addr : integer;
variable palette_index : integer;
begin
    --firs color in the palette is transparent color.
    if ((disp_ptn_h(0) or disp_ptn_l(0)) = '1') then
        if (cur_y(4) = '0') then
            plt_addr := conv_integer(
                        disp_attr(1 downto 0) & disp_ptn_h(0) & disp_ptn_l(0));
        else
            plt_addr := conv_integer(
                        disp_attr(5 downto 4) & disp_ptn_h(0) & disp_ptn_l(0));
        end if;
        --plt_addr := conv_integer("00" & disp_ptn_h(0) & disp_ptn_l(0));
        palette_index := conv_integer(bg_palatte(plt_addr));

        d_print("output_bg_rgb");
        d_print("plt_addr:" & conv_hex8(plt_addr));
        d_print("palette_index:" & conv_hex8(palette_index));

        b <= nes_color_palette(palette_index) (11 downto 8);
        g <= nes_color_palette(palette_index) (7 downto 4);
        r <= nes_color_palette(palette_index) (3 downto 0);

--        d_print("pht h:" & conv_hex8(disp_ptn_h));
--        d_print("pht l:" & conv_hex8(disp_ptn_h));
        d_print("rgb:" &
            conv_hex16(nes_color_palette(palette_index)));
    else
        b <= (others => '1');
        g <= (others => '1');
        r <= (others => '1');
    end if; --if ((disp_ptn_h(0) or disp_ptn_h(0)) = '1') then
end;

    begin
        if (rst_n = '0') then
            cnt_x_res_n <= '0';
            cnt_y_res_n <= '0';
            nt_next_we_n <= '1';

            b <= (others => '0');
            g <= (others => '0');
            r <= (others => '0');
        else
            if (clk'event) then
                --x pos reset.
                if (clk = '0' and 
                        cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                    cnt_x_res_n <= '0';

                    --y pos reset.
                    if (cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) then
                        cnt_y_res_n <= '0';
                    else
                        cnt_y_res_n <= '1';
                    end if;
                else
                    cnt_x_res_n <= '1';
                    cnt_y_res_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '1') then
                --y pos increment.
                if (cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                    cnt_y_en_n <= '0';
                else
                    cnt_y_en_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '0') then
                d_print("-");
            end if;

            --fetch bg pattern and display.
            if (clk'event and clk = '1') then
                if (ppu_mask(PPUSBG) = '1') then
                    d_print("*");

                    --visible area and last pixel for the next first pixel.
                    if (cur_x <= conv_std_logic_vector(HSCAN, X_SIZE) or 
                            (cur_x > conv_std_logic_vector(HSCAN_NEXT_START, X_SIZE) and 
                             cur_x < conv_std_logic_vector(HSCAN_NEXT_EXTRA, X_SIZE) )) 
                        then

                        ----fetch next tile byte.
                        if (cur_x (2 downto 0) = "001" ) then
                            --vram addr is incremented every 8 cycle.
                            --name table at 0x2000
                            vram_addr(9 downto 0) 
                                <= next_y(dsize - 1 downto 3) 
                                    & next_x(dsize - 1 downto 3);
                            vram_addr(asize - 1 downto 10) <= "10" & ppu_ctrl(PPUBNA downto 0);
                        end if;
                        if (cur_x (2 downto 0) = "010" ) then
                            nt_next_we_n <= '0';
                        else
                            nt_next_we_n <= '1';
                        end if;

                        ----fetch attr table byte.
                        if (cur_x (4 downto 0) = "00011" ) then
                            --attribute table is loaded every 32 cycle.
                            --attr table at 0x23c0
                            vram_addr(dsize - 1 downto 0) <= "11000000" +
                                    ("00" & next_y(7 downto 5) & next_x(7 downto 5));
                            vram_addr(asize - 1 downto dsize) <= "10" &
                                    ppu_ctrl(PPUBNA downto 0) & "11";
                        end if;--if (cur_x (2 downto 0) = "010" ) then
                        if (cur_x (4 downto 0) = "00100" ) then
                            attr_we_n <= '0';
                        else
                            attr_we_n <= '1';
                        end if;
                        if (cur_x (4 downto 0) = "00000" ) then
                            disp_attr_we_n <= '0';
                        else
                            disp_attr_we_n <= '1';
                        end if;
                        ---attribute is shifted every 16 bit.
                        if (cur_x (3 downto 0) = "0000" ) then
                            attr_ce_n <= '0';
                        else
                            attr_ce_n <= '1';
                        end if;
                        

                        ----fetch pattern table low byte.
                        if (cur_x (2 downto 0) = "101" ) then
                            --vram addr is incremented every 8 cycle.
                            vram_addr <= "0" & ppu_ctrl(PPUBPA) & 
                                            nt_next_val(dsize - 1 downto 0) 
                                                & "0"  & next_y(2  downto 0);
                        end if;--if (cur_x (2 downto 0) = "100" ) then
                        if (cur_x (2 downto 0) = "110" ) then
                            ptn_l_we_n <= '0';
                        else
                            ptn_l_we_n <= '1';
                        end if;

                        ----fetch pattern table high byte.
                        if (cur_x (2 downto 0) = "111" ) then
                            --vram addr is incremented every 8 cycle.
                            vram_addr <= "0" & ppu_ctrl(PPUBPA) & 
                                            nt_next_val(dsize - 1 downto 0) 
                                                & "0"  & next_y(2  downto 0) + 8;
                        end if; --if (cur_x (2 downto 0) = "110" ) then
                        if (cur_x (2 downto 0) = "000") then
                            ptn_h_we_n <= '0';
                        else
                            ptn_h_we_n <= '1';
                        end if;--if (cur_x (2 downto 0) = "001" ) then

                    end if; --if (cur_x <= conv_std_logic_vector(HSCAN, X_SIZE) or 

        d_print("cur_x: " & conv_hex16(conv_integer(cur_x)));
        d_print("cur_y: " & conv_hex16(conv_integer(cur_y)));
    --    d_print("next_x: " & conv_hex16(conv_integer(next_x)));
    --    d_print("nt_next_val: " & conv_hex8(conv_integer(nt_next_val)));
    --    d_print("vram_addr: " & conv_hex16(conv_integer(vram_addr)));

                    --output visible area only.
                    if ((cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                        (cur_y < conv_std_logic_vector(VSCAN, X_SIZE))) then
                        --output image.
                        output_bg_rgb;
                    end if;

                else
                    b <= (others => '1');
                    g <= (others => '0');
                    r <= (others => '1');
                end if;--if (ppu_mask(PPUSBG) = '1') then
            end if; --if (clk'event and clk = '1') then
        end if;--if (rst_n = '0') then
    end process;

    ------------------- palette access process -------------------
    plt_rw : process (plt_bus_ce_n, r_nw, plt_addr, plt_data)
    begin
        if (plt_bus_ce_n = '0') then
            if (r_nw = '0') then
                if (plt_addr(4) = '0') then
                    bg_palatte(conv_integer(plt_addr)) <= "00" & plt_data;
                else
                    sprite_palatte(conv_integer(plt_addr(3 downto 0))) <= "00" & plt_data;
                end if;
            end if;

            if (r_nw = '1') then
                if (plt_addr(4) = '0') then
                    plt_data <= bg_palatte(conv_integer(plt_addr))(5 downto 0);
                else
                    plt_data <= 
                        sprite_palatte(conv_integer(plt_addr(3 downto 0)))(5 downto 0);
                end if;
            end if;
        else
            plt_data <= (others => 'Z');
        end if;
    end process;

end rtl;

