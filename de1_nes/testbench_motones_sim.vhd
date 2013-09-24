library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity testbench_motones_sim is
end testbench_motones_sim;

architecture stimulus of testbench_motones_sim is 
    component de1_nes
        port (
--debug signal
    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_mem_clk  : out std_logic;
    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : inout std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : out std_logic_vector (7 downto 0);
    signal dbg_vram_a   : out std_logic_vector (13 downto 8);

---monitor inside cpu
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : out std_logic_vector(7 downto 0);
--NES instance
            base_clk 	: in std_logic;
            rst_n     	: in std_logic;
            joypad1     : in std_logic_vector(7 downto 0);
            joypad2     : in std_logic_vector(7 downto 0);
            vga_clk     : out std_logic;
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)
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

    signal base_clk         : std_logic;
    signal vga_clk         : std_logic;
    signal reset_input      : std_logic;

    signal h_sync_n    : std_logic;
    signal v_sync_n    : std_logic;
    signal r           : std_logic_vector(3 downto 0);
    signal g           : std_logic_vector(3 downto 0);
    signal b           : std_logic_vector(3 downto 0);
    signal joypad1     : std_logic_vector(7 downto 0);
    signal joypad2     : std_logic_vector(7 downto 0);

    constant powerup_time   : time := 2 us;
    constant reset_time     : time := 2 us;

    ---clock frequency = 21,477,270 (21 MHz)
    --constant base_clock_time : time := 46 ns;

    --DE1 base clock = 50 MHz
    constant base_clock_time : time := 20 ns;

    signal dbg_cpu_clk  : std_logic;
    signal dbg_ppu_clk  : std_logic;
    signal dbg_mem_clk  : std_logic;
    signal dbg_addr : std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : std_logic_vector (7 downto 0);
    signal dbg_vram_a   : std_logic_vector (13 downto 8);
    signal dbg_instruction  : std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : std_logic_vector(7 downto 0);

begin

    sim_board : de1_nes port map (
dbg_cpu_clk,
dbg_ppu_clk,
dbg_mem_clk,
dbg_addr,
dbg_d_io,
dbg_vram_ad,
dbg_vram_a,
dbg_instruction,
dbg_int_d_bus,
    
    base_clk, reset_input, joypad1, joypad2, 
            vga_clk, h_sync_n, v_sync_n, r, g, b);

--    dummy_vga_disp : vga_device 
--        port map (vga_clk, reset_input, h_sync_n, v_sync_n, r, g, b);

    --- input reset.
    reset_p: process
    begin
        wait for powerup_time;
        reset_input <= '0';

        wait for reset_time;
        reset_input <= '1';

        wait;
    end process;

    --- generate base clock.
    clock_p: process
    begin
        base_clk <= '1';
        wait for base_clock_time / 2;
        base_clk <= '0';
        wait for base_clock_time / 2;
    end process;

end stimulus;

