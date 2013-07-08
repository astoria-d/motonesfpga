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
            plt_bus_ce_n : in std_logic;
            plt_r_nw    : in std_logic;
            plt_addr    : in std_logic_vector (4 downto 0);
            plt_data    : inout std_logic_vector (5 downto 0);
            pos_x       : out std_logic_vector (8 downto 0);
            pos_y       : out std_logic_vector (8 downto 0);
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0)
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

component test_module_init_data
    port (  clk             : in std_logic;
            v_rd_n          : out std_logic;
            v_wr_n          : out std_logic;
            v_ale           : out std_logic;
            v_ad            : out std_logic_vector (7 downto 0);
            v_a             : out std_logic_vector (13 downto 8);
            plt_bus_ce_n    : out std_logic;
            plt_r_nw        : out std_logic;
            plt_addr        : out std_logic_vector (4 downto 0);
            plt_data        : out std_logic_vector (5 downto 0)
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

subtype palette_data is std_logic_vector (dsize -1 downto 0);
type palette_array is array (0 to 15) of palette_data;
signal bg_palatte : palette_array := (others => (others => '0'));
signal sprite_palatte : palette_array := (others => (others => '0'));

subtype nes_color_data is std_logic_vector (11 downto 0);
type nes_color_array is array (0 to 63) of nes_color_data;
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

signal render_x_en_n    : std_logic;
signal render_x_res_n   : std_logic;
signal render_y_en_n    : std_logic;
signal render_y_res_n   : std_logic;

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
signal ptn_addr         : std_logic_vector (asize - 1 downto 0);

----test init data.
signal init_ale         : std_logic;
signal init_rd_n        : std_logic;
signal init_wr_n        : std_logic;

signal init_plt_bus_ce_n : std_logic;
signal init_plt_r_nw    : std_logic;
signal init_plt_addr    : std_logic_vector (4 downto 0);
signal init_plt_data    : std_logic_vector (5 downto 0);

begin

    rst <= not rst_n;
    clk_n <= not clk;

    render_x_en_n <= '0';

--    wr_n <= '1';
--    ale <= not cur_x(0) when rst_n = '1' else '1';
--    rd_n <= not cur_x(0) when rst_n = '1' else '1';

    io_cnt_inst : counter_register generic map (1)
            port map (clk, render_x_res_n, '1', '0', (others => '0'), io_cnt);

    ale <= io_cnt(0) when rst_n = '1' else init_ale;
    rd_n <= io_cnt(0) when rst_n = '1' else init_rd_n;
    wr_n <= '1' when rst_n = '1' else init_wr_n;
    io_oe_n <= not io_cnt(0) when rst_n = '1' else '1';

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
            port map (clk_n, render_x_res_n, '1', 
                    render_x_en_n, (others => '0'), cur_x);
    cur_y_inst : counter_register generic map (X_SIZE)
            port map (clk_n, render_y_res_n, '1', 
                    render_y_en_n, (others => '0'), cur_y);

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
            port map (rst, vram_addr(asize - 1 downto dsize), vram_a);

    pos_x <= cur_x;
    pos_y <= cur_y;

    clk_p : process (rst_n, clk) 

procedure output_bg_rgb is
variable plt_addr : integer;
variable palette_index : integer;
begin
    --firs t color in the palette is transparent color.
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
            render_x_res_n <= '0';
            render_y_res_n <= '0';
            nt_next_we_n <= '1';
        else
            if (clk'event) then
                --x pos reset.
                if (clk = '0' and 
                        cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                    render_x_res_n <= '0';

                    --y pos reset.
                    if (cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) then
                        render_y_res_n <= '0';
                    else
                        render_y_res_n <= '1';
                    end if;
                else
                    render_x_res_n <= '1';
                    render_y_res_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '1') then
                --y pos increment.
                if (cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                    render_y_en_n <= '0';
                else
                    render_y_en_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '0') then
                d_print("-");
            end if;

            if (clk'event and clk = '1') then
                d_print("*");

                --visible area and last pixel for the next sirst pixel.
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
                        vram_addr(asize - 1 downto 10) <= "1000";
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
                        vram_addr(asize - 1 downto dsize) <= "100011";
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
                        vram_addr <= "01" & nt_next_val(dsize - 1 downto 0) 
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
                        vram_addr <= "01" & nt_next_val(dsize - 1 downto 0) 
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

            end if; --if (clk'event and clk = '1') then
        end if;--if (rst_n = '0') then
    end process;

--    ------------------- palette access process -------------------
--    plt_rw : process (plt_bus_ce_n, plt_r_nw, plt_addr, plt_data)
--    begin
--        if (plt_bus_ce_n = '0') then
--            if (plt_r_nw = '0') then
--                if (plt_addr(4) = '0') then
--                    bg_palatte(conv_integer(plt_addr)) <= plt_data;
--                else
--                    sprite_palatte(conv_integer(plt_addr)) <= plt_data;
--                end if;
--            end if;
--
--            if (plt_r_nw = '1') then
--                if (plt_addr(4) = '0') then
--                    plt_data <= bg_palatte(conv_integer(plt_addr));
--                else
--                    plt_data <= sprite_palatte(conv_integer(plt_addr));
--                end if;
--            end if;
--        else
--            plt_data <= (others => 'Z');
--        end if;
--    end process;

    -----fill test data during the reset.....
    init_data : test_module_init_data 
        port map (clk, init_rd_n, init_wr_n, init_ale, vram_ad, vram_a,
                init_plt_bus_ce_n, init_plt_r_nw, init_plt_addr, init_plt_data
                );

    ----- test initial value stting.
    plt_init_w : process (init_plt_bus_ce_n, init_plt_r_nw, 
                         init_plt_addr, init_plt_data)
    begin
        if (init_plt_bus_ce_n = '0') then
            if (init_plt_r_nw = '0') then
                if (init_plt_addr(4) = '0') then
--                    d_print("dummy addr:" & conv_hex8(conv_integer(init_plt_addr)));
--                    d_print("plt val:" & conv_hex8(conv_integer(init_plt_data)));
                    bg_palatte(conv_integer(init_plt_addr)) <= "00" & init_plt_data;
                end if;
            end if;
        end if;
    end process;

end rtl;



------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
--       initialize with dummy data
------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity test_module_init_data is
    port (  clk             : in std_logic;
            v_rd_n          : out std_logic;
            v_wr_n          : out std_logic;
            v_ale           : out std_logic;
            v_ad            : out std_logic_vector (7 downto 0);
            v_a             : out std_logic_vector (13 downto 8);
            plt_bus_ce_n    : out std_logic;
            plt_r_nw        : out std_logic;
            plt_addr        : out std_logic_vector (4 downto 0);
            plt_data        : out std_logic_vector (5 downto 0)
    );
end test_module_init_data;

architecture stimulus of test_module_init_data is

    constant ppu_clk : time := 186 ns;
    constant size8 : integer := 8;
    constant size16 : integer := 16;
    constant size14 : integer := 14;

    signal v_addr       : std_logic_vector (size14 - 1 downto 0);

begin

    v_ad <= v_addr(size8 - 1 downto 0);
    v_a <= v_addr(size14 - 1 downto size8);

    -----test for vram/chr-rom
    p_vram_init : process
    variable i : integer := 0;
    variable tmp : std_logic_vector (size8 - 1 downto 0);
    constant loopcnt : integer := 15;
    begin

        ---dummy power up wait (same amount of time as testbench)
        wait for 7 us;

        --copy from chr rom to name tbl.
        for i in 0 to loopcnt loop
            --write name tbl #0
            v_ale <= '1';
            v_rd_n <= '1';
            v_wr_n <= '1';
            v_addr <= conv_std_logic_vector(16#2000# + i, size14);
            wait for ppu_clk;
            v_addr(7 downto 0) <= (others => 'Z');
            v_ale <= '0';
            v_rd_n <= '1';
            v_wr_n <= '0';
            ---bg start from 0.
            v_addr(7 downto 0) <= conv_std_logic_vector(i + 32, size8);
            wait for ppu_clk;

            --write attr tbl #0
            v_ale <= '1';
            v_rd_n <= '1';
            v_wr_n <= '1';
            v_addr <= conv_std_logic_vector(16#23c0# + i, size14);
            wait for ppu_clk;
            v_addr(7 downto 0) <= (others => 'Z');
            v_ale <= '0';
            v_rd_n <= '1';
            v_wr_n <= '0';
            v_addr(7 downto 0) <= conv_std_logic_vector(16#a0# + i, size8);
            wait for ppu_clk;
        end loop;

        v_addr <= (others => 'Z');

        wait;
    end process;

    p_palette_init : process
    variable i : integer := 0;
    begin
        wait for 7 us;

        --fill palette teble.
        plt_bus_ce_n <= '0';
        plt_r_nw <= '0';
        for i in 0 to 32 loop
            plt_addr <= conv_std_logic_vector(i, 5);
            plt_data <= conv_std_logic_vector((i - 1) * 4 + 17, 6);
            wait for ppu_clk;
        end loop;
        plt_bus_ce_n <= '1';
        plt_data <= (others => 'Z');

        wait;
    end process;

end stimulus ;

