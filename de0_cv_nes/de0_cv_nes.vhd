library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On DE0-CV Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity de0_cv_nes is 
    port (
--logic analyzer reference clock
    signal dbg_base_clk: out std_logic;
    
--NES instance
        pi_base_clk 	: in std_logic;
        pi_rst_n     	: in std_logic;
        pi_joypad1     : in std_logic_vector(7 downto 0);
        pi_joypad2     : in std_logic_vector(7 downto 0);
        po_h_sync_n    : out std_logic;
        po_v_sync_n    : out std_logic;
        po_r           : out std_logic_vector(3 downto 0);
        po_g           : out std_logic_vector(3 downto 0);
        po_b           : out std_logic_vector(3 downto 0);
        pi_nt_v_mirror : in std_logic;
        
        --for debugging..
        po_dbg_cnt     : out std_logic_vector (63 downto 0)
         );
end de0_cv_nes;

architecture rtl of de0_cv_nes is
    component mos6502
        port (
                pi_rst_n       : in std_logic;
                pi_base_clk    : in std_logic;
                pi_cpu_en      : in std_logic_vector (7 downto 0);
                pi_rdy         : in std_logic;
                pi_irq_n       : in std_logic;
                pi_nmi_n       : in std_logic;
                po_r_nw        : out std_logic;
                po_addr        : out std_logic_vector ( 15 downto 0);
                pio_d_io       : inout std_logic_vector ( 7 downto 0)
        );
    end component;

    component clock_selector
        port (
                pi_rst_n        : in std_logic;
                pi_base_clk     : in std_logic;
                po_cpu_en       : out std_logic_vector (7 downto 0);
                po_rnd_en       : out std_logic_vector (3 downto 0)
            );
    end component;

    component chip_selector
        port (
                pi_rst_n        : in std_logic;
                pi_base_clk     : in std_logic;
                pi_addr         : in std_logic_vector (15 downto 0);
                po_rom_ce_n     : out std_logic;
                po_ram_ce_n     : out std_logic;
                po_ppu_ce_n     : out std_logic;
                po_apu_ce_n     : out std_logic
            );
    end component;

    component prg_rom port (
                pi_rst_n        : in std_logic;
                pi_base_clk 	: in std_logic;
                pi_ce_n         : in std_logic;
                pi_addr         : in std_logic_vector (14 downto 0);
                pi_data         : out std_logic_vector (7 downto 0)
            );
    end component;

    component ppu port (
                pi_rst_n       : in std_logic;
                pi_base_clk    : in std_logic;
                pi_cpu_en      : in std_logic_vector (7 downto 0);
                pi_ce_n        : in std_logic;
                pi_r_nw        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d      : inout std_logic_vector (7 downto 0);

                po_v_ce_n       : out std_logic;
                po_v_rd_n       : out std_logic;
                po_v_wr_n       : out std_logic;
                po_v_addr       : out std_logic_vector (13 downto 0);
                pio_v_data      : inout std_logic_vector (7 downto 0);

                po_plt_ce_n     : out std_logic;
                po_plt_rd_n     : out std_logic;
                po_plt_wr_n     : out std_logic;
                po_plt_addr     : out std_logic_vector (4 downto 0);
                pio_plt_data    : inout std_logic_vector (7 downto 0);

                po_spr_ce_n     : out std_logic;
                po_spr_rd_n     : out std_logic;
                po_spr_wr_n     : out std_logic;
                po_spr_addr     : out std_logic_vector (7 downto 0);
                po_spr_data     : out std_logic_vector (7 downto 0);

                po_ppu_ctrl        : out std_logic_vector (7 downto 0);
                po_ppu_mask        : out std_logic_vector (7 downto 0);
                pi_ppu_status      : in std_logic_vector (7 downto 0);
                po_ppu_scroll_x    : out std_logic_vector (7 downto 0);
                po_ppu_scroll_y    : out std_logic_vector (7 downto 0)
    );
    end component;

    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (
                pi_base_clk     : in std_logic;
                pi_ce_n         : in std_logic;
                pi_oe_n         : in std_logic;
                pi_we_n         : in std_logic;
                pi_addr         : in std_logic_vector (abus_size - 1 downto 0);
                pio_d_io        : inout std_logic_vector (dbus_size - 1 downto 0)
            );
    end component;

    component palette_ram
        port (
                pi_base_clk     : in std_logic;
                pi_ce_n         : in std_logic;
                pi_oe_n         : in std_logic;
                pi_we_n         : in std_logic;
                pi_addr         : in std_logic_vector (4 downto 0);
                pio_d_io        : inout std_logic_vector (7 downto 0)
            );
    end component;

    component chr_rom
        port (  
                pi_base_clk     : in std_logic;
                pi_ce_n         : in std_logic;
                pi_addr         : in std_logic_vector (12 downto 0);
                po_data         : out std_logic_vector (7 downto 0)
            );
    end component;

    component v_chip_selector
        port (
                    pi_rst_n        : in std_logic;
                    pi_base_clk     : in std_logic;
                    pi_v_ce_n       : in std_logic;
                    pi_v_addr       : in std_logic_vector (13 downto 0);
                    pi_nt_v_mirror  : in std_logic;
                    po_pt_ce_n      : out std_logic;
                    po_nt0_ce_n     : out std_logic;
                    po_nt1_ce_n     : out std_logic
            );
    end component;

    component render
        port (
            pi_rst_n       : in std_logic;
            pi_base_clk    : in std_logic;
            pi_rnd_en      : in std_logic_vector (3 downto 0);

            --ppu i/f
            pi_ppu_ctrl        : in std_logic_vector (7 downto 0);
            pi_ppu_mask        : in std_logic_vector (7 downto 0);
            po_ppu_status      : out std_logic_vector (7 downto 0);
            pi_ppu_scroll_x    : in std_logic_vector (7 downto 0);
            pi_ppu_scroll_y    : in std_logic_vector (7 downto 0);

            --vram i/f
            po_v_ce_n       : out std_logic;
            po_v_rd_n       : out std_logic;
            po_v_wr_n       : out std_logic;
            po_v_addr       : out std_logic_vector (13 downto 0);
            pi_v_data       : in std_logic_vector (7 downto 0);

            --plt i/f
            po_plt_ce_n     : out std_logic;
            po_plt_rd_n     : out std_logic;
            po_plt_wr_n     : out std_logic;
            po_plt_addr     : out std_logic_vector (4 downto 0);
            pi_plt_data     : in std_logic_vector (7 downto 0);

            --sprite i/f
            po_spr_ce_n     : out std_logic;
            po_spr_rd_n     : out std_logic;
            po_spr_wr_n     : out std_logic;
            po_spr_addr     : out std_logic_vector (7 downto 0);
            pi_spr_data     : in std_logic_vector (7 downto 0);

            --vga output
            po_h_sync_n    : out std_logic;
            po_v_sync_n    : out std_logic;
            po_r           : out std_logic_vector(3 downto 0);
            po_g           : out std_logic_vector(3 downto 0);
            po_b           : out std_logic_vector(3 downto 0)
            );
    end component;

