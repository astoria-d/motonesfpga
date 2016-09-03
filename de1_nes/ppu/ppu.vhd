library ieee;
use ieee.std_logic_1164.all;
use work.motonesfpga_common.all;

entity ppu is 
    port (  
    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);

    signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
    signal dbg_nes_y                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_y                        : out std_logic_vector (9 downto 0);
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
    signal dbg_s_oam_addr_cpy               : out std_logic_vector (4 downto 0);

            dl_cpu_clk  : in std_logic;
            ppu_clk     : in std_logic;
            vga_clk     : in std_logic;
            emu_ppu_clk : in std_logic;
            emu_ppu_clk_dl : in std_logic;
            ce_n        : in std_logic;
            rst_n       : in std_logic;
            r_nw        : in std_logic;
            cpu_addr    : in std_logic_vector (2 downto 0);
            cpu_d       : inout std_logic_vector (7 downto 0);

            vblank_n    : out std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale_n       : out std_logic;
            vram_addr   : out std_logic_vector (13 downto 0);
            vram_data   : inout std_logic_vector (7 downto 0);

            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)

    );
end ppu;

architecture rtl of ppu is

component vga_ppu_render
    port (  
    signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
    signal dbg_nes_y                        : out std_logic_vector (8 downto 0);
    signal dbg_vga_y                        : out std_logic_vector (9 downto 0);
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
    signal dbg_s_oam_addr_cpy               : out std_logic_vector (4 downto 0);

            vga_clk     : in std_logic;
            emu_ppu_clk : in std_logic;
            emu_ppu_clk_dl : in std_logic;
            rst_n       : in std_logic;

            --vram i/f
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale_n       : out std_logic;
            vram_addr   : out std_logic_vector (13 downto 0);
            vram_data   : in std_logic_vector (7 downto 0);

            --vga output
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0);

            --upper ppu i/f
            ppu_ctrl        : in std_logic_vector (7 downto 0);
            ppu_mask        : in std_logic_vector (7 downto 0);
            ppu_status      : out std_logic_vector (7 downto 0);
            ppu_scroll_x    : in std_logic_vector (7 downto 0);
            ppu_scroll_y    : in std_logic_vector (7 downto 0);

            --ppu internal ram access
            r_nw            : in std_logic;
            plt_bus_ce_n    : in std_logic;
            plt_addr_in     : in std_logic_vector (4 downto 0);
            plt_data_in     : in std_logic_vector (7 downto 0);
            plt_data_out    : out std_logic_vector (7 downto 0);

            oam_bus_ce_n    : in std_logic;
            oam_addr_in     : in std_logic_vector (7 downto 0);
            oam_data_in     : in std_logic_vector (7 downto 0);
            oam_data_out    : out std_logic_vector (7 downto 0);

            v_bus_busy_n    : out std_logic
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

component d_flip_flop_bit
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic;
            q       : out std_logic
        );
end component;

constant dsize     : integer := 8;

constant PPUCTRL   : std_logic_vector(2 downto 0) := "000";
constant PPUMASK   : std_logic_vector(2 downto 0) := "001";
constant PPUSTATUS : std_logic_vector(2 downto 0) := "010";
constant OAMADDR   : std_logic_vector(2 downto 0) := "011";
constant OAMDATA   : std_logic_vector(2 downto 0) := "100";
constant PPUSCROLL : std_logic_vector(2 downto 0) := "101";
constant PPUADDR   : std_logic_vector(2 downto 0) := "110";
constant PPUDATA   : std_logic_vector(2 downto 0) := "111";

constant PPUVAI     : integer := 2;  --vram address increment
constant PPUNEN     : integer := 7;  --nmi enable
constant ST_VBL     : integer := 7;  --vblank

constant WR0 : std_logic_vector (0 downto 0) := "0";
constant WR1 : std_logic_vector (0 downto 0) := "1";

