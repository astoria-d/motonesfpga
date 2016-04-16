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
    signal dbg_r_nw     : out std_logic;
    signal dbg_addr     : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io     : out std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : out std_logic_vector (7 downto 0);
    signal dbg_vram_a   : out std_logic_vector (13 downto 8);

---monitor inside cpu
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus    : out std_logic_vector(7 downto 0);
    signal dbg_exec_cycle   : out std_logic_vector (5 downto 0);
    signal dbg_ea_carry     : out std_logic;
--    signal dbg_index_bus    : out std_logic_vector(7 downto 0);
--    signal dbg_acc_bus      : out std_logic_vector(7 downto 0);
    signal dbg_status       : out std_logic_vector(7 downto 0);
--    signal dbg_pcl, dbg_pch : out std_logic_vector(7 downto 0);
    signal dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
--    signal dbg_stat_we_n    : out std_logic;
--    signal dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w    : out std_logic_vector (7 downto 0);

--ppu debug pins
    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);
    signal dbg_disp_nt, dbg_disp_attr : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : out std_logic_vector (15 downto 0);
    signal dbg_nmi  : out std_logic;
    
    
--NES instance
        base_clk 	: in std_logic;
        rst_n     	: in std_logic;
        joypad1     : in std_logic_vector(7 downto 0);
        joypad2     : in std_logic_vector(7 downto 0);
        h_sync_n    : out std_logic;
        v_sync_n    : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0)
         );
    end component;

    signal base_clk         : std_logic;
    signal reset_input      : std_logic;
    signal nmi_input      : std_logic;
    signal dbg_nmi      : std_logic;

    signal h_sync_n    : std_logic;
    signal v_sync_n    : std_logic;
    signal r           : std_logic_vector(3 downto 0);
    signal g           : std_logic_vector(3 downto 0);
    signal b           : std_logic_vector(3 downto 0);
    signal joypad1     : std_logic_vector(7 downto 0);
    signal joypad2     : std_logic_vector(7 downto 0);

    constant powerup_time   : time := 2 us;
    constant reset_time     : time := 890 ns;

    ---clock frequency = 21,477,270 (21 MHz)
    --constant base_clock_time : time := 46 ns;

    --DE1 base clock = 50 MHz
    constant base_clock_time : time := 20 ns;

    signal dbg_cpu_clk  : std_logic;
    signal dbg_ppu_clk  : std_logic;
    signal dbg_mem_clk  : std_logic;
    signal dbg_r_nw     : std_logic;
    signal dbg_addr : std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : std_logic_vector (7 downto 0);
    signal dbg_vram_a   : std_logic_vector (13 downto 8);
    signal dbg_instruction  : std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : std_logic_vector(7 downto 0);
    signal dbg_exec_cycle   : std_logic_vector (5 downto 0);
    signal dbg_ea_carry     : std_logic;
--    signal dbg_index_bus    : std_logic_vector(7 downto 0);
--    signal dbg_acc_bus      : std_logic_vector(7 downto 0);
    signal dbg_status       : std_logic_vector(7 downto 0);
    signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : std_logic;
    signal dbg_dec_val     : std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : std_logic_vector (7 downto 0);
--    signal dbg_status_val    : std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : std_logic;
    signal dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w    : std_logic_vector (7 downto 0);
    signal dbg_ppu_ce_n    : std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : std_logic_vector (7 downto 0);
    signal dbg_disp_nt, dbg_disp_attr : std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : std_logic_vector (15 downto 0);
    signal dbg_ppu_addr_we_n    : std_logic;
    signal dbg_ppu_clk_cnt          : std_logic_vector(1 downto 0);

begin

    sim_board : de1_nes port map (
dbg_cpu_clk,
dbg_ppu_clk,
dbg_mem_clk,
dbg_r_nw,
dbg_addr,
dbg_d_io,
dbg_vram_ad,
dbg_vram_a,
dbg_instruction,
dbg_int_d_bus,
dbg_exec_cycle   ,
dbg_ea_carry     ,
--dbg_index_bus    ,
--dbg_acc_bus      ,
dbg_status       ,
--dbg_pcl, dbg_pch, 
dbg_sp, dbg_x, dbg_y, dbg_acc       ,
dbg_dec_oe_n    ,
dbg_dec_val     ,
dbg_int_dbus    ,
--dbg_status_val    ,
--dbg_stat_we_n    ,
--dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w,

dbg_ppu_ce_n    ,
dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status ,
dbg_ppu_addr ,
dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y,
dbg_disp_nt, dbg_disp_attr ,
dbg_disp_ptn_h, dbg_disp_ptn_l ,
--dbg_ppu_addr_we_n,
--dbg_ppu_clk_cnt          ,
dbg_nmi,
    
    base_clk, reset_input, joypad1, joypad2, 
            h_sync_n, v_sync_n, r, g, b);

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
    constant nmi_wait     : time := 100 us;
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

end stimulus;

