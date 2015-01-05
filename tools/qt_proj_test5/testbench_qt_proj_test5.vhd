library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity testbench_qt_proj_test5 is
end testbench_qt_proj_test5;

architecture stimulus of testbench_qt_proj_test5 is 
    component qt_proj_test5
        port (
    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : out std_logic_vector( 8 - 1 downto 0);

    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
    signal dbg_status_val    : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;
    
---monitor inside cpu
    signal dbg_d1, dbg_d2, dbg_d_out: out std_logic_vector (7 downto 0);
    signal dbg_ea_carry, dbg_carry_clr_n    : out std_logic;
    signal dbg_gate_n    : out std_logic;


        base_clk 	: in std_logic;
        base_clk_27mhz 	: in std_logic;
        rst_n     	: in std_logic;
        h_sync_n    : out std_logic;
        v_sync_n    : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0)
            );
    end component;

    signal base_clk         : std_logic;
        signal base_clk_27mhz 	: std_logic;
    signal vga_clk         : std_logic;
    signal reset_input      : std_logic;

    signal h_sync_n    : std_logic;
    signal v_sync_n    : std_logic;
    signal r           : std_logic_vector(3 downto 0);
    signal g           : std_logic_vector(3 downto 0);
    signal b           : std_logic_vector(3 downto 0);
    signal joypad1     : std_logic_vector(7 downto 0);
    signal joypad2     : std_logic_vector(7 downto 0);

    constant powerup_time   : time := 50 ns;
    constant reset_time     : time := 200 ns;

    ---clock frequency = 21,477,270 (21 MHz)
    --constant base_clock_time : time := 46 ns;
    --base clock frequency = 50 MHz.
    constant base_clock_time : time := 20 ns;
    
    constant base_clock_27mhz_time : time := 37 ns;
    


    signal dbg_cpu_clk  : std_logic;
    signal dbg_ppu_clk  : std_logic;
    signal dbg_addr : std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : std_logic_vector (7 downto 0);
    signal dbg_vram_a   : std_logic_vector (13 downto 8);

    
    signal dbg_status       : std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : std_logic;
    signal dbg_dec_val     : std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : std_logic_vector (7 downto 0);
    signal dbg_status_val    : std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : std_logic;
    
    signal dbg_d1, dbg_d2, dbg_d_out: std_logic_vector (7 downto 0);
    signal dbg_ea_carry, dbg_carry_clr_n    : std_logic;
    signal dbg_gate_n    : std_logic;

begin

    sim_board : qt_proj_test5 port map (
    dbg_cpu_clk  , 
    dbg_ppu_clk  , 
    dbg_addr , 
    dbg_d_io , 

    
    dbg_status       , 
    dbg_dec_oe_n    , 
    dbg_dec_val     , 
    dbg_int_dbus    , 
    dbg_status_val    , 
    dbg_stat_we_n    , 

    dbg_d1, dbg_d2, dbg_d_out,
    dbg_ea_carry    ,dbg_carry_clr_n , 
    dbg_gate_n    ,

    
    base_clk, base_clk_27mhz, reset_input, 
        h_sync_n    ,
        v_sync_n    ,
        r           ,
        g           ,
        b           
);

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

    clock27mhz_p: process
    begin
        base_clk_27mhz <= '1';
        wait for base_clock_27mhz_time / 2;
        base_clk_27mhz <= '0';
        wait for base_clock_27mhz_time / 2;
    end process;
end stimulus;

