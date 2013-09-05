library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity motones_sim is 
    port (  rst_n     : in std_logic
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
                ppu_clk     : out std_logic
            );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
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

    component vga_device
    port (  vga_clk     : in std_logic;
            rst_n       : in std_logic;
            h_sync_n    : in std_logic;
            v_sync_n    : in std_logic;
            r           : in std_logic_vector(3 downto 0);
            g           : in std_logic_vector(3 downto 0);
            b           : in std_logic_vector(3 downto 0)
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

    ---clock frequency = 21,477,270 (21 MHz)
    constant base_clock_time : time := 46 ns;
    constant vga_clk_time : time := 40 ns;
    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant size14    : integer := 14;

    signal base_clk : std_logic;
    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;

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

    signal vga_clk     : std_logic;
    signal h_sync_n    : std_logic;
    signal v_sync_n    : std_logic;
    signal r           : std_logic_vector(3 downto 0);
    signal g           : std_logic_vector(3 downto 0);
    signal b           : std_logic_vector(3 downto 0);

    --test...
    signal nmi_n2 : std_logic;

begin

    irq_n <= '0';

    --- generate base clock.
    clock_p: process
    begin
        base_clk <= '1';
        wait for base_clock_time / 2;
        base_clk <= '0';
        wait for base_clock_time / 2;
    end process;

    --- generate test vga clock.
    vga_clock_p : process
    begin
        vga_clk <= '1';
        wait for vga_clk_time / 2;
        vga_clk <= '0';
        wait for vga_clk_time / 2;
    end process;

    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk);

    --mos 6502 cpu instance
    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (cpu_clk, rdy, rst_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, d_io);

    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
        port map (phi2, r_nw, addr, d_io, ppu_ce_n, apu_ce_n);

    --nes ppu instance
    ppu_inst : ppu 
        port map (ppu_clk, ppu_ce_n, rst_n, r_nw, addr(2 downto 0), d_io, 
                nmi_n, rd_n, wr_n, ale, vram_ad, vram_a,
                vga_clk, h_sync_n, v_sync_n, r, g, b);

    ppu_addr_decoder : v_address_decoder generic map (size14, data_size) 
        port map (ppu_clk, rd_n, wr_n, ale, vram_ad, vram_a);

    apu_inst : apu
        port map (cpu_clk, apu_ce_n, rst_n, r_nw, addr, d_io, rdy);

    dummy_vga_disp : vga_device 
        port map (vga_clk, rst_n, h_sync_n, v_sync_n, r, g, b);

--    nmi_p: process
--    constant powerup_time : time := 5000 ns;
--    constant reset_time : time := 10 us;
--    begin
--        wait for powerup_time;
--        nmi_n  <= '1';
--        wait for reset_time;
--        wait for 46 us;
--        nmi_n  <= '0';
--
--        wait;
--    end process;

end rtl;