constant ram_2k     : integer := 11;    --2k = 11   bit width.
constant rom_32k    : integer := 15;    --32k = 15  bit width.
constant vram_1k    : integer := 10;    --1k = 10   bit width.

signal wr_cpu_en       : std_logic_vector (7 downto 0);
signal wr_rnd_en       : std_logic_vector (3 downto 0);

signal wr_rdy       : std_logic;
signal wr_irq_n     : std_logic;
signal wr_nmi_n     : std_logic;
signal wr_r_nw      : std_logic;
--r_n is negative logic of wr_r_nw.
signal lg_r_n       : std_logic;

signal wr_addr      : std_logic_vector ( 15 downto 0);
signal wr_d_io      : std_logic_vector ( 7 downto 0);

signal wr_rom_ce_n     : std_logic;
signal wr_ram_ce_n     : std_logic;
signal wr_ppu_ce_n     : std_logic;
signal wr_apu_ce_n     : std_logic;

signal wr_v_ce_n        : std_logic;
signal wr_v_rd_n        : std_logic;
signal wr_v_wr_n        : std_logic;
signal wr_v_addr        : std_logic_vector (13 downto 0);
signal wr_v_data        : std_logic_vector (7 downto 0);

signal wr_plt_ce_n      : std_logic;
signal wr_plt_rd_n      : std_logic;
signal wr_plt_wr_n      : std_logic;
signal wr_plt_addr      : std_logic_vector (4 downto 0);
signal wr_plt_data      : std_logic_vector (7 downto 0);

signal wr_spr_ce_n      : std_logic;
signal wr_spr_rd_n      : std_logic;
signal wr_spr_wr_n      : std_logic;
signal wr_spr_addr      : std_logic_vector (7 downto 0);
signal wr_spr_data      : std_logic_vector (7 downto 0);

signal wr_pt_ce_n       : std_logic;
signal wr_nt0_ce_n      : std_logic;
signal wr_nt1_ce_n      : std_logic;

signal wr_ppu_ctrl          : std_logic_vector (7 downto 0);
signal wr_ppu_mask          : std_logic_vector (7 downto 0);
signal wr_ppu_status        : std_logic_vector (7 downto 0);
signal wr_ppu_scroll_x      : std_logic_vector (7 downto 0);
signal wr_ppu_scroll_y      : std_logic_vector (7 downto 0);

signal reg_dbg_cnt          : std_logic_vector (63 downto 0);