signal ppu_ctrl_we_n    : std_logic;
signal ppu_mask_we_n    : std_logic;
signal ppu_addr_we_n        : std_logic;
signal ppu_addr_inc_n       : std_logic;
signal ppu_addr_upd_n       : std_logic;
signal ppu_data_we_n    : std_logic;
signal ppu_scroll_x_we_n    : std_logic;
signal ppu_scroll_y_we_n    : std_logic;
signal oam_addr_inc_n    : std_logic;
signal oam_addr_we_n    : std_logic;
signal oam_data_we_n    : std_logic;

signal ppu_ctrl         : std_logic_vector (dsize - 1 downto 0);
signal ppu_mask         : std_logic_vector (dsize - 1 downto 0);
signal ppu_addr         : std_logic_vector (13 downto 0);
signal ppu_addr_inc1    : std_logic_vector (13 downto 0);
signal ppu_addr_inc32   : std_logic_vector (13 downto 0);
signal ppu_addr_in      : std_logic_vector (13 downto 0);
signal ppu_addr_wr_cycle    : std_logic_vector (0 downto 0);

signal ppu_status       : std_logic_vector (dsize - 1 downto 0);
signal rdr_ppu_stat     : std_logic_vector (dsize - 1 downto 0);

signal ppu_data         : std_logic_vector (dsize - 1 downto 0);
signal ppu_data_in      : std_logic_vector (dsize - 1 downto 0);
signal ppu_data_out     : std_logic_vector (dsize - 1 downto 0);
signal oam_addr         : std_logic_vector (dsize - 1 downto 0);
signal oam_data         : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_x     : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_y     : std_logic_vector (dsize - 1 downto 0);
signal ppu_scr_wr_cycle    : std_logic_vector (0 downto 0);

signal oam_bus_ce_n     : std_logic;
signal plt_bus_ce_n     : std_logic;

signal rnd_rd_n, rnd_wr_n, rnd_ale_n : std_logic;
signal rnd_vram_addr    : std_logic_vector (13 downto 0);
signal rnd_vram_data    : std_logic_vector (7 downto 0);

signal rnd_plt_data_out     : std_logic_vector (7 downto 0);
signal rnd_oam_data_out     : std_logic_vector (7 downto 0);

signal v_bus_busy_n     : std_logic;

