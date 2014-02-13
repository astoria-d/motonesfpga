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
    signal dbg_mem_clk    : out std_logic;

    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : out std_logic_vector( 8 - 1 downto 0);

--    signal dbg_status       : out std_logic_vector(7 downto 0);
--    signal dbg_dec_oe_n    : out std_logic;
--    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
--    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
--    signal dbg_stat_we_n    : out std_logic;
    
---monitor inside cpu
--    signal dbg_d1, dbg_d2, dbg_d_out: out std_logic_vector (7 downto 0);
--    signal dbg_ea_carry, dbg_carry_clr_n    : out std_logic;
--    signal dbg_gate_n    : out std_logic;

        signal dbg_pos_x       : out std_logic_vector (8 downto 0);
        signal dbg_pos_y       : out std_logic_vector (8 downto 0);
        signal dbg_nes_r       : out std_logic_vector (3 downto 0);
        signal dbg_nes_g       : out std_logic_vector (3 downto 0);
        signal dbg_nes_b       : out std_logic_vector (3 downto 0);

        signal dbg_wbs_adr_i	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
        signal dbg_wbs_dat_i	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
        signal dbg_wbs_we_i	    :	out std_logic;							--Write Enable
        signal dbg_wbs_tga_i	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
        signal dbg_wbs_cyc_i	:	out std_logic;							--Cycle Command from interface
        signal dbg_wbs_stb_i	:	out std_logic;							--Strobe Command from interface

        signal dbg_vga_x        : out std_logic_vector (9 downto 0);
        signal dbg_vga_y        : out std_logic_vector (9 downto 0);
        signal dbg_nes_x        : out std_logic_vector(7 downto 0);
        signal dbg_nes_x_old        : out std_logic_vector(7 downto 0);
        signal dbg_sw_state     : out std_logic_vector(2 downto 0);

        signal dbg_f_in             : out std_logic_vector(11 downto 0);
        signal dbg_f_out            : out std_logic_vector(11 downto 0);
        signal dbg_f_cnt            : out std_logic_vector(7 downto 0);
        signal dbg_f_rd, dbg_f_wr, dbg_f_emp, dbg_f_ful 
                                    : out std_logic;
        signal dbg_bst_cnt          : out std_logic_vector(7 downto 0);

        base_clk 	: in std_logic;
        base_clk_27mhz 	: in std_logic;
        rst_n     	: in std_logic;
        h_sync_n    : out std_logic;
        v_sync_n    : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0);

		--SDRAM Signals
		dram_addr	:	out std_logic_vector (11 downto 0);		--Address (12 bit)
		dram_bank	:	out std_logic_vector (1 downto 0);		--Bank
		dram_cas_n	:	out std_logic;							--Column Address is being transmitted
		dram_cke	:	out std_logic;							--Clock Enable
		dram_clk	:	out std_logic;							--Clock
		dram_cs_n	:	out std_logic;							--Chip Select (Here - Mask commands)
		dram_dq		:	inout std_logic_vector (15 downto 0);	--Data in / Data out
		dram_ldqm	:	out std_logic;							--Byte masking
		dram_udqm	:	out std_logic;							--Byte masking
		dram_ras_n	:	out std_logic;							--Row Address is being transmitted
		dram_we_n	:	out std_logic 							--Write Enable
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

	signal dram_addr	:	std_logic_vector (11 downto 0);		--Address (12 bit)
	signal dram_bank	:	std_logic_vector (1 downto 0);		--Bank
	signal dram_cas_n	:	std_logic;							--Column Address is being transmitted
	signal dram_cke	:	std_logic;							--Clock Enable
	signal dram_clk	:	std_logic;							--Clock
	signal dram_cs_n	:	std_logic;							--Chip Select (Here - Mask commands)
	signal dram_dq		:	std_logic_vector (15 downto 0);	--Data in / Data out
	signal dram_ldqm	:	std_logic;							--Byte masking
	signal dram_udqm	:	std_logic;							--Byte masking
	signal dram_ras_n	:	std_logic;							--Row Address is being transmitted
	signal dram_we_n	:	std_logic; 							--Write Enable

    constant powerup_time   : time := 50 ns;
    constant reset_time     : time := 200 ns;

    ---clock frequency = 21,477,270 (21 MHz)
    --constant base_clock_time : time := 46 ns;
    --base clock frequency = 50 MHz.
    constant base_clock_time : time := 20 ns;
    
    constant base_clock_27mhz_time : time := 37 ns;
    


    signal dbg_cpu_clk  : std_logic;
    signal dbg_ppu_clk  : std_logic;
    signal dbg_mem_clk    : std_logic;
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

    signal dbg_pos_x       : std_logic_vector (8 downto 0);
    signal dbg_pos_y       : std_logic_vector (8 downto 0);
    signal dbg_nes_r       : std_logic_vector (3 downto 0);
    signal dbg_nes_g       : std_logic_vector (3 downto 0);
    signal dbg_nes_b       : std_logic_vector (3 downto 0);

    signal dbg_wbs_adr_i	:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
    signal dbg_wbs_dat_i	:	std_logic_vector (15 downto 0);		--Data In (16 bits)
    signal dbg_wbs_we_i	    :	std_logic;							--Write Enable
    signal dbg_wbs_tga_i	:	std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
    signal dbg_wbs_cyc_i	:	std_logic;							--Cycle Command from interface
    signal dbg_wbs_stb_i	:	std_logic;							--Strobe Command from interface

    signal dbg_vga_x        : std_logic_vector (9 downto 0);
    signal dbg_vga_y        : std_logic_vector (9 downto 0);
    signal dbg_nes_x        : std_logic_vector(7 downto 0);
    signal dbg_nes_x_old        : std_logic_vector(7 downto 0);
    signal dbg_sw_state     : std_logic_vector(2 downto 0);

    signal dbg_f_in             : std_logic_vector(11 downto 0);
    signal dbg_f_out            : std_logic_vector(11 downto 0);
    signal dbg_f_cnt            : std_logic_vector(7 downto 0);
    signal dbg_f_rd, dbg_f_wr, dbg_f_emp, dbg_f_ful 
                                    : std_logic;
    signal dbg_bst_cnt          : std_logic_vector(7 downto 0);

