library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ppu is 
    port (
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
end ppu;

architecture rtl of ppu is
begin
    pio_cpu_d      <= (others => 'Z');

    po_v_ce_n       'Z';
    po_v_rd_n       'Z';
    po_v_wr_n       'Z';
    po_v_addr       <= (others => 'Z');
    pio_v_data      <= (others => 'Z');

    po_plt_ce_n     'Z';
    po_plt_rd_n     'Z';
    po_plt_wr_n     'Z';
    po_plt_addr     <= (others => 'Z');
    pio_plt_data    <= (others => 'Z');

    po_spr_ce_n     'Z';
    po_spr_rd_n     'Z';
    po_spr_wr_n     'Z';
    po_spr_addr     <= (others => 'Z');
    po_spr_data     <= (others => 'Z');

    po_ppu_ctrl        <= (others => 'Z');
    po_ppu_mask        <= (others => 'Z');
    po_ppu_scroll_x    <= (others => 'Z');
    po_ppu_scroll_y    <= (others => 'Z');
end rtl;