begin

    dbg_ppu_ce_n <= ce_n;
    dbg_ppu_ctrl <= ppu_ctrl;
    dbg_ppu_mask <= ppu_mask;
    dbg_ppu_status <= ppu_status;
    dbg_ppu_addr  <= ppu_addr;
    dbg_ppu_data <= ppu_data;
    dbg_ppu_scrl_x <= ppu_scroll_x;
    --dbg_ppu_scrl_y <= ppu_scroll_y;


    -----------------------------
    --PPU register set..
    -----------------------------
    --ppu ctl reg.
    ppu_ctrl_we_n <= '0' when ce_n = '0' and cpu_addr = PPUCTRL and r_nw = '0' else
                     '1';
    ppu_ctrl_inst : d_flip_flop generic map(dsize)
            port map (dl_cpu_clk, rst_n, '1', ppu_ctrl_we_n, cpu_d, ppu_ctrl);

    --ppu mask reg.
    ppu_mask_we_n <= '0' when ce_n = '0' and cpu_addr = PPUMASK and r_nw = '0' else
                     '1';
    ppu_mask_inst : d_flip_flop generic map(dsize)
            port map (dl_cpu_clk, rst_n, '1', ppu_mask_we_n, cpu_d, ppu_mask);

    ppu_status_inst : d_flip_flop generic map(dsize)
            port map (emu_ppu_clk, rst_n, '1', '0', rdr_ppu_stat, ppu_status);

    --ppu addr reg.
    ppu_addr_in <=  cpu_d(5 downto 0) & ppu_addr(7 downto 0)
                        when ppu_addr_wr_cycle = WR0 else
                    ppu_addr(13 downto 8) & cpu_d;
    ppu_addr_we_n <= '0' when ce_n = '0' and cpu_addr = PPUADDR and r_nw = '0' else
                     '1';
    ppu_addr_inc_en_inst : d_flip_flop_bit
            port map (dl_cpu_clk, '1', rst_n, '0', ppu_data_we_n, ppu_addr_inc_n);
    ppu_addr_inst_inc1 : counter_register generic map(14, 1)
            port map (dl_cpu_clk, rst_n, ppu_addr_inc_n, ppu_addr_we_n, ppu_addr_in, ppu_addr_inc1);
    ppu_addr_inst_inc32 : counter_register generic map(14, 32)
            port map (dl_cpu_clk, rst_n, ppu_addr_inc_n, ppu_addr_we_n, ppu_addr_in, ppu_addr_inc32);
    ppu_addr <= ppu_addr_inc32 when ppu_ctrl(PPUVAI) = '1' else
                ppu_addr_inc1;

    --ppu write cycle update.
    clk_addr_wr_p : process (rst_n, dl_cpu_clk)
    begin
        if (rst_n = '0') then
            ppu_addr_wr_cycle <= WR0;
            ppu_scr_wr_cycle <= WR0;
        elsif (rising_edge(dl_cpu_clk) and ce_n = '0') then
            --ppu addr cycle.
            if (cpu_addr = PPUADDR and r_nw = '0') then
                if (ppu_addr_wr_cycle = WR1) then
                    ppu_addr_wr_cycle <= WR0;
                else
                    ppu_addr_wr_cycle <= WR1;
                end if;
            elsif (cpu_addr = PPUSTATUS and r_nw = '1') then
                --reset read count after reading status res.
                ppu_addr_wr_cycle <= WR0;
            end if;

            --ppu scroll cycle.
            if (cpu_addr = PPUSCROLL and r_nw = '0') then
                if (ppu_scr_wr_cycle = WR1) then
                    ppu_scr_wr_cycle <= WR0;
                else
                    ppu_scr_wr_cycle <= WR1;
                end if;
            elsif (cpu_addr = PPUSTATUS and r_nw = '1') then
                --reset read count after reading status res.
                ppu_scr_wr_cycle <= WR0;
            end if;

        end if;
    end process;

    --ppu data reg.
    ppu_data_we_n <= '0' when ce_n = '0' and cpu_addr = PPUDATA and r_nw = '0' else
                     '1';
    ppu_data_inst : d_flip_flop generic map(dsize)
            port map (dl_cpu_clk, rst_n, '1', ppu_data_we_n, cpu_d, ppu_data);

    --oam addr reg.
    oam_addr_we_n <= '0' when ce_n = '0' and cpu_addr = OAMADDR and r_nw = '0' else
                     '1';
    oam_addr_inc_en_inst : d_flip_flop_bit
            port map (dl_cpu_clk, '1', rst_n, '0', oam_data_we_n, oam_addr_inc_n);
    oma_addr_inst : counter_register generic map(dsize, 1)
            port map (dl_cpu_clk, rst_n, oam_addr_inc_n, oam_addr_we_n, cpu_d, oam_addr);

    --oam data reg.
    oam_data_we_n <= '0' when ce_n = '0' and cpu_addr = OAMDATA and r_nw = '0' else
                     '1';
    oma_data_inst : d_flip_flop generic map(dsize)
            port map (dl_cpu_clk, rst_n, '1', oam_data_we_n, cpu_d, oam_data);

    --oam chip enable.
    oam_bus_ce_n <= '0' when ce_n = '0' and cpu_addr = OAMDATA else
                    '1';
    
    --scroll reg.
    ppu_scroll_x_we_n <= '0' when ce_n = '0' and cpu_addr = PPUSCROLL and 
                                  r_nw = '0' and ppu_scr_wr_cycle = WR0 else
                     '1';
    ppu_scroll_x_inst : d_flip_flop generic map(dsize)
            port map (dl_cpu_clk, rst_n, '1', ppu_scroll_x_we_n, cpu_d, ppu_scroll_x);
    ppu_scroll_y_we_n <= '0' when ce_n = '0' and cpu_addr = PPUSCROLL and 
                                  r_nw = '0' and ppu_scr_wr_cycle = WR1 else
                     '1';
    ppu_scroll_y_inst : d_flip_flop generic map(dsize)
            port map (dl_cpu_clk, rst_n, '1', ppu_scroll_y_we_n, cpu_d, ppu_scroll_y);


    -----------------------------
    --vram access.
    -----------------------------
    dbg_ppu_scrl_y(0) <= ppu_addr_upd_n;
    dbg_ppu_scrl_y(1) <= ppu_addr_inc_n;
    dbg_ppu_scrl_y(2) <= ppu_data_we_n;

    ppu_addr_upd_en_inst : d_flip_flop_bit
            port map (dl_cpu_clk, rst_n, '1', '0', ppu_addr_inc_n, ppu_addr_upd_n);
    ale_n <= '0' when ce_n = '0' and cpu_addr = PPUADDR and r_nw = '0' else
           '0' when ppu_addr_upd_n = '0' else
           '1' when ce_n = '0' and cpu_addr = PPUDATA and r_nw = '0' else
           rnd_ale_n;
    wr_n <= '0' when ce_n = '0' and cpu_addr = PPUDATA and r_nw = '0' else
            '1' when ppu_addr_upd_n = '0' else
            '1' when ce_n = '0' and cpu_addr = PPUADDR and r_nw = '0' else
            rnd_wr_n;
    rd_n <= '1' when ce_n = '0' and cpu_addr = PPUADDR and r_nw = '0' else
            '1' when ppu_addr_upd_n = '0' else
            rnd_rd_n;

    vram_addr <= ppu_addr when ce_n = '0' and cpu_addr = PPUADDR and r_nw = '0' else
              ppu_addr when ppu_addr_upd_n = '0' else
              ppu_addr when ce_n = '0' and cpu_addr = PPUDATA else
              rnd_vram_addr when rnd_ale_n = '0' else
              (others => 'Z');
    vram_data <= cpu_d when ce_n = '0' and cpu_addr = PPUDATA and r_nw = '0' else
               (others => 'Z');

   rnd_vram_data <= vram_data;


    -----------------------------
    --palette ram access..
    -----------------------------
    plt_bus_ce_n <= '0' when ce_n = '0' and cpu_addr = PPUDATA and ppu_addr(13 downto 8) = "111111" else
                    '1';

    -----------------------------
    --cpu nmi generation...
    -----------------------------
    clk_nmi_p : process (rst_n, ppu_clk)
    begin
        if (rst_n = '0') then
            vblank_n <= '1';
        elsif (rising_edge(ppu_clk)) then
            if (rdr_ppu_stat(ST_VBL) = '1' and ppu_ctrl(PPUNEN) = '1') then
                --nmi takes place only when ST_VBL arises...
                --doesn't work....
