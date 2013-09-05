library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity de1_nes is 
    port (  
		base_clk 	: in std_logic;
		rst_n     	: in std_logic;
		dbg_pin0	: out std_logic;
		dbg_pin1	: out std_logic;
		dbg_pin2	: out std_logic;
		dbg_pin3	: out std_logic;
		dbg_pin4	: out std_logic;
		dbg_pin5	: out std_logic;
		dbg_pin6	: out std_logic;
		dbg_pin7	: out std_logic
         );
end de1_nes;

architecture rtl of de1_nes is
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
				vga_clk     : out std_logic
            );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                R_nW        : in std_logic; 
                addr       : in std_logic_vector (abus_size - 1 downto 0);
                d_io       : inout std_logic_vector (dbus_size - 1 downto 0);
                ppu_ce_n    : out std_logic
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

    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant size14    : integer := 14;

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;

    signal rdy, irq_n, nmi_n, dbe, r_nw : std_logic;
    signal phi1, phi2 : std_logic;
    signal addr : std_logic_vector( addr_size - 1 downto 0);
    signal d_io : std_logic_vector( data_size - 1 downto 0);

    signal ppu_ce_n : std_logic;
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

begin

    irq_n <= '0';
    rdy <= '1';

    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, vga_clk);

    --mos 6502 cpu instance
    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (cpu_clk, rdy, rst_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, d_io);

    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
        port map (phi2, r_nw, addr, d_io, ppu_ce_n);

    --nes ppu instance
--    ppu_inst : ppu 
--        port map (ppu_clk, ppu_ce_n, rst_n, r_nw, addr(2 downto 0), d_io, 
--                nmi_n, rd_n, wr_n, ale, vram_ad, vram_a,
--                vga_clk, h_sync_n, v_sync_n, r, g, b);

--    ppu_addr_decoder : v_address_decoder generic map (size14, data_size) 
--        port map (ppu_clk, rd_n, wr_n, ale, vram_ad, vram_a);

-----debug-----
	dbg_pin0 <= cpu_clk;
	dbg_pin1 <= ppu_clk;
	dbg_pin2 <= vga_clk;

end rtl;

