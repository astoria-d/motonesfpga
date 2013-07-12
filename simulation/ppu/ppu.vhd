library ieee;
use ieee.std_logic_1164.all;

entity ppu is 
    port (  clk         : in std_logic;
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

component ppu_render
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
            plt_bus_ce_n    : in std_logic;
            oma_plt_addr    : in std_logic_vector (7 downto 0);
            oma_plt_data    : inout std_logic_vector (7 downto 0)
    );
end component;

component vga_ctl
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

signal pos_x       : std_logic_vector (8 downto 0);
signal pos_y       : std_logic_vector (8 downto 0);
signal nes_r       : std_logic_vector (3 downto 0);
signal nes_g       : std_logic_vector (3 downto 0);
signal nes_b       : std_logic_vector (3 downto 0);

constant dsize     : integer := 8;

constant PPUCTRL   : std_logic_vector(2 downto 0) := "000";
constant PPUMASK   : std_logic_vector(2 downto 0) := "001";
constant PPUSTATUS : std_logic_vector(2 downto 0) := "010";
constant OAMADDR   : std_logic_vector(2 downto 0) := "011";
constant OAMDATA   : std_logic_vector(2 downto 0) := "100";
constant PPUSCROLL : std_logic_vector(2 downto 0) := "101";
constant PPUADDR   : std_logic_vector(2 downto 0) := "110";
constant PPUDATA   : std_logic_vector(2 downto 0) := "111";

signal clk_n            : std_logic;

signal ppu_clk_cnt_res_n    : std_logic;
signal ppu_clk_cnt          : std_logic_vector(1 downto 0);

signal ppu_ctrl_we_n    : std_logic;
signal ppu_mask_we_n    : std_logic;
signal ppu_status_we_n  : std_logic;
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
signal ppu_status       : std_logic_vector (dsize - 1 downto 0);
signal oam_addr         : std_logic_vector (dsize - 1 downto 0);
signal oam_data         : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_x     : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_y     : std_logic_vector (dsize - 1 downto 0);
signal ppu_scroll_cnt   : std_logic_vector (0 downto 0);
signal ppu_addr         : std_logic_vector (13 downto 0);
signal ppu_addr_in      : std_logic_vector (13 downto 0);
signal ppu_addr_cnt     : std_logic_vector (0 downto 0);
signal ppu_data         : std_logic_vector (dsize - 1 downto 0);

signal oam_bus_ce_n     : std_logic;
signal plt_bus_ce_n     : std_logic;

signal oma_plt_addr     : std_logic_vector (7 downto 0);
signal oma_plt_data     : std_logic_vector (7 downto 0);

