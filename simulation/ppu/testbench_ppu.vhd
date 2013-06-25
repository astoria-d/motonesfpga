
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
            vram_a      : out std_logic_vector (13 downto 8)
    );
    end component;

constant ppu_clk : time := 196 ns;

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

begin

    ppu_inst : ppu 
        port map (clk, ce_n, rst_n, r_nw, cpu_addr, cpu_d, 
                vblank_n, rd_n, wr_n, ale, vram_ad, vram_a);

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
        wait for ppu_clk / 2;
        clk <= '0';
        wait for ppu_clk / 2;
    end process;


end stimulus ;

