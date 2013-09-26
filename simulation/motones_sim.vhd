library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity motones_sim is 
    port (
        base_clk 	: in std_logic;
        rst_n     	: in std_logic;
        joypad1     : in std_logic_vector(7 downto 0);
        joypad2     : in std_logic_vector(7 downto 0);
        vga_clk     : out std_logic;
        h_sync_n    : out std_logic;
        v_sync_n    : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0)
         );
end motones_sim;

architecture rtl of motones_sim is
    component mos6502
        generic (   dsize : integer := 8;
                    asize : integer :=16
                );
        port (  input_clk   : in std_logic; --phi0 input pin.
                rdy         : in std_logic;
                rst_n       : in std_logic;
                irq_n       : in std_logic;
                nmi_n       : in std_logic;
                dbe         : in std_logic;
                r_nw        : out std_logic;
                phi1        : out std_logic;
                phi2        : out std_logic;
                addr        : out std_logic_vector ( asize - 1 downto 0);
                d_io        : inout std_logic_vector ( dsize - 1 downto 0)
        );
    end component;

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                mem_clk     : out std_logic;
                vga_clk     : out std_logic
            );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                mem_clk     : in std_logic;
                R_nW        : in std_logic; 
                addr        : in std_logic_vector (abus_size - 1 downto 0);
                d_io        : in std_logic_vector (dbus_size - 1 downto 0);
                rom_ce_n    : out std_logic;
                ram_ce_n    : out std_logic;
                ppu_ce_n    : out std_logic;
                apu_ce_n    : out std_logic
    );
    end component;

    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  
                clk               : in std_logic;
                ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr              : in std_logic_vector (abus_size - 1 downto 0);
                d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component prg_rom
        generic (abus_size : integer := 15; dbus_size : integer := 8);
        port (
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component ppu
    port (  clk         : in std_logic;
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
    end component;

    component v_address_decoder
    generic (abus_size : integer := 14; dbus_size : integer := 8);
        port (  clk         : in std_logic; 
                rd_n        : in std_logic;
                wr_n        : in std_logic;
                ale         : in std_logic;
                v_addr      : in std_logic_vector (13 downto 0);
                v_data      : in std_logic_vector (7 downto 0);
                nt_v_mirror : in std_logic;
                pt_ce_n     : out std_logic;
                nt0_ce_n    : out std_logic;
                nt1_ce_n    : out std_logic
            );
    end component;

    component chr_rom
        generic (abus_size : integer := 13; dbus_size : integer := 8);
        port (  
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0);
                nt_v_mirror     : out std_logic
        );
    end component;

    component ls373
        generic (
            dsize : integer := 8
        );
        port (  c         : in std_logic;
                oc_n      : in std_logic;
                d         : in std_logic_vector(dsize - 1 downto 0);
                q         : out std_logic_vector(dsize - 1 downto 0)
        );
    end component;

    component apu
        port (  clk         : in std_logic;
                ce_n        : in std_logic;
                rst_n       : in std_logic;
                r_nw        : inout std_logic;
                cpu_addr    : inout std_logic_vector (15 downto 0);
                cpu_d       : inout std_logic_vector (7 downto 0);
                rdy         : out std_logic
        );
    end component;

    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant vram_size14    : integer := 14;

    constant ram_2k : integer := 11;      --2k = 11 bit width.
    constant rom_32k : integer := 15;     --32k = 15 bit width.
    constant vram_1k : integer := 10;      --1k = 10 bit width.
    constant chr_rom_8k : integer := 13;     --32k = 15 bit width.

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal mem_clk  : std_logic;
    signal vga_out_clk   : std_logic;

    signal rdy, irq_n, nmi_n, dbe, r_nw : std_logic;
    signal phi1, phi2 : std_logic;
    signal addr : std_logic_vector( addr_size - 1 downto 0);
    signal d_io : std_logic_vector( data_size - 1 downto 0);

    signal rom_ce_n : std_logic;
    signal ram_ce_n : std_logic;
    signal ram_oe_n : std_logic;
    signal ppu_ce_n : std_logic;
    signal apu_ce_n : std_logic;

    signal rd_n     : std_logic;
    signal wr_n     : std_logic;
    signal ale      : std_logic;
    signal vram_ad  : std_logic_vector (7 downto 0);
    signal vram_a   : std_logic_vector (13 downto 8);
    signal v_addr   : std_logic_vector (13 downto 0);
    signal nt_v_mirror  : std_logic;
    signal pt_ce_n  : std_logic;
    signal nt0_ce_n : std_logic;
    signal nt1_ce_n : std_logic;


begin

    irq_n <= '0';
    vga_clk <= vga_out_clk;

    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, mem_clk, vga_out_clk);

    --mos 6502 cpu instance
    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (cpu_clk, rdy, rst_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, d_io);

    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
        port map (phi2, mem_clk, r_nw, addr, d_io, rom_ce_n, ram_ce_n, ppu_ce_n, apu_ce_n);

    --main ROM/RAM instance
    prg_rom_inst : prg_rom generic map (rom_32k, data_size)
            port map (mem_clk, rom_ce_n, addr(rom_32k - 1 downto 0), d_io);

    ram_oe_n <= not R_nW;
    prg_ram_inst : ram generic map (ram_2k, data_size)
            port map (mem_clk, ram_ce_n, ram_oe_n, R_nW, addr(ram_2k - 1 downto 0), d_io);

    --nes ppu instance
    ppu_inst : ppu 
        port map (ppu_clk, mem_clk, ppu_ce_n, rst_n, r_nw, addr(2 downto 0), d_io, 
                nmi_n, rd_n, wr_n, ale, vram_ad, vram_a,
                vga_out_clk, h_sync_n, v_sync_n, r, g, b);

    ppu_addr_decoder : v_address_decoder generic map (vram_size14, data_size) 
        port map (ppu_clk, rd_n, wr_n, ale, v_addr, vram_ad, 
                nt_v_mirror, pt_ce_n, nt0_ce_n, nt1_ce_n);

    ---VRAM/CHR ROM instances
    v_addr (13 downto 8) <= vram_a;

    --transparent d-latch
    vram_latch : ls373 generic map (data_size)
                port map(ale, '0', vram_ad, v_addr(7 downto 0));

    vchr_rom : chr_rom generic map (chr_rom_8k, data_size)
            port map (mem_clk, pt_ce_n, v_addr(chr_rom_8k - 1 downto 0), vram_ad, nt_v_mirror);

    --name table/attr table
    vram_nt0 : ram generic map (vram_1k, data_size)
            port map (mem_clk, nt0_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    vram_nt1 : ram generic map (vram_1k, data_size)
            port map (mem_clk, nt1_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    --APU/DMA instance
    apu_inst : apu
        port map (cpu_clk, apu_ce_n, rst_n, r_nw, addr, d_io, rdy);

end rtl;

