library ieee;
use ieee.std_logic_1164.all;
use work.motonesfpga_common.all;

entity ppu is 
    port (
                pi_base_clk    : in std_logic;
                pi_ppu_en      : in std_logic_vector (3 downto 0);
                pi_ce_n        : in std_logic;
                pi_rst_n       : in std_logic;
                pi_r_nw        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d      : inout std_logic_vector (7 downto 0);

                po_rd_n        : out std_logic;
                po_wr_n        : out std_logic;
                po_ale_n       : out std_logic;
                po_vram_addr   : out std_logic_vector (13 downto 0);
                pio_vram_data  : inout std_logic_vector (7 downto 0)
    );
end ppu;

architecture rtl of ppu is

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

begin

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
            port map (cpu_clk, rst_n, '1', '0', rdr_ppu_stat, ppu_status);

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
            '0' when ce_n = '0' and cpu_addr = PPUDATA and r_nw = '1' else
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

    -----------------------------
    --read from cpu...
    -----------------------------
    --TODO! palette ram read sequence must be re-worked!!
    cpu_d <= ppu_status when ce_n = '0' and cpu_addr = PPUSTATUS and r_nw = '1' else
             rnd_plt_data_out when ce_n = '0' and cpu_addr = PPUDATA and
                                           ppu_addr(13 downto 8) = "111111" and r_nw = '1' else
             vram_data when ce_n = '0' and cpu_addr = PPUDATA and r_nw = '1' else
             (others => 'Z');

end rtl;

