library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use work.motonesfpga_common.all;

entity ppu_render is 
    port (  
    signal dbg_vga_clk                      : out std_logic;
    signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
    signal dbg_disp_nt, dbg_disp_attr       : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l   : out std_logic_vector (15 downto 0);
    signal dbg_plt_ce_rn_wn                 : out std_logic_vector (2 downto 0);
    signal dbg_plt_addr                     : out std_logic_vector (4 downto 0);
    signal dbg_plt_data                     : out std_logic_vector (7 downto 0);
    signal dbg_p_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
    signal dbg_p_oam_addr                   : out std_logic_vector (7 downto 0);
    signal dbg_p_oam_data                   : out std_logic_vector (7 downto 0);
    signal dbg_s_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
    signal dbg_s_oam_addr                   : out std_logic_vector (4 downto 0);
    signal dbg_s_oam_data                   : out std_logic_vector (7 downto 0);
    
            ppu_clk     : in std_logic;
            vga_clk     : in std_logic;
            mem_clk     : in std_logic;
            rst_n       : in std_logic;

            --vram i/f
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);

            --vga output
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0);

            --upper ppu i/f
            ppu_ctrl        : in std_logic_vector (7 downto 0);
            ppu_mask        : in std_logic_vector (7 downto 0);
            read_status     : in std_logic;
            ppu_scroll_x    : in std_logic_vector (7 downto 0);
            ppu_scroll_y    : in std_logic_vector (7 downto 0);
            ppu_status      : out std_logic_vector (7 downto 0);
            v_bus_busy_n    : out std_logic;

            --ppu internal ram access
            r_nw            : in std_logic;
            oam_bus_ce_n    : in std_logic;
            plt_bus_ce_n    : in std_logic;
            oam_plt_addr    : in std_logic_vector (7 downto 0);
            oam_plt_data    : inout std_logic_vector (7 downto 0)
    );
end ppu_render;

architecture rtl of ppu_render is

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

component vga_ctl
    port (  
    signal dbg_vga_clk                      : out std_logic;
    signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
    signal dbg_disp_nt, dbg_disp_attr       : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l   : out std_logic_vector (15 downto 0);
    signal dbg_plt_ce_rn_wn                 : out std_logic_vector (2 downto 0);
    signal dbg_plt_addr                     : out std_logic_vector (4 downto 0);
    signal dbg_plt_data                     : out std_logic_vector (7 downto 0);
    signal dbg_p_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
    signal dbg_p_oam_addr                   : out std_logic_vector (7 downto 0);
    signal dbg_p_oam_data                   : out std_logic_vector (7 downto 0);
    signal dbg_s_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
    signal dbg_s_oam_addr                   : out std_logic_vector (4 downto 0);
    signal dbg_s_oam_data                   : out std_logic_vector (7 downto 0);

            vga_clk     : in std_logic;
            mem_clk     : in std_logic;
            rst_n       : in std_logic;

            --vram i/f
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout  std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);

            --vga output
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0);

            --upper ppu i/f
            ppu_ctrl        : in std_logic_vector (7 downto 0);
            ppu_mask        : in std_logic_vector (7 downto 0);
            read_status     : in std_logic;
            ppu_scroll_x    : in std_logic_vector (7 downto 0);
            ppu_scroll_y    : in std_logic_vector (7 downto 0);

            --ppu internal ram access
            r_nw            : in std_logic;
            oam_bus_ce_n    : in std_logic;
            plt_bus_ce_n    : in std_logic;
            oam_plt_addr    : in std_logic_vector (7 downto 0);
            oam_plt_data    : inout std_logic_vector (7 downto 0)
    );
end component;


constant X_SIZE       : integer := 9;
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

constant SPRHFL     : integer := 6;  --flip sprigte horizontally
constant SPRVFL     : integer := 7;  --flip sprigte vertically

constant ST_SOF     : integer := 5;  --sprite overflow
constant ST_SP0     : integer := 6;  --sprite 0 hits
constant ST_VBL     : integer := 7;  --vblank

