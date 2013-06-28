
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity testbench_ppu is
end testbench_ppu;

architecture stimulus of testbench_ppu is 
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
            h_sync      : out std_logic;
            v_sync      : out std_logic;
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
        port (  
            vga_clk     : in std_logic;
            h_sync      : in std_logic;
            v_sync      : in std_logic;
            r           : in std_logic_vector(3 downto 0);
            g           : in std_logic_vector(3 downto 0);
            b           : in std_logic_vector(3 downto 0)
            );
    end component;

constant ppu_clk_time : time := 186 ns;
constant vga_clk_time : time := 40 ns;
constant size8  : integer := 8;
constant size14 : integer := 14;

signal clk      : std_logic;
signal ce_n     : std_logic;
signal rst_n    : std_logic;
signal r_nw     : std_logic;
signal cpu_addr : std_logic_vector (2 downto 0);
signal cpu_d    : std_logic_vector (7 downto 0);
signal vblank_n : std_logic;
signal rd_n     : std_logic;
signal wr_n     : std_logic;
signal ale      : std_logic;
signal vram_ad  : std_logic_vector (7 downto 0);
signal vram_a   : std_logic_vector (13 downto 8);

signal vga_clk     : std_logic;
signal h_sync      : std_logic;
signal v_sync      : std_logic;
signal r           : std_logic_vector(3 downto 0);
signal g           : std_logic_vector(3 downto 0);
signal b           : std_logic_vector(3 downto 0);

begin

    ppu_inst : ppu 
        port map (clk, ce_n, rst_n, r_nw, cpu_addr, cpu_d, 
                vblank_n, rd_n, wr_n, ale, vram_ad, vram_a,
                vga_clk, h_sync, v_sync, r, g, b);

    ppu_addr_decoder : v_address_decoder generic map (size14, size8) 
        port map (clk, rd_n, wr_n, ale, vram_ad, vram_a);

    dummy_vga_disp : vga_device 
        port map (vga_clk, h_sync, v_sync, r, g, b);

    reset_p : process
    begin
        rst_n <= '1';
        wait for 5 us;
        rst_n <= '0';
        wait for 10 us;
        rst_n <= '1';
        wait;
    end process;

    clock_p : process
    begin
        clk <= '1';
        wait for ppu_clk_time / 2;
        clk <= '0';
        wait for ppu_clk_time / 2;
    end process;

    vga_clock_p : process
    begin
        vga_clk <= '1';
        wait for vga_clk_time / 2;
        vga_clk <= '0';
        wait for vga_clk_time / 2;
    end process;

end stimulus ;

