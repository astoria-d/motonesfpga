library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity de1_nes is 
    port (
--debug signal
    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_mem_clk  : out std_logic;
    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : out std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : out std_logic_vector (7 downto 0);
    signal dbg_vram_a   : out std_logic_vector (13 downto 8);
---monitor inside cpu
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : out std_logic_vector(7 downto 0);

--NES instance
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
end de1_nes;

architecture rtl of de1_nes is
    component mos6502
        generic (   dsize : integer := 8;
                    asize : integer :=16
                );
        port (  
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : out std_logic_vector(7 downto 0);

                input_clk   : in std_logic; --phi0 input pin.
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
        port (
                phi2        : in std_logic;
                mem_clk     : in std_logic;
                R_nW        : in std_logic; 
                addr       : in std_logic_vector (abus_size - 1 downto 0);
                d_io       : inout std_logic_vector (dbus_size - 1 downto 0);
                ppu_ce_n    : out std_logic;
                apu_ce_n    : out std_logic
    );
    end component;

    component ppu
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
    end component;

    component v_address_decoder
    generic (abus_size : integer := 14; dbus_size : integer := 8);
        port (  clk         : in std_logic; 
                rd_n        : in std_logic;
                wr_n        : in std_logic;
                ale         : in std_logic;
                vram_ad     : inout std_logic_vector (7 downto 0);
                vram_a      : in std_logic_vector (13 downto 8)
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
    constant size14    : integer := 14;

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal mem_clk  : std_logic;
    signal vga_out_clk   : std_logic;

    signal rdy, irq_n, nmi_n, dbe, r_nw : std_logic;
    signal phi1, phi2 : std_logic;
    signal addr : std_logic_vector( addr_size - 1 downto 0);
    signal d_io : std_logic_vector( data_size - 1 downto 0);

    signal ppu_ce_n : std_logic;
    signal apu_ce_n : std_logic;
    signal rd_n     : std_logic;
    signal wr_n     : std_logic;
    signal ale      : std_logic;
    signal vram_ad  : std_logic_vector (7 downto 0);
    signal vram_a   : std_logic_vector (13 downto 8);

component single_port_rom
    generic 
    (
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 8
    );
    port 
    (
        clk		: in std_logic;
        ce		: in std_logic;
        addr            : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
        q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
    );
end component;

begin

    irq_n <= '0';
    vga_clk <= vga_out_clk;

    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, mem_clk, vga_out_clk);

    --mos 6502 cpu instance
    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (
    dbg_instruction,
    dbg_int_d_bus,
                cpu_clk, rdy, rst_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, d_io);

--    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
--        port map (phi2, mem_clk, r_nw, addr, d_io, ppu_ce_n, apu_ce_n);

    rom_inst : single_port_rom generic map (8, 15) port map
        (base_clk, '0', addr(14 downto 0), d_io);

--    --nes ppu instance
--    ppu_inst : ppu 
--        port map (ppu_clk, ppu_ce_n, rst_n, r_nw, addr(2 downto 0), d_io, 
--                nmi_n, rd_n, wr_n, ale, vram_ad, vram_a,
--                vga_out_clk, h_sync_n, v_sync_n, r, g, b);

--    ppu_addr_decoder : v_address_decoder generic map (size14, data_size) 
--        port map (ppu_clk, rd_n, wr_n, ale, vram_ad, vram_a);

    apu_inst : apu
        port map (cpu_clk, apu_ce_n, rst_n, r_nw, addr, d_io, rdy);

    dbg_cpu_clk <= cpu_clk;
    dbg_ppu_clk <= ppu_clk;
    dbg_mem_clk <= mem_clk;
    dbg_addr <= addr;
--    dbg_d_io <= d_io;
--    dbg_vram_ad  <= vram_ad ;
--    dbg_vram_a   <= vram_a  ;


end rtl;

