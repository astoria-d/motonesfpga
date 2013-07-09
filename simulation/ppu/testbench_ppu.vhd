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

constant ppu_clk_time : time := 186 ns;
constant vga_clk_time : time := 40 ns;
constant size8  : integer := 8;
constant size14 : integer := 14;

constant test_init_time : time := 7 us;
constant test_reset_time : time := 20 us;

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

signal set_addr  : std_logic_vector (15 downto 0);

signal vga_clk     : std_logic;
signal h_sync_n    : std_logic;
signal v_sync_n    : std_logic;
signal r           : std_logic_vector(3 downto 0);
signal g           : std_logic_vector(3 downto 0);
signal b           : std_logic_vector(3 downto 0);

begin

    ppu_inst : ppu 
        port map (clk, ce_n, rst_n, r_nw, cpu_addr, cpu_d, 
                vblank_n, rd_n, wr_n, ale, vram_ad, vram_a,
                vga_clk, h_sync_n, v_sync_n, r, g, b);

    ppu_addr_decoder : v_address_decoder generic map (size14, size8) 
        port map (clk, rd_n, wr_n, ale, vram_ad, vram_a);

    dummy_vga_disp : vga_device 
        port map (vga_clk, rst_n, h_sync_n, v_sync_n, r, g, b);

    reset_p : process
    begin
        rst_n <= '1';
        wait for test_init_time;
        rst_n <= '0';
        wait for test_reset_time;
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

    --test data set.
    test_init_p : process
    variable i : integer := 0;
    begin
        wait for test_init_time + test_reset_time + ppu_clk_time / 2;
        ce_n <= '0';

        --disable show bg.
        r_nw <= '0';
        cpu_addr <= "001";
        cpu_d <= "00000000";
        wait for ppu_clk_time;

        --ppuctl set
        cpu_addr <= "000";
        cpu_d <= "00010010";
        wait for ppu_clk_time;

        --vram addr set
        r_nw <= '0';
        for i in 0 to 50 loop
            --name table set.
            cpu_addr <= "110";
            cpu_d <= conv_std_logic_vector(16#2800# + i, 16)(15 downto 8);
            wait for ppu_clk_time;
            cpu_d <= conv_std_logic_vector(16#2800# + i, 16)(7 downto 0);
            wait for ppu_clk_time;
            cpu_addr <= "111";
            cpu_d <= conv_std_logic_vector(i + 32, 8);
            wait for ppu_clk_time;
        end loop;

        for i in 0 to 13 loop
            --attr tbl set.
            cpu_addr <= "110";
            cpu_d <= conv_std_logic_vector(16#23c0# + i, 16)(15 downto 8);
            wait for ppu_clk_time;
            cpu_d <= conv_std_logic_vector(16#23c0# + i, 16)(7 downto 0);
            wait for ppu_clk_time;
            cpu_addr <= "111";
            cpu_d <= conv_std_logic_vector(16#5a# + 3 * i, 8);
            wait for ppu_clk_time;
        end loop;

        for i in 0 to 31 loop
            --palette tbl set.
            cpu_addr <= "110";
            cpu_d <= conv_std_logic_vector(16#3f00# + i, 16)(15 downto 8);
            wait for ppu_clk_time;
            cpu_d <= conv_std_logic_vector(16#3f00# + i, 16)(7 downto 0);
            wait for ppu_clk_time;
            cpu_addr <= "111";
            cpu_d <= conv_std_logic_vector((i - 1 ) * 4 + 17, 8);
            wait for ppu_clk_time;
        end loop;

        --enable show bg.
        r_nw <= '0';
        cpu_addr <= "001";
        cpu_d <= "00011000";
        wait for ppu_clk_time;

        ce_n <= '1';
        cpu_addr <= (others => 'Z');
        cpu_d <= (others => 'Z');
        wait;
    end process;

end stimulus ;