--                if (ST_VBL_old = '0') then
                    --start vblank.
                    vblank_n <= '0';
--                end if;
            else
                --clear flag.
                vblank_n <= '1';
            end if;
        end if;
    end process;

    cpu_d <= (others => 'Z');

    vga_render_inst : vga_ppu_render port map (
    dbg_nes_x                        ,
    dbg_vga_x                        ,
    dbg_nes_y                        ,
    dbg_vga_y                        ,
    dbg_disp_nt, dbg_disp_attr, dbg_disp_ptn_h, dbg_disp_ptn_l,
    dbg_plt_ce_rn_wn                 ,
    dbg_plt_addr                     ,
    dbg_plt_data                     ,
    dbg_p_oam_ce_rn_wn              ,
    dbg_p_oam_addr                  ,
    dbg_p_oam_data                  ,
    dbg_s_oam_ce_rn_wn              ,
    dbg_s_oam_addr                  ,
    dbg_s_oam_data                  ,
    dbg_s_oam_addr_cpy              ,

            vga_clk, emu_ppu_clk, emu_ppu_clk_dl, rst_n,
            rnd_rd_n, rnd_wr_n, rnd_ale_n, rnd_vram_addr, rnd_vram_data,
            h_sync_n, v_sync_n, r, g, b, 
            ppu_ctrl, ppu_mask, rdr_ppu_stat, ppu_scroll_x, ppu_scroll_y,
            r_nw,
            plt_bus_ce_n, ppu_addr(4 downto 0), cpu_d, rnd_plt_data_out,
            oam_bus_ce_n, oam_addr, cpu_d, rnd_oam_data_out,
            v_bus_busy_n);

end rtl;

