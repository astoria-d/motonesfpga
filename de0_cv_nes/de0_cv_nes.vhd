library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
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
                pi_base_clk 	: in std_logic;
                pi_rdy         : in std_logic;
                pi_rst_n       : in std_logic;
                pi_irq_n       : in std_logic;
                pi_nmi_n       : in std_logic;
                po_r_nw        : out std_logic;
                po_addr        : out std_logic_vector ( 15 downto 0);
                pio_d_io       : inout std_logic_vector ( 7 downto 0)
        );
    end component;

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                emu_ppu_clk : out std_logic;
                vga_clk     : out std_logic;
                cpu_mem_clk     : out std_logic;
                cpu_recv_clk     : out std_logic;
                emu_ppu_mem_clk : out std_logic
            );
    end component;

    component address_decoder
        port (
                addr        : in std_logic_vector (15 downto 0);
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

    component rom
        generic (abus_size : integer := 15; dbus_size : integer := 8);
        port (
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component ppu port (
                base_clk    : in std_logic;
                ce_n        : in std_logic;
                rst_n       : in std_logic;
                r_nw        : in std_logic;
                cpu_addr    : in std_logic_vector (2 downto 0);
                cpu_d       : inout std_logic_vector (7 downto 0);

                rd_n        : out std_logic;
                wr_n        : out std_logic;
                ale_n       : out std_logic;
                vram_addr   : out std_logic_vector (13 downto 0);
                vram_data   : inout std_logic_vector (7 downto 0)
    );
    end component;

    component v_address_decoder
        port (
                v_addr      : in std_logic_vector (13 downto 0);
                nt_v_mirror : in std_logic;
                pt_ce_n     : out std_logic;
                nt0_ce_n    : out std_logic;
                nt1_ce_n    : out std_logic
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

begin

    dbg_base_clk <= pi_base_clk;

    po_h_sync_n    <= '0';
    po_v_sync_n    <= '0';
    po_r           <= (others => '0');
    po_g           <= (others => '0');
    po_b           <= (others => '0');
end rtl;

