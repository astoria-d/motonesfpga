library ieee;
use ieee.std_logic_1164.all;
use work.motonesfpga_common.all;

entity ppu is 
    port (  
    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);

    signal dbg_ppu_clk                      : out std_logic;
    signal dbg_vga_clk                      : out std_logic;
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
    signal dbg_emu_ppu_clk                  : out std_logic;

    signal dbg_ppu_addr_we_n                : out std_logic;
    signal dbg_ppu_clk_cnt                  : out std_logic_vector(1 downto 0);

    
            ppu_clk     : in std_logic;
            mem_clk     : in std_logic;
            ce_n        : in std_logic;
            rst_n       : in std_logic;
            r_nw        : in std_logic;
            cpu_addr    : in std_logic_vector (2 downto 0);
            cpu_d       : inout std_logic_vector (7 downto 0);

            vblank_n    : out std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);

            vga_clk     : in std_logic;
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
    signal dbg_vga_clk                      : out std_logic;
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
    signal dbg_emu_ppu_clk                  : out std_logic;

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
            ppu_status      : out std_logic_vector (7 downto 0);
            ppu_scroll_x    : in std_logic_vector (7 downto 0);
            ppu_scroll_y    : in std_logic_vector (7 downto 0);

            --ppu internal ram access
            r_nw            : in std_logic;
            oam_bus_ce_n    : in std_logic;
            plt_bus_ce_n    : in std_logic;
            oam_plt_addr    : in std_logic_vector (7 downto 0);
            oam_plt_data    : inout std_logic_vector (7 downto 0);
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

constant dsize     : integer := 8;

constant PPUCTRL   : std_logic_vector(2 downto 0) := "000";
constant PPUMASK   : std_logic_vector(2 downto 0) := "001";
constant PPUSTATUS : std_logic_vector(2 downto 0) := "010";
constant OAMADDR   : std_logic_vector(2 downto 0) := "011";
constant OAMDATA   : std_logic_vector(2 downto 0) := "100";
constant PPUSCROLL : std_logic_vector(2 downto 0) := "101";
constant PPUADDR   : std_logic_vector(2 downto 0) := "110";
constant PPUDATA   : std_logic_vector(2 downto 0) := "111";

constant PPUSBG    : integer := 3;  --show bg
constant PPUSSP    : integer := 4;  --show sprie

constant PPUVAI     : integer := 2;  --vram address increment
constant PPUNEN     : integer := 7;  --nmi enable
constant ST_VBL     : integer := 7;  --vblank

signal ppu_clk_n            : std_logic;

signal ppu_clk_cnt_res_n    : std_logic;
signal ppu_clk_cnt          : std_logic_vector(1 downto 0);

signal ppu_ctrl_we_n    : std_logic;
signal ppu_mask_we_n    : std_logic;
signal oam_addr_ce_n    : std_logic;
signal oam_addr_we_n    : std_logic;
signal oam_data_we_n    : std_logic;
signal ppu_scroll_x_we_n    : std_logic;
signal ppu_scroll_y_we_n    : std_logic;
signal ppu_scroll_cnt_ce_n  : std_logic;
signal ppu_addr_we_n        : std_logic;
signal ppu_addr_cnt_ce_n    : std_logic;
signal ppu_data_we_n    : std_logic;

signal ppu_ctrl         : std_logic_vector (dsize - 1 downto 0);
signal ppu_mask         : std_logic_vector (dsize - 1 downto 0);
signal read_status      : std_logic;
signal ppu_status       : std_logic_vector (dsize - 1 downto 0);
signal ppu_stat_out     : std_logic_vector (dsize - 1 downto 0);
signal oam_addr         : std_logic_vector (dsize - 1 downto 0);
signal oam_data         : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_x     : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_y     : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_cnt   : std_logic_vector (0 downto 0);
signal ppu_addr         : std_logic_vector (13 downto 0);
signal ppu_addr_inc1    : std_logic_vector (13 downto 0);
signal ppu_addr_inc32   : std_logic_vector (13 downto 0);
signal ppu_addr_in      : std_logic_vector (13 downto 0);
signal ppu_addr_cnt     : std_logic_vector (0 downto 0);
signal ppu_data         : std_logic_vector (dsize - 1 downto 0);
signal ppu_data_in      : std_logic_vector (dsize - 1 downto 0);
signal ppu_data_out     : std_logic_vector (dsize - 1 downto 0);
signal read_data_n      : std_logic;
signal ppu_latch_rst_n  : std_logic;
signal v_bus_busy_n     : std_logic;

