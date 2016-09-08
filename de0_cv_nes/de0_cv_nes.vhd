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
                pi_cpu_en       : in std_logic_vector (7 downto 0);
                pi_rdy         : in std_logic;
                pi_rst_n       : in std_logic;
                pi_irq_n       : in std_logic;
                pi_nmi_n       : in std_logic;
                po_r_nw        : out std_logic;
                po_addr        : out std_logic_vector ( 15 downto 0);
                pio_d_io       : inout std_logic_vector ( 7 downto 0)
        );
    end component;

    component chip_selector
        port (  
                pi_rst_n        : in std_logic;
                pi_base_clk     : in std_logic;
                po_cpu_en       : out std_logic_vector (7 downto 0);
                po_ppu_en       : out std_logic_vector (3 downto 0)
            );
    end component;

    component ppu port (
                pi_base_clk    : in std_logic;
                pi_ce_n        : in std_logic;
                pi_rst_n       : in std_logic;
                pi_r_nw        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d       : inout std_logic_vector (7 downto 0);

                po_rd_n        : out std_logic;
                po_wr_n        : out std_logic;
                po_ale_n       : out std_logic;
                po_vram_addr   : out std_logic_vector (13 downto 0);
                pio_vram_data   : inout std_logic_vector (7 downto 0)
    );
    end component;

    component v_address_decoder
        port (
                pi_v_addr      : in std_logic_vector (13 downto 0);
                pi_nt_v_mirror : in std_logic;
                po_pt_ce_n     : out std_logic;
                po_nt0_ce_n    : out std_logic;
                po_nt1_ce_n    : out std_logic
            );
    end component;

signal wr_cpu_en       : std_logic_vector (7 downto 0);
signal wr_ppu_en       : std_logic_vector (3 downto 0);

signal wr_rdy       : std_logic;
signal wr_irq_n     : std_logic;
signal wr_nmi_n     : std_logic;
signal wr_r_nw      : std_logic;

signal wr_addr      : std_logic_vector ( 15 downto 0);
signal wr_d_io      : std_logic_vector ( 7 downto 0);

begin

    dbg_base_clk <= pi_base_clk;

    chip_selector_inst : chip_selector port map
        (pi_rst_n, pi_base_clk, wr_cpu_en, wr_ppu_en);

    --mos 6502 cpu instance
    cpu_inst : mos6502 port map (
            pi_base_clk, 
            wr_cpu_en, 
            wr_rdy,
            pi_rst_n, 
            wr_irq_n, 
            wr_nmi_n, 
            wr_r_nw, 
            wr_addr, 
            wr_d_io
            );

    wr_rdy <= '0';
    wr_irq_n <= '0';
    wr_nmi_n <= '0';

    po_h_sync_n    <= '0';
    po_v_sync_n    <= '0';
    po_r           <= (others => '0');
    po_g           <= (others => '0');
    po_b           <= (others => '0');
end rtl;

