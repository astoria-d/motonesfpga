library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ppu is 
    port (
                pi_rst_n       : in std_logic;
                pi_base_clk    : in std_logic;
                pi_cpu_en      : in std_logic_vector (7 downto 0);
                pi_ce_n        : in std_logic;
                pi_oe_n        : in std_logic;
                pi_we_n        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d      : inout std_logic_vector (7 downto 0);
                po_vblank_n    : out std_logic;

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
    po_vblank_n    <= '1';

    po_v_ce_n       <= 'Z';
    po_v_rd_n       <= 'Z';
    po_v_wr_n       <= 'Z';
    po_v_addr       <= (others => 'Z');
    pio_v_data      <= (others => 'Z');

    po_plt_ce_n     <= 'Z';
    po_plt_rd_n     <= 'Z';
    po_plt_wr_n     <= 'Z';
    po_plt_addr     <= (others => 'Z');
    pio_plt_data    <= (others => 'Z');

    po_spr_ce_n     <= 'Z';
    po_spr_rd_n     <= 'Z';
    po_spr_wr_n     <= 'Z';
    po_spr_addr     <= (others => 'Z');
    po_spr_data     <= (others => 'Z');

    po_ppu_ctrl        <= (others => 'Z');
    po_ppu_mask        <= (others => 'Z');
    po_ppu_scroll_x    <= (others => 'Z');
    po_ppu_scroll_y    <= (others => 'Z');

--    --- initiate nmi.
--    nmi_p: process
--    constant nmi_wait     : time := 880us;
--    constant vblank_time     : time := 1000 us;
--    begin
--        po_vblank_n <= '1';
--        wait for nmi_wait;
--        po_vblank_n <= '0';
--        wait for vblank_time ;
--    end process;

end rtl;



--------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;

entity render is 
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
end render;

architecture rtl of render is

begin

        po_ppu_status      <= (others => 'Z');

        --vram i/f
        po_v_ce_n       <= 'Z';
        po_v_rd_n       <= 'Z';
        po_v_wr_n       <= 'Z';
        po_v_addr       <= (others => 'Z');

        --plt i/f
        po_plt_ce_n     <= 'Z';
        po_plt_rd_n     <= 'Z';
        po_plt_wr_n     <= 'Z';
        po_plt_addr     <= (others => 'Z');

        --sprite i/f
        po_spr_ce_n     <= 'Z';
        po_spr_rd_n     <= 'Z';
        po_spr_wr_n     <= 'Z';
        po_spr_addr     <= (others => 'Z');

        --vga output
        po_h_sync_n    <= 'Z';
        po_v_sync_n    <= 'Z';
        po_r           <= (others => 'Z');
        po_g           <= (others => 'Z');
        po_b           <= (others => 'Z');
end rtl;


--------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use std.textio.all;

entity chr_rom is 
    port (  
            pi_base_clk     : in std_logic;
            pi_ce_n         : in std_logic;
            pi_oe_n         : in std_logic;
            pi_addr         : in std_logic_vector (12 downto 0);
            po_data         : out std_logic_vector (7 downto 0)
        );
end chr_rom;

architecture rtl of chr_rom is

begin
    po_data     <= (others => 'Z');
end rtl;