begin

    sim_board : qt_proj_test5 port map (
    dbg_cpu_clk  , 
    dbg_ppu_clk  , 
    dbg_mem_clk    ,
    dbg_addr , 
    dbg_d_io , 

    
--    dbg_status       , 
--    dbg_dec_oe_n    , 
--    dbg_dec_val     , 
--    dbg_int_dbus    , 
--    dbg_status_val    , 
--    dbg_stat_we_n    , 

--    dbg_d1, dbg_d2, dbg_d_out,
--    dbg_ea_carry    ,dbg_carry_clr_n , 
--    dbg_gate_n    ,

    dbg_pos_x       ,
    dbg_pos_y       ,
    dbg_nes_r       ,
    dbg_nes_g       ,
    dbg_nes_b       ,

    dbg_wbs_adr_i	,
    dbg_wbs_dat_i	,
    dbg_wbs_we_i	,
    dbg_wbs_tga_i	,
    dbg_wbs_cyc_i	,
    dbg_wbs_stb_i	,

    dbg_vga_x        ,
    dbg_vga_y        ,
    dbg_nes_x        ,
	dbg_nes_x_old    ,
    dbg_sw_state     ,
        
    dbg_f_in             ,
    dbg_f_out            ,
    dbg_f_cnt            ,
    dbg_f_rd, dbg_f_wr, dbg_f_emp, dbg_f_ful ,
	dbg_bst_cnt          ,
    
    base_clk, base_clk_27mhz, reset_input, 
        h_sync_n    ,
        v_sync_n    ,
        r           ,
        g           ,
        b           ,

	dram_addr	,
	dram_bank	,
	dram_cas_n	,
	dram_cke	,
	dram_clk	,
	dram_cs_n	,
	dram_dq		,
	dram_ldqm	,
	dram_udqm	,
	dram_ras_n	,
	dram_we_n	
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

