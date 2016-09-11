library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity testbench_motones_sim is
end testbench_motones_sim;

architecture stimulus of testbench_motones_sim is 
    component de0_cv_nes
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
        pi_nt_v_mirror : in std_logic;
        
        --for debugging..
        po_dbg_cnt     : out std_logic_vector (63 downto 0)
         );
    end component;

    signal dbg_base_clk     : std_logic;
    signal base_clk         : std_logic;
    signal reset_input      : std_logic;
    signal nmi_input      : std_logic;
    signal dbg_nmi      : std_logic;
    signal dummy_nmi  : std_logic;

    signal h_sync_n    : std_logic;
    signal v_sync_n    : std_logic;
    signal r           : std_logic_vector(3 downto 0);
    signal g           : std_logic_vector(3 downto 0);
    signal b           : std_logic_vector(3 downto 0);
    signal joypad1     : std_logic_vector(7 downto 0);
    signal joypad2     : std_logic_vector(7 downto 0);
    signal nt_v_mirror : std_logic;
    signal dbg_cnt     : std_logic_vector (63 downto 0);

    constant powerup_time   : time := 2 us;
    constant reset_time     : time := 890 ns;

    ---clock frequency = 21,477,270 (21 MHz)
    --constant base_clock_time : time := 46 ns;

    --DE1 base clock = 50 MHz
    constant base_clock_time : time := 20 ns;

begin

    sim_board : de0_cv_nes port map (
    dbg_base_clk,
    base_clk, reset_input, joypad1, joypad2, 
            h_sync_n, v_sync_n, r, g, b, nt_v_mirror, dbg_cnt);

    --- input reset.
    reset_p: process
    begin
        reset_input <= '1';
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

    --- initiate nmi.
    nmi_p: process
    constant nmi_wait     : time := 100657965 ps;
    --constant nmi_wait     : time := 10 ms;
    constant vblank_time     : time := 60 us;
    variable wait_cnt : integer := 0;
    begin

        if (wait_cnt = 0) then
            nmi_input <= '1';
            wait for powerup_time + reset_time + nmi_wait;
            wait_cnt := wait_cnt + 1;
        else
            nmi_input <= '0';
            wait for vblank_time ;
            nmi_input <= '1';
            wait for vblank_time / 4;
        end if;
    end process;
    ---for test nmi...
    dummy_nmi <= nmi_input;
    --dummy_nmi <= 'Z';

    --set chr rom mirror setting.
    nt_v_mirror <= '1';
end stimulus;