signal oam_bus_ce_n     : std_logic;
signal plt_bus_ce_n     : std_logic;

signal oam_plt_addr     : std_logic_vector (dsize - 1 downto 0);
signal oam_plt_data     : std_logic_vector (dsize - 1 downto 0);
signal plt_data_out     : std_logic_vector (dsize - 1 downto 0);

begin


    dbg_ppu_clk <= ppu_clk;
    dbg_ppu_ce_n <= ce_n;
    dbg_ppu_ctrl <= ppu_ctrl;
    dbg_ppu_mask <= ppu_mask;
    dbg_ppu_status <= ppu_status;
    dbg_ppu_addr  <= ppu_addr;
    dbg_ppu_data <= ppu_data;
    dbg_ppu_scrl_x <= ppu_scroll_x;
    dbg_ppu_scrl_y <= ppu_scroll_y;
    dbg_ppu_addr_we_n <= ppu_addr_we_n;
    dbg_ppu_clk_cnt <= ppu_clk_cnt;



    vga_render_inst : vga_ppu_render port map (
    dbg_vga_clk                      ,
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
    dbg_emu_ppu_clk                 ,
    
            vga_clk, mem_clk, rst_n,
            rd_n, wr_n, ale, vram_ad, vram_a,
            h_sync_n, v_sync_n, r, g, b, 
            ppu_ctrl, ppu_mask, read_status, ppu_status, ppu_scroll_x, ppu_scroll_y,
            r_nw, oam_bus_ce_n, plt_bus_ce_n, 
            oam_plt_addr, oam_plt_data, v_bus_busy_n);

    --PPU registers.
    ppu_clk_n <= not ppu_clk;

    ppu_clk_cnt_inst : counter_register generic map (2, 1)
            port map (ppu_clk_n, ppu_clk_cnt_res_n, '0', '1', (others => '0'), ppu_clk_cnt); 

    ppu_ctrl_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_ctrl_we_n, cpu_d, ppu_ctrl);

    ppu_mask_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_mask_we_n, cpu_d, ppu_mask);

    ppu_status_inst : d_flip_flop generic map(dsize)
            port map (read_status, rst_n, '1', '0', ppu_status, ppu_stat_out);

    oma_addr_inst : counter_register generic map(dsize, 1)
            port map (ppu_clk_n, rst_n, oam_addr_ce_n, oam_addr_we_n, cpu_d, oam_addr);
    oma_data_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', oam_data_we_n, cpu_d, oam_data);

    ppu_scroll_x_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_scroll_x_we_n, cpu_d, ppu_scroll_x);
    ppu_scroll_y_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_scroll_y_we_n, cpu_d, ppu_scroll_y);
    ppu_scroll_cnt_inst : counter_register generic map (1, 1)
            port map (ppu_clk_n, ppu_latch_rst_n, ppu_scroll_cnt_ce_n, 
                                            '1', (others => '0'), ppu_scroll_cnt);

    ppu_addr_in <=  cpu_d(5 downto 0) & ppu_addr(7 downto 0)
                        when ppu_addr_cnt(0) = '1' else
                    ppu_addr(13 downto 8) & cpu_d;

    ppu_addr_inst_inc1 : counter_register generic map(14, 1)
            port map (ppu_clk_n, rst_n, ppu_data_we_n, ppu_addr_we_n, ppu_addr_in, ppu_addr_inc1);
    ppu_addr_inst_inc32 : counter_register generic map(14, 32)
            port map (ppu_clk_n, rst_n, ppu_data_we_n, ppu_addr_we_n, ppu_addr_in, ppu_addr_inc32);

    ppu_addr <= ppu_addr_inc32 when ppu_ctrl(PPUVAI) = '1' else
                ppu_addr_inc1;

    ppu_addr_cnt_inst : counter_register generic map (1, 1)
            port map (ppu_clk_n, ppu_latch_rst_n, ppu_addr_cnt_ce_n, 
                                            '1', (others => '0'), ppu_addr_cnt);
    ppu_data_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_data_we_n, cpu_d, ppu_data);

    ppu_data_in_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_data_we_n, vram_ad, ppu_data_in);

    ppu_data_out_inst : d_flip_flop generic map(dsize)
            port map (read_data_n, rst_n, '1', '0', ppu_data_in, ppu_data_out);

    plt_data_out_inst : d_flip_flop generic map(dsize)
            port map (ppu_clk_n, rst_n, '1', ppu_data_we_n, oam_plt_data, plt_data_out);

    reg_set_p : process (rst_n, ce_n, r_nw, cpu_addr)
    begin

        if (rst_n = '0') then
            ppu_ctrl_we_n    <= '1';
            ppu_mask_we_n    <= '1';
            oam_addr_we_n    <= '1';
            oam_data_we_n    <= '1';
            ppu_scroll_x_we_n    <= '1';
            ppu_scroll_y_we_n    <= '1';
            ppu_scroll_cnt_ce_n  <= '1';
            read_status <= '0';
            read_data_n <= '1';
        elsif (rst_n = '1' and ce_n = '0') then

            --register set.
            if(cpu_addr = PPUCTRL) then
                ppu_ctrl_we_n <= '0';
            else
                ppu_ctrl_we_n <= '1';
            end if;

            if(cpu_addr = PPUMASK) then
                ppu_mask_we_n <= '0';
            else
                ppu_mask_we_n <= '1';
            end if;

            if(cpu_addr = PPUSTATUS and r_nw = '1') then
                --notify reading status
                read_status <= '1';
            else
                read_status <= '0';
            end if;

            if(cpu_addr = OAMADDR) then
                oam_addr_we_n <= '0';
            else
                oam_addr_we_n <= '1';
            end if;

            if(cpu_addr = OAMDATA) then
                oam_data_we_n <= '0';
            else
                oam_data_we_n <= '1';
            end if;

            if(cpu_addr = PPUSCROLL) then
                ppu_scroll_cnt_ce_n <= '0';
                if (ppu_scroll_cnt(0) = '0') then
                    ppu_scroll_x_we_n <= '0';
                    ppu_scroll_y_we_n <= '1';
                else
                    ppu_scroll_y_we_n <= '0';
                    ppu_scroll_x_we_n <= '1';
                end if;
            else
                ppu_scroll_x_we_n <= '1';
                ppu_scroll_y_we_n <= '1';
                ppu_scroll_cnt_ce_n <= '1';
            end if;

            if (cpu_addr = PPUDATA and r_nw = '1') then
                read_data_n <= '0';
            else
                read_data_n <= '1';
            end if;
        else
            ppu_ctrl_we_n    <= '1';
            ppu_mask_we_n    <= '1';
            oam_addr_we_n    <= '1';
            oam_data_we_n    <= '1';
            ppu_scroll_x_we_n    <= '1';
            ppu_scroll_y_we_n    <= '1';
            ppu_scroll_cnt_ce_n  <= '1';
            read_status <= '0';
            read_data_n <= '1';
        end if; --if (rst_n = '1' and ce_n = '0') 

    end process;

    ppu_clk_cnt_res_n <= not ce_n;

    --cpu nmi generation...
    clk_nmi_p : process (rst_n, ppu_clk)
    begin
        if (rst_n = '0') then
            vblank_n <= '1';
        elsif (rising_edge(ppu_clk)) then
            if (ppu_status(ST_VBL) = '1' and ppu_ctrl(PPUNEN) = '1') then
                --start vblank.
                vblank_n <= '0';
            else
                --clear flag.
                vblank_n <= '1';
            end if;
        end if;
    end process;
    
    --cpu and ppu clock timing adjustment...
    clk_cnt_set_p : process (rst_n, ce_n, r_nw, cpu_addr, ppu_clk, cpu_d, ppu_clk_cnt, ppu_addr_cnt)
    begin
        if (rst_n = '0') then
            ppu_latch_rst_n <= '0';
            ppu_addr_we_n    <= '1';
            oam_addr_ce_n <= '1';
            ppu_addr_cnt_ce_n    <= '1';
            ppu_data_we_n    <= '1';
            plt_bus_ce_n <= '1';
            oam_bus_ce_n     <= '1';
            rd_n <= 'Z';
            wr_n <= 'Z';
            ale <= 'Z';
            oam_plt_data <= (others => 'Z');
            vram_ad <= (others => 'Z');
            vram_a <= (others => 'Z');
            cpu_d <= (others => 'Z');
        elsif (rst_n = '1' and ce_n = '0') then

            --start counter.
            if (ppu_clk'event and ppu_clk = '0') then
                if (read_status = '1') then
                    --reading status resets ppu_addr/scroll cnt.
                    ppu_latch_rst_n <= '0';
                else
                    ppu_latch_rst_n <= '1';
                end if;
                --d_print("clk event");
            end if;

            --oam data set
            if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then
                oam_bus_ce_n <= '0';
                oam_addr_ce_n <= '0';
            else
                oam_bus_ce_n <= '1';
                oam_addr_ce_n <= '1';
            end if; --if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then

            if (cpu_addr = PPUADDR and ppu_clk_cnt = "00") then
                ppu_addr_cnt_ce_n <= '0';
                if (ppu_addr_cnt(0) = '0') then
                    --load addr high
                    ale <= '0';
                else
                    --load addr low and output vram/plt bus.
                    --if address is 3fxx, set palette table.
                    if (ppu_addr(13 downto 8) = "111111") then
                        ale <= '0';
                    else
                        ale <= '1';
                    end if;
                end if;
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "01") then
                ppu_addr_cnt_ce_n <= '1';
                --for burst write.
                if (ppu_addr(13 downto 8) = "111111") then
                    ale <= '0';
                else
                    ale <= '1';
                end if;
            else
                ppu_addr_cnt_ce_n <= '1';
                ale <= '0';
            end if; --if (cpu_addr = PPUADDR and ppu_clk_cnt = "00") then

            if (cpu_addr = PPUADDR and ppu_clk_cnt = "01") then
                ppu_addr_we_n <= '0';
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "10") then
                ppu_addr_we_n <= '1';
            else
                ppu_addr_we_n    <= '1';
            end if; --if (cpu_addr = PPUADDR and ppu_clk_cnt = "01") then
            
            if (cpu_addr = PPUDATA and ppu_clk_cnt = "00") then
                ppu_data_we_n <= '0';
                if (ppu_addr(13 downto 8) = "111111") then
                    --case palette tbl.
                    plt_bus_ce_n <= '0';
                    rd_n <= '1';
                    wr_n <= '1';
                else
                    plt_bus_ce_n <= '1';
                    rd_n <= not r_nw;
                    wr_n <= r_nw;
                end if;
            else
                ppu_data_we_n <= '1';
                plt_bus_ce_n <= '1';
                rd_n <= 'Z';
                wr_n <= 'Z';
            end if; --if (cpu_addr = PPUDATA and ppu_clk_cnt = "00") then

            --oam_plt_addr output...
            if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then
                oam_plt_addr <= oam_addr;
            elsif (cpu_addr = PPUADDR and ppu_clk_cnt = "00") then
                if (ppu_addr_cnt(0) = '1' and ppu_addr(13 downto 8) = "111111") then
                    oam_plt_addr <= cpu_d;
                else
                    oam_plt_addr <= (others => 'Z');
                end if;
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "01") then
                if (ppu_addr(13 downto 8) = "111111") then
                    oam_plt_addr <= ppu_addr(7 downto 0);
                else
                    oam_plt_addr <= (others => 'Z');
                end if;
            else
                oam_plt_addr <= (others => 'Z');
            end if; --if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then

            --oam_plt_data output...
            if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then
                if (r_nw = '0') then
                    oam_plt_data <= cpu_d;
                else
                    oam_plt_data <= (others => 'Z');
                end if;
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "00") then
                if (ppu_addr(13 downto 8) = "111111") then
                    if (r_nw = '0') then
                        oam_plt_data <= cpu_d;
                    else
                        oam_plt_data <= (others => 'Z');
                    end if;
                else
                    oam_plt_data <= (others => 'Z');
                end if;
            else
                oam_plt_data <= (others => 'Z');
            end if; --if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then

            --cpu_d data set
            if (cpu_addr = OAMDATA and r_nw = '1') then
                if (ppu_clk_cnt = "00") then
                    cpu_d <= oam_plt_data;
                else
                    cpu_d <= oam_data;
                end if;
            elsif (cpu_addr = PPUDATA and r_nw = '1' and ppu_clk_cnt = "00") then
                if (ppu_clk_cnt = "00") then
                    if (ppu_addr(13 downto 8) = "111111") then
                        cpu_d <= oam_plt_data;
                    else
                        cpu_d <= ppu_data_out;
                    end if;
                else
                    if (ppu_addr(13 downto 8) = "111111") then
                        cpu_d <= plt_data_out;
                    else
                        cpu_d <= ppu_data_out;
                    end if;
                end if;
            elsif (cpu_addr = PPUSTATUS and r_nw = '1') then
                cpu_d <= ppu_stat_out;
            else
                cpu_d <= (others => 'Z');
            end if; --if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then


            --vram_a/vram_ad data set
            if (cpu_addr = PPUADDR and ppu_clk_cnt = "00" and ppu_addr_cnt(0) = '1') then
                if (ppu_addr(13 downto 8) = "111111") then
                    vram_a <= (others => 'Z');
                    vram_ad <= (others => 'Z');
                else
                    vram_a <= ppu_addr(13 downto 8);
                    vram_ad <= cpu_d;
                end if;
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "01") then
                if (ppu_addr(13 downto 8) = "111111") then
                    vram_a <= (others => 'Z');
                    vram_ad <= (others => 'Z');
                else
                    vram_a <= ppu_addr(13 downto 8);
                    vram_ad <= ppu_addr(7 downto 0);
                end if;
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "00") then
                vram_a <= ppu_addr(13 downto 8);
                if (ppu_addr(13 downto 8) = "111111") then
                    vram_ad <= (others => 'Z');
                else
                    if (r_nw = '0') then
                        vram_ad <= cpu_d;
                    else
                        vram_ad <= (others => 'Z');
                    end if;
                end if;
            else
                vram_a <= (others => 'Z');
                vram_ad <= (others => 'Z');
            end if; --if (cpu_addr = PPUADDR and ppu_clk_cnt = "00") then

        else
            ppu_addr_we_n    <= '1';
            ppu_data_we_n    <= '1';
            plt_bus_ce_n <= '1';
            oam_bus_ce_n     <= '1';
            oam_addr_ce_n <= '1';
            ppu_addr_cnt_ce_n    <= '1';
            ppu_latch_rst_n <= '1';

            rd_n <= 'Z';
            wr_n <= 'Z';
            if ppu_mask(PPUSBG) = '1' or ppu_mask(PPUSSP) = '1' then
                ale <= 'Z';
            else
                ale <= '0';
            end if;
            oam_plt_data <= (others => 'Z');
            vram_ad <= (others => 'Z');
            vram_a <= (others => 'Z');
            cpu_d <= (others => 'Z');
        end if; --if (rst_n = '0') then
    end process;

end rtl;