begin

    render_inst : ppu_render port map (clk, rst_n, vblank_n, 
            rd_n, wr_n, ale, vram_ad, vram_a,
            pos_x, pos_y, nes_r, nes_g, nes_b,
            ppu_ctrl, ppu_mask, ppu_status, ppu_scroll_x, ppu_scroll_y,
            r_nw, oam_bus_ce_n, plt_bus_ce_n, 
            oma_plt_addr, oma_plt_data);

    vga_inst : vga_ctl port map (clk, vga_clk, rst_n, 
            pos_x, pos_y, nes_r, nes_g, nes_b,
            h_sync_n, v_sync_n, r, g, b);

    --PPU registers.
    clk_n <= not clk;

    ppu_clk_cnt_inst : counter_register generic map (2, 1)
            port map (clk_n, ppu_clk_cnt_res_n, '1', '0', (others => '0'), ppu_clk_cnt); 

    ppu_ctrl_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ppu_ctrl_we_n, cpu_d, ppu_ctrl);

    ppu_mask_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ppu_mask_we_n, cpu_d, ppu_mask);

    ppu_status_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ppu_status_we_n, cpu_d, ppu_status);

    oma_addr_inst : counter_register generic map(dsize, 1)
            port map (clk_n, rst_n, oam_addr_we_n, oam_addr_ce_n, cpu_d, oam_addr);
    oma_data_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', oam_data_we_n, cpu_d, oam_data);

    ppu_scroll_x_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ppu_scroll_x_we_n, cpu_d, ppu_scroll_x);
    ppu_scroll_y_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ppu_scroll_y_we_n, cpu_d, ppu_scroll_y);
    ppu_scroll_cnt_inst : counter_register generic map (1, 1)
            port map (clk_n, rst_n, '1', ppu_scroll_cnt_ce_n, (others => '0'), ppu_scroll_cnt);

    ppu_addr_inst : counter_register generic map(14, 1)
            port map (clk_n, rst_n, ppu_addr_we_n, ppu_data_we_n, ppu_addr_in, ppu_addr);
    ppu_addr_cnt_inst : counter_register generic map (1, 1)
            port map (clk_n, rst_n, '1', ppu_addr_cnt_ce_n, (others => '0'), ppu_addr_cnt);
    ppu_data_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', ppu_data_we_n, cpu_d, ppu_data);


    reg_set_p : process (rst_n, ce_n, r_nw, cpu_addr, cpu_d)
    begin

        if (rst_n = '1' and ce_n = '0') then

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

            if(cpu_addr = PPUSTATUS) then
                ppu_status_we_n <= '0';
            else
                ppu_status_we_n <= '1';
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

            if(cpu_addr = PPUADDR) then
                ppu_addr_cnt_ce_n <= '0';
                ppu_addr_we_n <= '0';
                if (ppu_addr_cnt(0) = '0') then
                    ppu_addr_in <= cpu_d(5 downto 0) & ppu_addr(7 downto 0);
                else
                    ppu_addr_in <= ppu_addr(13 downto 8) & cpu_d;
                end if;
            else
                ppu_addr_cnt_ce_n <= '1';
                ppu_addr_we_n <= '1';
            end if;
        else
            ppu_ctrl_we_n    <= '1';
            ppu_mask_we_n    <= '1';
            ppu_status_we_n  <= '1';
            oam_addr_we_n    <= '1';
            oam_data_we_n    <= '1';
            ppu_scroll_x_we_n    <= '1';
            ppu_scroll_y_we_n    <= '1';
            ppu_scroll_cnt_ce_n  <= '1';
            ppu_addr_we_n        <= '1';
            ppu_addr_cnt_ce_n    <= '1';
        end if; --if (rst_n = '1' and ce_n = '0') 

    end process;

    --cpu and ppu clock timing adjustment...
    clk_cnt_set_p : process (rst_n, ce_n, r_nw, cpu_addr, cpu_d, clk)
    begin
        if (rst_n = '1' and ce_n = '0') then
            --set counter=0 on register write.   
            if (ce_n'event or r_nw'event or cpu_addr'event or cpu_d'event) then
                ppu_clk_cnt_res_n <= '0';
                --d_print("write event");
            end if;

            --start counter.
            if (clk'event and clk = '0') then
                if (ppu_clk_cnt = "10") then
                    ppu_clk_cnt_res_n <= '0';
                elsif (ppu_clk_cnt = "00") then
                    ppu_clk_cnt_res_n <= '1';
                end if;
                --d_print("clk event");
            end if;

            --oam data set
            if (cpu_addr = OAMDATA and ppu_clk_cnt = "00") then
                oam_bus_ce_n <= '0';
                oma_plt_addr <= oam_addr;
                oma_plt_data <= cpu_d;
                --address increment for burst write. 
                oam_addr_ce_n <= '0';
            else
                oam_addr_ce_n <= '1';
                oam_bus_ce_n <= '1';
            end if;

            --vram address access.
            if (cpu_addr = PPUADDR and ppu_clk_cnt = "00") then
                if (ppu_addr_cnt(0) = '0') then
                    --load addr high
                    ale <= '0';
                else
                    --load addr low and output vram/plt bus.

                    --if address is 3fxx, set palette table.
                    if (ppu_addr(13 downto 8) = "111111") then
                        oma_plt_addr <= cpu_d;
                        ale <= '0';
                    else
                        vram_ad <= cpu_d;
                        vram_a <= ppu_addr(13 downto 8);
                        ale <= '1';
                    end if;
                end if;
            elsif (cpu_addr = PPUDATA and ppu_clk_cnt = "01") then
                --for burst write.
                if (ppu_addr(13 downto 8) = "111111") then
                    oma_plt_addr <= ppu_addr(7 downto 0);
                    ale <= '0';
                else
                    vram_a <= ppu_addr(13 downto 8);
                    vram_ad <= ppu_addr(7 downto 0);
                    ale <= '1';
                end if;
            else
                ale <= '0';
            end if;

            if (cpu_addr = PPUDATA and ppu_clk_cnt = "00") then
                ppu_data_we_n <= '0';
                if (ppu_addr(13 downto 8) = "111111") then
                    --case palette tbl.
                    plt_bus_ce_n <= '0';
                    oma_plt_data <= cpu_d;
                    rd_n <= '1';
                    wr_n <= '1';
                else
                    rd_n <= not r_nw;
                    wr_n <= r_nw;
                    plt_bus_ce_n <= '1';
                    if (r_nw = '0') then
                        vram_ad <= cpu_d;
                    end if;
                end if;
            else
                plt_bus_ce_n <= '1';
                ppu_data_we_n <= '1';
                rd_n <= '1';
                wr_n <= '1';
            end if;

        else
            ppu_data_we_n    <= '1';
            plt_bus_ce_n <= '1';
            ppu_clk_cnt_res_n <= '0';
            oam_bus_ce_n     <= '1';
            oam_addr_ce_n <= '1';

            rd_n <= 'Z';
            wr_n <= 'Z';
            ale <= 'Z';
            vram_ad <= (others => 'Z');
            vram_a <= (others => 'Z');
        end if;
    end process;

end rtl;

