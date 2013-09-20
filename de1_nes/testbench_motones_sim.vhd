library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity testbench_motones_sim is
end testbench_motones_sim;

architecture stimulus of testbench_motones_sim is 
    component de1_nes
        port (
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

    constant powerup_time   : time := 5000 ns;
    constant reset_time     : time := 10 us;

    ---clock frequency = 21,477,270 (21 MHz)
    --constant base_clock_time : time := 46 ns;
    --base clock frequency shares vga clock.
    constant base_clock_time : time := 40 ns;

begin

    sim_board : de1_nes port map (base_clk, reset_input, joypad1, joypad2, 
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