--current drawing position 340 x 261
signal cur_x            : std_logic_vector(X_SIZE - 1 downto 0);
signal cur_y            : std_logic_vector(X_SIZE - 1 downto 0);
signal cnt_x_res_n      : std_logic;
signal cnt_y_en_n       : std_logic;
signal cnt_y_res_n      : std_logic;

begin

    --vga rendering module instance...
    vga_render_inst : vga_ctl
            port map (
            dbg_vga_clk                      ,
            dbg_nes_x                        ,
            dbg_vga_x                        ,
            dbg_disp_nt, dbg_disp_attr     ,
            dbg_disp_ptn_h, dbg_disp_ptn_l ,
            dbg_plt_ce_rn_wn                 ,
            dbg_plt_addr                     ,
            dbg_plt_data                     ,
            dbg_p_oam_ce_rn_wn              ,
            dbg_p_oam_addr                  ,
            dbg_p_oam_data                  ,
            dbg_s_oam_ce_rn_wn              ,
            dbg_s_oam_addr                  ,
            dbg_s_oam_data                  ,
            vga_clk     ,
            mem_clk     ,
            rst_n       ,

            rd_n        ,
            wr_n        ,
            ale         ,
            vram_ad     ,
            vram_a      ,

            h_sync_n    ,
            v_sync_n    ,
            r           ,
            g           ,
            b           ,

            ppu_ctrl    ,
            ppu_mask    ,
            read_status ,
            ppu_scroll_x ,
            ppu_scroll_y ,

            r_nw            ,
            oam_bus_ce_n    ,
            plt_bus_ce_n    ,
            oam_plt_addr    ,
            oam_plt_data    
        );

    pos_p : process (rst_n, ppu_clk)
    begin
        if (rst_n = '0') then
            cnt_x_res_n <= '0';
            cnt_y_res_n <= '0';
        elsif (ppu_clk'event and ppu_clk = '0') then
            if (cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                --x pos reset.
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

            --y pos increment.
            if (cur_x = conv_std_logic_vector(HSCAN_MAX - 1, X_SIZE)) then
                cnt_y_en_n <= '0';
            else
                cnt_y_en_n <= '1';
            end if;
        end if; --if (rst_n = '0') then
    end process;

    --manipulate ppu flag procedure.
    v_bus_busy_n <= '0' when (ppu_mask(PPUSBG) = '1' or ppu_mask(PPUSSP) = '1') and
                (cur_y < conv_std_logic_vector(VSCAN, X_SIZE) or 
                cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE)) else
              '1';

    ppu_flag_p : process (rst_n, ppu_clk, read_status)

procedure set_spr0_hit is
begin
    --not ready yet...
end;

    begin
        if (rst_n = '0') then
            ppu_status <= (others => '0');
        else

            if (ppu_clk'event and ppu_clk = '1') then
                if ((cur_x < conv_std_logic_vector(HSCAN, X_SIZE)) and
                    (cur_y < conv_std_logic_vector(VSCAN, X_SIZE))) then
                    --check if sprite 0 is hit.
                    set_spr0_hit;
                end if;

                --flag operation
                if ((cur_x = conv_std_logic_vector(1, X_SIZE)) and
                    (cur_y = conv_std_logic_vector(VSCAN + 1, X_SIZE))) then
                    --vblank start
                    ppu_status(ST_VBL) <= '1';
                elsif ((cur_x = conv_std_logic_vector(1, X_SIZE)) and
                    (cur_y = conv_std_logic_vector(VSCAN_MAX - 1, X_SIZE))) then
                    ppu_status(ST_SP0) <= '0';
                    --vblank end
                    ppu_status(ST_VBL) <= '0';
                    --TODO: sprite overflow is not inplemented!
                    ppu_status(ST_SOF) <= '0';
                end if;
            end if; --if (clk'event and clk = '1') then
        end if;--if (rst_n = '0') then
    end process;

end rtl;

