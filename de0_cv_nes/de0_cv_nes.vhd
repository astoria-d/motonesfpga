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
        pi_nt_v_mirror : in std_logic
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
                po_ppu_en       : out std_logic_vector (3 downto 0)
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

    component ppu port (
                pi_rst_n       : in std_logic;
                pi_base_clk    : in std_logic;
                pi_ppu_en      : in std_logic_vector (3 downto 0);
                pi_ce_n        : in std_logic;
                pi_r_nw        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d      : inout std_logic_vector (7 downto 0);

                po_rd_n        : out std_logic;
                po_wr_n        : out std_logic;
                po_ale_n       : out std_logic;
                po_vram_addr   : out std_logic_vector (13 downto 0);
                pio_vram_data  : inout std_logic_vector (7 downto 0)
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
                    pi_v_addr       : in std_logic_vector (13 downto 0);
                    pi_nt_v_mirror  : in std_logic;
                    po_pt_ce_n      : out std_logic;
                    po_nt0_ce_n     : out std_logic;
                    po_nt1_ce_n     : out std_logic;
                    po_plt_ce_n     : out std_logic
            );
    end component;

constant ram_2k     : integer := 11;    --2k = 11   bit width.
constant rom_32k    : integer := 15;    --32k = 15  bit width.
constant vram_1k    : integer := 10;    --1k = 10   bit width.

signal wr_cpu_en       : std_logic_vector (7 downto 0);
signal wr_ppu_en       : std_logic_vector (3 downto 0);

signal wr_rdy       : std_logic;
signal wr_irq_n     : std_logic;
signal wr_nmi_n     : std_logic;
signal wr_r_nw      : std_logic;

signal wr_addr      : std_logic_vector ( 15 downto 0);
signal wr_d_io      : std_logic_vector ( 7 downto 0);

signal wr_rom_ce_n     : std_logic;
signal wr_ram_ce_n     : std_logic;
signal wr_ppu_ce_n     : std_logic;
signal wr_apu_ce_n     : std_logic;

signal wr_v_rd_n        : std_logic;
signal wr_v_wr_n        : std_logic;
signal wr_v_ale_n       : std_logic;
signal wr_vram_addr     : std_logic_vector (13 downto 0);
signal wr_vram_data     : std_logic_vector (7 downto 0);

signal wr_pt_ce_n       : std_logic;
signal wr_nt0_ce_n      : std_logic;
signal wr_nt1_ce_n      : std_logic;
signal wr_plt_ce_n      : std_logic;


begin

    dbg_base_clk <= pi_base_clk;

    --synchronized clock generator instance
    clock_selector_inst : clock_selector port map (
            pi_rst_n,
            pi_base_clk,
            wr_cpu_en,
            wr_ppu_en
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

    --ppu
    ppu_inst : ppu port map (
            pi_rst_n, 
            pi_base_clk, 
            wr_ppu_en,
            wr_ppu_ce_n,
            wr_r_nw, 
            wr_addr(2 downto 0), 
            wr_d_io,

            wr_v_rd_n,
            wr_v_wr_n,
            wr_v_ale_n,
            wr_vram_addr,
            wr_vram_data
            );

    --vram chip select (address decode)
    vcs_inst : v_chip_selector port map (
            pi_rst_n,
            pi_base_clk, 
            wr_vram_addr,
            pi_nt_v_mirror,
            wr_pt_ce_n,
            wr_nt0_ce_n,
            wr_nt1_ce_n,
            wr_plt_ce_n
            );

    --name table/attr table #0
    vram_nt0_inst : ram generic map
        (vram_1k, 8) port map (
            pi_base_clk,
            wr_nt0_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_vram_addr(vram_1k - 1 downto 0),
            wr_vram_data
            );

    --name table/attr table #1
    vram_nt1_inst : ram generic map
        (vram_1k, 8) port map (
            pi_base_clk,
            wr_nt1_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_vram_addr(vram_1k - 1 downto 0),
            wr_vram_data
            );

    --palette table
    vram_plt_inst : palette_ram port map (
            pi_base_clk,
            wr_plt_ce_n,
            wr_v_rd_n,
            wr_v_wr_n,
            wr_vram_addr(4 downto 0),
            wr_vram_data
            );

    --pattern table
    chr_rom_inst : chr_rom port map (
            pi_base_clk,
            wr_pt_ce_n,
            wr_vram_addr(12 downto 0),
            wr_vram_data
            );

    wr_rdy <= '1';
    wr_irq_n <= '1';
    wr_nmi_n <= '1';

    po_h_sync_n    <= '0';
    po_v_sync_n    <= '0';
    po_r           <= (others => '0');
    po_g           <= (others => '0');
    po_b           <= (others => '0');
end rtl;