begin

    dbg_base_clk <= pi_base_clk;

    --synchronized clock generator instance
    clock_selector_inst : clock_selector port map (
            pi_rst_n,
            pi_base_clk,
            wr_cpu_en,
            wr_rnd_en
            );

    --mos 6502 cpu instance
    cpu_inst : mos6502 port map (
            pi_rst_n, 
            pi_base_clk, 
            wr_cpu_en, 
            wr_rdy,
            wr_irq_n, 
            wr_nmi_n, 
            wr_r_nw, 
            wr_addr, 
            wr_d_io
            );

    --chip select (address decode)
    cs_inst : chip_selector port map (
            pi_rst_n,
            pi_base_clk, 
            wr_addr,
            wr_rom_ce_n,
            wr_ram_ce_n,
            wr_ppu_ce_n,
            wr_apu_ce_n
            );

    --program rom
    prom_inst : prg_rom port map (
            pi_rst_n,
            pi_base_clk, 
            wr_rom_ce_n,
            wr_addr(14 downto 0), 
            wr_d_io
            );

    lg_r_n <= not wr_r_nw;
    --cpu ram inst.
    cpu_ram_inst : ram generic map
        (ram_2k, 8) port map (
            pi_base_clk,
            wr_ram_ce_n,
            lg_r_n, 
            wr_r_nw, 
            wr_addr(10 downto 0), 
            wr_d_io
            );

    --ppu
    ppu_inst : ppu port map (
            pi_rst_n, 
            pi_base_clk, 
            wr_cpu_en,
            wr_ppu_ce_n,
            wr_r_nw, 
            wr_addr(2 downto 0), 
            wr_d_io,

            wr_v_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_v_addr,
            wr_v_data,

            wr_plt_ce_n,
            wr_plt_rd_n,
            wr_plt_wr_n,
            wr_plt_addr,
            wr_plt_data,

            wr_spr_ce_n,
            wr_spr_rd_n,
            wr_spr_wr_n,
            wr_spr_addr,
            wr_spr_data,

            --render i/f
            wr_ppu_ctrl,
            wr_ppu_mask,
            wr_ppu_status,
            wr_ppu_scroll_x,
            wr_ppu_scroll_y
            );

    --vram chip select (address decode)
    vcs_inst : v_chip_selector port map (
            pi_rst_n,
            pi_base_clk,
            wr_v_ce_n,
            wr_v_addr,
            pi_nt_v_mirror,
            wr_pt_ce_n,
            wr_nt0_ce_n,
            wr_nt1_ce_n
            );

    --name table/attr table #0
    vram_nt0_inst : ram generic map
        (vram_1k, 8) port map (
            pi_base_clk,
            wr_nt0_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_v_addr(vram_1k - 1 downto 0),
            wr_v_data
            );

    --name table/attr table #1
    vram_nt1_inst : ram generic map
        (vram_1k, 8) port map (
            pi_base_clk,
            wr_nt1_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_v_addr(vram_1k - 1 downto 0),
            wr_v_data
            );

    --palette table
    vram_plt_inst : palette_ram port map (
            pi_base_clk,
            wr_plt_ce_n,
            wr_plt_rd_n,
            wr_plt_wr_n,
            wr_plt_addr,
            wr_plt_data
            );

    --pattern table
    chr_rom_inst : chr_rom port map (
            pi_base_clk,
            wr_pt_ce_n,
            wr_v_addr(12 downto 0),
            wr_v_data
            );

    --palette table
    spr_ram_inst : ram generic map
            (8, 8) port map (
            pi_base_clk,
            wr_spr_ce_n,
            wr_spr_rd_n,
            wr_spr_wr_n,
            wr_spr_addr,
            wr_spr_data
            );

    --vga render instance
    render_inst : render port map (
            pi_rst_n, 
            pi_base_clk,
            wr_rnd_en,

            --ppu i/f
            wr_ppu_ctrl,
            wr_ppu_mask,
            wr_ppu_status,
            wr_ppu_scroll_x,
            wr_ppu_scroll_y,

            --vram i/f
            wr_v_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_v_addr,
            wr_v_data,

            --plt i/f
            wr_plt_ce_n,
            wr_plt_rd_n,
            wr_plt_wr_n,
            wr_plt_addr,
            wr_plt_data,

            --sprite i/f
            wr_spr_ce_n,
            wr_spr_rd_n,
            wr_spr_wr_n,
            wr_spr_addr,
            wr_spr_data,

            --vga output
            po_h_sync_n,
            po_v_sync_n,
            po_r,
            po_g,
            po_b
            );

    wr_rdy <= '1';
    wr_irq_n <= '1';
    wr_nmi_n <= '1';

    po_dbg_cnt <= reg_dbg_cnt;
    deb_cnt_p : process (pi_rst_n, pi_base_clk)
use ieee.std_logic_unsigned.all;
    variable cnt : integer;
    begin
        if (pi_rst_n = '0') then
            reg_dbg_cnt <= (others => '0');
            cnt := 0;
        else
            if (rising_edge(pi_base_clk)) then
                if (cnt = 0) then
                    --debug count is half cycle because too fast to capture in st ii.
                    reg_dbg_cnt <= reg_dbg_cnt + 1;
                    cnt := 1;
                else
                    cnt := 0;
                end if;
            end if;
        end if;
    end process;
end rtl;
