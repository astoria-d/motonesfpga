library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity testbench_apu is
end testbench_apu;

architecture stimulus of testbench_apu is 
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

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic
            );
    end component;

constant base_clk_time : time := 46 ns;
constant ppu_clk_time : time := (base_clk_time * 4);
constant cpu_clk_time : time := (base_clk_time * 12);
constant vga_clk_time : time := 40 ns;
constant size8  : integer := 8;
constant size14 : integer := 14;

constant test_init_time : time := 5 us;
constant test_reset_time : time := 10 us;

signal base_clk : std_logic;
signal cpu_clk  : std_logic;
signal ppu_clk  : std_logic;
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
signal h_sync_n    : std_logic;
signal v_sync_n    : std_logic;
signal r           : std_logic_vector(3 downto 0);
signal g           : std_logic_vector(3 downto 0);
signal b           : std_logic_vector(3 downto 0);

begin


end stimulus ;

