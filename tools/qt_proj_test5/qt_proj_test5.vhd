library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  


entity qt_proj_test5 is 
    port (

    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_mem_clk  : out std_logic;
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
        
        signal green_led	:	out std_logic;	--Test passed
        signal red_led		:	out std_logic;	--Test fail

        base_clk 	: in std_logic;
        base_clk_24mhz 	: in std_logic;
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
end qt_proj_test5;

architecture rtl of qt_proj_test5 is

component sdram_controller 
  generic
	   (
		reset_polarity_g	:	std_logic	:= '0' --When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		--Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		pll_locked	:	in std_logic;	--PLL Locked indication, for CKE (Clock Enable) signal to SDRAM
		
		--SDRAM Signals
		dram_addr	:	out std_logic_vector (11 downto 0);		--Address (12 bit)
		dram_bank	:	out std_logic_vector (1 downto 0);		--Bank
		dram_cas_n	:	out std_logic;							--Column Address is being transmitted
		dram_cke	:	out std_logic;							--Clock Enable
		dram_cs_n	:	out std_logic;							--Chip Select (Here - Mask commands)
		dram_dq		:	inout std_logic_vector (15 downto 0);	--Data in / Data out
		dram_ldqm	:	out std_logic;							--Byte masking
		dram_udqm	:	out std_logic;							--Byte masking
		dram_ras_n	:	out std_logic;							--Row Address is being transmitted
		dram_we_n	:	out std_logic;							--Write Enable
   
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle
																--When Write Burst: Data has been read from SDRAM and is valid

		--Debug signals
		cmd_ack		:	out std_logic;							--Command has been acknowledged
		cmd_done	:	out std_logic;							--Command has finished (read/write)
		init_st_o	:	out std_logic_vector (3 downto 0);		--Current init state
		main_st_o	:	out std_logic_vector (3 downto 0)		--Current main state
   );
end component;

component sdram_rw 
  generic(
		reset_polarity :	std_logic := '0' --When rst = reset_polarity, system at RESET
	);
  port(
		--Clock and Reset
		clk_i		:	in std_logic;	--WISHBONE Clock
		rst			:	in std_logic;	--RESET
		
		--Signals to SDRAM controller
		wbm_adr_o	:	out std_logic_vector (21 downto 0);	--Address to read from / write to
		wbm_dat_i	:	in std_logic_vector (15 downto 0);	--Data out (to SDRAM)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);	--Data in (from SDRAM)
		wbm_we_i	:	out std_logic;	--'1' - Write, '0' - Read
		wbm_tga_o	:	out std_logic_vector (7 downto 0);	--Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;	--Transmit command to SDRAM controller
		wbm_stb_o	:	out std_logic;	--Transmit command to SDRAM controller
		wbm_stall_i	:	in std_logic;	--When '1', write data to SDRAM
		wbm_ack_i	:	in std_logic;	--when '1', data is ready to be read from SDRAM
		
		--Debug and test signals
		cmd_ack		:	in std_logic;	--Command has been acknowledged by SDRAM controller
		cmd_done	:	in std_logic;	--Command has finished (read/write)
		green_led	:	out std_logic;	--Test passed
		red_led		:	out std_logic;	--Test fail
		writing		:	out std_logic;	--'1' when writing, '0' when reading
		mem_val_o	:	out std_logic_vector (15 downto 0); --Memory value written / compared to SDRAM
		sdram_val_o	:	out std_logic_vector (15 downto 0); --Read value from SDRAM
		cur_st_o	:	out std_logic_vector (3 downto 0)	--Current state
   );
end component;

component sdram_model
	GENERIC (
		addr_bits : INTEGER := 12;
		data_bits : INTEGER := 16 ;
		col_bits  : INTEGER := 8
		);
	PORT (
		Dq		: inout std_logic_vector (15 downto 0) := (others => 'Z');
		Addr    : in    std_logic_vector (11 downto 0) ;-- := (others => '0');
		Ba      : in    std_logic_vector(1 downto 0);-- := "00";
		Clk     : in    std_logic ;--:= '0';
		Cke     : in    std_logic ;--:= '0';
		Cs      : in    std_logic ;--:= '1';
		Ras     : in    std_logic ;--:= '0';
		Cas     : in    std_logic ;--:= '0';
		We      : in    std_logic ;--:= '0';
		Dqm     : in    std_logic_vector(1 downto 0)-- := (others => 'Z')
		);
	
END component;

component vga_clk_gen
    PORT
    (
        inclk0		: IN STD_LOGIC  := '0';
        c0		: OUT STD_LOGIC ;
        locked		: OUT STD_LOGIC 
    );
end component;

--Clock and Reset
signal clk_133		:	std_logic := '0'; --133 MHz
signal rst			:	std_logic := '0'; --Reset

----SDRAM Signals
--signal dram_addr	:	std_logic_vector (11 downto 0);
--signal dram_bank	:	std_logic_vector (1 downto 0);
--signal dram_cas_n	:	std_logic;
--signal dram_cke		:	std_logic;
--signal dram_cs_n	:	std_logic;
--signal dram_dq		:	std_logic_vector (15 downto 0);
--signal dram_ldqm	:	std_logic;
--signal dram_udqm	:	std_logic;
--signal dram_ras_n	:	std_logic;
--signal dram_we_n	:	std_logic;

--Read / Write signals to SDRAM
signal addr			: 	std_logic_vector (21 downto 0);
signal dat_tb2ram	:	std_logic_vector (15 downto 0);
signal dat_ram2tb	: 	std_logic_vector (15 downto 0);
signal we_i			: 	std_logic;
signal stall_i		: 	std_logic;
signal cyc_o		:	std_logic;
signal err_o		:	std_logic;
signal ack_i		:	std_logic;
signal stb_o		:	std_logic;
signal burst_len	:	std_logic_vector (7 downto 0);
signal cmd_ack		:	std_logic;
signal cmd_done		:	std_logic;

--LEDs
--signal green_led	: std_logic;
--signal red_led		: std_logic;
signal writing		: std_logic;

--States
signal init_st_o	: std_logic_vector (3 downto 0);
signal main_st_o	: std_logic_vector (3 downto 0);

--Debug
signal cur_st_o		: std_logic_vector (3 downto 0);

signal sdram_clk, pll_locked : std_logic;
begin
	--Clock process
    vga_clk_gen_inst : vga_clk_gen
    PORT map
    (
        --sdram_clk = 133.3333 MHz.
        base_clk, sdram_clk, pll_locked
    );
	clk_proc:
	clk_133 <= sdram_clk;
	
	rst_proc:
	rst 	<= rst_n;
	
	--Componenets:
	sdr_ctrl : sdram_controller 	generic map (
										reset_polarity_g  	=> '0'
										)
									port map(
										clk_i		=> clk_133,
	                                    rst			=> rst,
	                                    pll_locked	=> pll_locked,
	                                    
	                                    dram_addr	=> dram_addr,	
	                                    dram_bank	=> dram_bank,	
	                                    dram_cas_n	=> dram_cas_n,	
	                                    dram_cke	=> dram_cke,	
	                                    dram_cs_n	=> dram_cs_n,	
	                                    dram_dq		=> dram_dq,		
	                                    dram_ldqm	=> dram_ldqm,	
	                                    dram_udqm	=> dram_udqm,	
	                                    dram_ras_n	=> dram_ras_n,	
	                                    dram_we_n	=> dram_we_n,	
	                                    
	                                    wbs_adr_i	=> addr,	
	                                    wbs_dat_i	=> dat_tb2ram,	
										wbs_we_i	=> we_i,	
										wbs_tga_i	=> burst_len,	
										wbs_cyc_i	=> cyc_o,
										wbs_stb_i	=> stb_o,	
										wbs_dat_o	=> dat_ram2tb,
										wbs_stall_o	=> stall_i,
										wbs_err_o	=> err_o,
										wbs_ack_o	=> ack_i,
										
										cmd_ack		=> cmd_ack,
										cmd_done	=> cmd_done,
										init_st_o	=> init_st_o,
										main_st_o	=> main_st_o
									);
									
	sdr_rw : sdram_rw port map		(
										clk_i		=> clk_133,
										rst			=> rst,
										
										wbm_adr_o	=> addr,
										wbm_dat_i	=> dat_ram2tb,
	                                    wbm_dat_o	=> dat_tb2ram,
										wbm_we_i	=> we_i,
                                        wbm_tga_o	=> burst_len,
                                        wbm_cyc_o	=> cyc_o,
                                        wbm_stb_o	=> stb_o,
										wbm_stall_i	=> stall_i,
                                        wbm_ack_i	=> ack_i,

                                        cmd_ack		=> cmd_ack,
                                        cmd_done	=> cmd_done,
										green_led	=> green_led,
										red_led		=> red_led,
										writing		=> writing
									);
--	sdram_model_inst : sdram_model port map (
--										Dq		=> dram_dq,	
--	                                    Addr    => dram_addr,
--	                                    Ba      => dram_bank,
--	                                    Clk     => clk_133,
--	                                    Cke     => dram_cke,
--	                                    Cs      => dram_cs_n,
--	                                    Ras     => dram_ras_n,
--	                                    Cas     => dram_cas_n,
--	                                    We      => dram_we_n,
--	                                    Dqm(0)  => dram_ldqm,
--	                                    Dqm(1)  => dram_udqm
--									);
									
end architecture rtl;

--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

entity qt_proj_test5_old is 
    port (

    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_mem_clk  : out std_logic;
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
        
        signal green_led	:	out std_logic;	--Test passed
        signal red_led		:	out std_logic;	--Test fail

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
end qt_proj_test5_old;

architecture rtl of qt_proj_test5_old is

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                mem_clk     : out std_logic;
                vga_clk     : out std_logic
            );
    end component;

    component dummy_ppu
        port (  ppu_clk     : in std_logic;
                rst_n       : in std_logic;
                pos_x       : out std_logic_vector (8 downto 0);
                pos_y       : out std_logic_vector (8 downto 0);
                nes_r       : out std_logic_vector (3 downto 0);
                nes_g       : out std_logic_vector (3 downto 0);
                nes_b       : out std_logic_vector (3 downto 0)
        );
    end component;

    component vga_clk_gen
        PORT
        (
            inclk0		: IN STD_LOGIC  := '0';
            c0		: OUT STD_LOGIC ;
            locked		: OUT STD_LOGIC 
        );
    end component;

signal pos_x       : std_logic_vector (8 downto 0);
signal pos_y       : std_logic_vector (8 downto 0);
signal nes_r       : std_logic_vector (3 downto 0);
signal nes_g       : std_logic_vector (3 downto 0);
signal nes_b       : std_logic_vector (3 downto 0);

component vga_ctl
    port (  
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

            ppu_clk     : in std_logic;
            vga_clk     : in std_logic;
            mem_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : in std_logic_vector (8 downto 0);
            pos_y       : in std_logic_vector (8 downto 0);
            nes_r       : in std_logic_vector (3 downto 0);
            nes_g       : in std_logic_vector (3 downto 0);
            nes_b       : in std_logic_vector (3 downto 0);
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0);
            
            --SDRAM Signals
            wbs_adr_i	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
            wbs_dat_i	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
            wbs_we_i	:	out std_logic;							--Write Enable
            wbs_tga_i	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
            wbs_cyc_i	:	out std_logic;							--Cycle Command from interface
            wbs_stb_i	:	out std_logic;							--Strobe Command from interface
            wbs_dat_o	:	in std_logic_vector (15 downto 0);		--Data Out (16 bits)
            wbs_stall_o	:	in std_logic;							--Slave is not ready to receive new data
            wbs_err_o	:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
            wbs_ack_o	:	in std_logic 							--When Read Burst: DATA bus must be valid in this cycle
    );
end component;

component sdram_controller
  generic
	   (
		reset_polarity_g	:	std_logic	:= '0' --When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		--Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		pll_locked	:	in std_logic;	--PLL Locked indication, for CKE (Clock Enable) signal to SDRAM
		
		--SDRAM Signals
		dram_addr	:	out std_logic_vector (11 downto 0);		--Address (12 bit)
		dram_bank	:	out std_logic_vector (1 downto 0);		--Bank
		dram_cas_n	:	out std_logic;							--Column Address is being transmitted
		dram_cke	:	out std_logic;							--Clock Enable
		dram_cs_n	:	out std_logic;							--Chip Select (Here - Mask commands)
		dram_dq		:	inout std_logic_vector (15 downto 0);	--Data in / Data out
		dram_ldqm	:	out std_logic;							--Byte masking
		dram_udqm	:	out std_logic;							--Byte masking
		dram_ras_n	:	out std_logic;							--Row Address is being transmitted
		dram_we_n	:	out std_logic;							--Write Enable
   
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle
																--When Write Burst: Data has been read from SDRAM and is valid

		--Debug signals
		cmd_ack		:	out std_logic;							--Command has been acknowledged
		cmd_done	:	out std_logic;							--Command has finished (read/write)
		init_st_o	:	out std_logic_vector (3 downto 0);		--Current init state
		main_st_o	:	out std_logic_vector (3 downto 0)		--Current main state
   ); 
end component;


component sdram_rw
  generic(
		reset_polarity :	std_logic := '0' --When rst = reset_polarity, system at RESET
	);
  port(
		--Clock and Reset
		clk_i		:	in std_logic;	--WISHBONE Clock
		rst			:	in std_logic;	--RESET
		
		--Signals to SDRAM controller
		wbm_adr_o	:	out std_logic_vector (21 downto 0);	--Address to read from / write to
		wbm_dat_i	:	in std_logic_vector (15 downto 0);	--Data out (to SDRAM)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);	--Data in (from SDRAM)
		wbm_we_i	:	out std_logic;	--'1' - Write, '0' - Read
		wbm_tga_o	:	out std_logic_vector (7 downto 0);	--Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;	--Transmit command to SDRAM controller
		wbm_stb_o	:	out std_logic;	--Transmit command to SDRAM controller
		wbm_stall_i	:	in std_logic;	--When '1', write data to SDRAM
		wbm_ack_i	:	in std_logic;	--when '1', data is ready to be read from SDRAM
		
		--Debug and test signals
		cmd_ack		:	in std_logic;	--Command has been acknowledged by SDRAM controller
		cmd_done	:	in std_logic;	--Command has finished (read/write)
		green_led	:	out std_logic;	--Test passed
		red_led		:	out std_logic;	--Test fail
		writing		:	out std_logic;	--'1' when writing, '0' when reading
		mem_val_o	:	out std_logic_vector (15 downto 0); --Memory value written / compared to SDRAM
		sdram_val_o	:	out std_logic_vector (15 downto 0); --Read value from SDRAM
		cur_st_o	:	out std_logic_vector (3 downto 0)	--Current state
   );
end component;

    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant size14    : integer := 14;

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal mem_clk   : std_logic;
    signal vga_clk   : std_logic;
    signal vga_clk_pll, sdram_clk : std_logic;
    signal pll_locked   : std_logic;

    -- Wishbone Slave signals to Read/Write interface
    signal wbs_adr_i	:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
    signal wbs_dat_i	:	std_logic_vector (15 downto 0);		--Data In (16 bits)
    signal wbs_we_i	    :	std_logic;							--Write Enable
    signal wbs_tga_i	:	std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
    signal wbs_cyc_i	:	std_logic;							--Cycle Command from interface
    signal wbs_stb_i	:	std_logic;							--Strobe Command from interface
    signal wbs_dat_o	:	std_logic_vector (15 downto 0);		--Data Out (16 bits)
    signal wbs_stall_o	:	std_logic;							--Slave is not ready to receive new data
    signal wbs_err_o	:	std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
    signal wbs_ack_o	:	std_logic;							--When Read Burst: DATA bus must be valid in this cycle
                                                                --When Write Burst: Data has been read from SDRAM and is valid

    --Debug signals
    signal cmd_ack		:	std_logic;							--Command has been acknowledged
    signal cmd_done	    :	std_logic;							--Command has finished (read/write)
    signal init_st_o	:	std_logic_vector (3 downto 0);		--Current init state
    signal main_st_o	:	std_logic_vector (3 downto 0);  	--Current main state

    signal writing		:	std_logic;	--'1' when writing, '0' when reading
    signal mem_val_o	:	std_logic_vector (15 downto 0); --Memory value written / compared to SDRAM
    signal sdram_val_o	:	std_logic_vector (15 downto 0); --Read value from SDRAM
    signal cur_st_o	:	std_logic_vector (3 downto 0);	--Current state
    
begin


    dbg_mem_clk <= mem_clk  ;
    dbg_cpu_clk <= cpu_clk;
    dbg_ppu_clk <= ppu_clk;

    dbg_pos_x       <= pos_x       ;
    dbg_pos_y       <= pos_y       ;
    dbg_nes_r       <= nes_r       ;
    dbg_nes_g       <= nes_g       ;
    dbg_nes_b       <= nes_b       ;

    dbg_wbs_adr_i	<= wbs_adr_i	;
    dbg_wbs_dat_i	<= wbs_dat_i	;
    dbg_wbs_we_i	<= wbs_we_i	    ;
    dbg_wbs_tga_i	<= wbs_tga_i	;
    dbg_wbs_cyc_i	<= wbs_cyc_i	;
    dbg_wbs_stb_i	<= wbs_stb_i	;



    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, mem_clk, vga_clk);

    ppu_inst: dummy_ppu 
        port map (  ppu_clk     ,
                rst_n       ,
                pos_x       ,
                pos_y       ,
                nes_r       ,
                nes_g       ,
                nes_b       
        );

--        vga_clk_gen_inst : vga_clk_gen
--        PORT map
--        (
--            --mem_clk_pll = 133.333 MHz.
--            base_clk, vga_clk_pll, sdram_clk, pll_locked
--        );
    --- testbench pll clock..
--    dummy_clock_p: process
--    begin
--        sdram_clk <= '1';
--        wait for 6250 ps / 2;
--        sdram_clk <= '0';
--        wait for 6250 ps / 2;
--    end process;

    
--    vga_ctl_inst : vga_ctl
--    port map (  
--        dbg_vga_x        ,
--        dbg_vga_y        ,
--        dbg_nes_x        ,
--        dbg_nes_x_old    ,
--        dbg_sw_state     ,
--        
--        dbg_f_in             ,
--        dbg_f_out            ,
--        dbg_f_cnt            ,
--        dbg_f_rd, dbg_f_wr, dbg_f_emp, dbg_f_ful ,
--        dbg_bst_cnt          ,
--
--            ppu_clk     ,
--            --vga_clk_pll, 
--            --ppu_clk ,
--            vga_clk     ,
--            mem_clk     ,
--            rst_n       ,
--            pos_x       ,
--            pos_y       ,
--            nes_r       ,
--            nes_g       ,
--            nes_b       ,
--            h_sync_n    ,
--            v_sync_n    ,
--            r           ,
--            g           ,
--            b           ,
--            
--            --SDRAM Signals
--            wbs_adr_i	,
--            wbs_dat_i	,
--            wbs_we_i	,
--            wbs_tga_i	,
--            wbs_cyc_i	,
--            wbs_stb_i	,
--            wbs_dat_o	,
--            wbs_stall_o	,
--            wbs_err_o	,
--            wbs_ack_o	
--    );

    test_sdram_inst : sdram_rw
    port map (  
		mem_clk,
		rst_n,
		
		--Signals to SDRAM controller
		wbs_adr_i,
		wbs_dat_o,
		wbs_dat_i,
		wbs_we_i,
		wbs_tga_i,
		wbs_cyc_i,
		wbs_stb_i,
		wbs_stall_o,
		wbs_ack_o,
		
		--Debug and test signals
		cmd_ack		,
		cmd_done	,
		green_led	,
		red_led		,
		writing		,
		mem_val_o	,
		sdram_val_o	,
		cur_st_o	
   );

    dram_clk <= not mem_clk;
    sdram_clk <= not mem_clk;
sdram_ctl_inst : sdram_controller
  port map (
		--Clocks and Reset 
		sdram_clk, 
		rst_n, 
		'0',
		
		--SDRAM Signals
		dram_addr	,
		dram_bank	,
		dram_cas_n	,
		dram_cke	,
		dram_cs_n	,
		dram_dq		,
		dram_ldqm	,
		dram_udqm	,
		dram_ras_n	,
		dram_we_n	,
   
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	,
		wbs_dat_i	,
		wbs_we_i	,
		wbs_tga_i	,
		wbs_cyc_i	,
		wbs_stb_i	,
		wbs_dat_o	,
		wbs_stall_o	,
		wbs_err_o	,
		wbs_ack_o	,

		--Debug signals
		cmd_ack		,
		cmd_done	,
		init_st_o	,
		main_st_o	
   ); 
        
    --    signal addr : std_logic_vector( addr_size - 1 downto 0);
--    signal d_io : std_logic_vector( data_size - 1 downto 0);
--
--component counter_register
--    generic (
--        dsize       : integer := 8;
--        inc         : integer := 1
--    );
--    port (  clk         : in std_logic;
--            rst_n       : in std_logic;
--            ce_n        : in std_logic;
--            we_n        : in std_logic;
--            d           : in std_logic_vector(dsize - 1 downto 0);
--            q           : out std_logic_vector(dsize - 1 downto 0)
--    );
--end component;
--
--component prg_rom
--    generic (abus_size : integer := 15; dbus_size : integer := 8);
--    port (  clk             : in std_logic;
--            ce_n           : in std_logic;   --select pin active low.
--            addr            : in std_logic_vector (abus_size - 1 downto 0);
--            data            : inout std_logic_vector (dbus_size - 1 downto 0)
--        );
--end component;
--
--component processor_status 
--    generic (
--            dsize : integer := 8
--            );
--    port (  
--    signal dbg_dec_oe_n    : out std_logic;
--    signal dbg_dec_val     : out std_logic_vector (dsize - 1 downto 0);
--    signal dbg_int_dbus    : out std_logic_vector (dsize - 1 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
--    signal dbg_stat_we_n    : out std_logic;
--    
--            clk         : in std_logic;
--            res_n       : in std_logic;
--            dec_oe_n    : in std_logic;
--            bus_oe_n    : in std_logic;
--            set_flg_n   : in std_logic;
--            flg_val     : in std_logic;
--            load_bus_all_n      : in std_logic;
--            load_bus_nz_n       : in std_logic;
--            set_from_alu_n      : in std_logic;
--            alu_n       : in std_logic;
--            alu_v       : in std_logic;
--            alu_z       : in std_logic;
--            alu_c       : in std_logic;
--            stat_c      : out std_logic;
--            dec_val     : inout std_logic_vector (dsize - 1 downto 0);
--            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
--        );
--end component;
--
--    ---status register
--    signal status_reg, int_d_bus : std_logic_vector (7 downto 0);
--    signal stat_dec_oe_n : std_logic;
--    signal stat_bus_oe_n : std_logic;
--    signal stat_set_flg_n : std_logic;
--    signal stat_flg : std_logic;
--    signal stat_bus_all_n : std_logic;
--    signal stat_bus_nz_n : std_logic;
--    signal stat_alu_we_n : std_logic;
--    signal alu_n : std_logic;
--    signal alu_z : std_logic;
--    signal alu_c : std_logic;
--    signal alu_v : std_logic;
--    signal stat_c : std_logic;
--    signal trig_clk : std_logic;
--    
--    
--    
--    component alu_test
--    port (  
--        d1    : in std_logic_vector(7 downto 0);
--        d2    : in std_logic_vector(7 downto 0);
--        d_out    : out std_logic_vector(7 downto 0);
--        carry_clr_n : in std_logic;
--        ea_carry : out std_logic
--        );
--end component;
--
--    signal d1, d2, d_out : std_logic_vector (7 downto 0);
--    signal ea_carry, gate_n    : std_logic;
--        signal carry_clr_n : std_logic;


    
    
--    trig_clk <= not cpu_clk;
--
--    pcl_inst : counter_register generic map (16) port map
--        (cpu_clk, rst_n, '0', '1', (others => '0'), addr(15 downto 0));
--
--    rom_inst : prg_rom generic map (12, 8) port map
--        (base_clk, '0', addr(11 downto 0), d_io);
--
--    dbg_addr <= addr;
--    dbg_d_io <= d_io;
--
--    dbg_d1 <= d1;
--    dbg_d2 <= d2;
--    dbg_d_out <= d_out;
--    dbg_ea_carry <= ea_carry;
--    dbg_carry_clr_n <= carry_clr_n;
--    dbg_gate_n <= gate_n;
--    
--    dummy_alu : alu_test
--    port map (  
--        d1, d2, d_out, carry_clr_n , ea_carry
--        );
--
--        gate_n <= not ea_carry;
--    dec_test_p : process (rst_n, ea_carry, trig_clk)
--    begin
--        if (rst_n = '0') then
--            d1 <= "00000000";
--            d2 <= "00000000";
--            carry_clr_n <= '0';
--            --gate_n <= '1';
----        elsif (ea_carry = '1') then
----            gate_n <= '0';
----            carry_clr_n <= '0';
--        elsif (rising_edge(trig_clk)) then
--            if (addr(5 downto 0) = "000001") then
--            --addr=01
--                carry_clr_n <= '1';
--                d1 <= "00010011";
--                d2 <= "01000111";
--                --gate_n <= '1';
--            elsif (addr(5 downto 0) = "000010") then
--            --addr=02
--                carry_clr_n <= '1';
--                d1 <= "00110011";
--                d2 <= "11001111";
--                --gate_n <= '1';
--            elsif (addr(5 downto 0) = "000011") then
--            --addr=03
--                carry_clr_n <= '1';
--                d1 <= "00001010";
--                d2 <= "01011001";
--                --gate_n <= '1';
--            elsif (addr(5 downto 0) = "000100") then
--            --addr=04
--                carry_clr_n <= '1';
--                d1 <= "10001010";
--                d2 <= "10011001";
--                --gate_n <= '1';
--            else
--                carry_clr_n <= '1';
--                d1 <= "00000000";
--                d2 <= "00000000";
--                --gate_n <= '1';
--            end if;
--        end if;
--    end process;
--
--
--    --status register
--    status_register : processor_status generic map (8) 
--            port map (
--    dbg_dec_oe_n,
--    dbg_dec_val,
--    dbg_int_dbus,
--    dbg_status_val,
--    dbg_stat_we_n    ,
--                    trig_clk , rst_n, 
--                    stat_dec_oe_n, stat_bus_oe_n, 
--                    stat_set_flg_n, stat_flg, stat_bus_all_n, stat_bus_nz_n, 
--                    stat_alu_we_n, alu_n, alu_v, alu_z, alu_c, stat_c,
--                    status_reg, int_d_bus);
--
--    dbg_status <= status_reg;
--    status_test_p : process (addr)
--    begin
--        if (addr(5 downto 0) = "000010") then
--        --addr=02
--        --set status(7) = '1'
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '0';
--            stat_flg <= '1';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '1'; 
--            stat_alu_we_n <= '1';
--            status_reg <= "01000000";
--            int_d_bus <= "00000000";
--
--        elsif (addr(5 downto 0) = "000100") then
--        --addr=04
--        --set status(2) = '0'
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '0';
--            stat_flg <= '0';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '1'; 
--            stat_alu_we_n <= '1';
--            status_reg <= "00000100";
--            int_d_bus <= "00000000";
--
--        elsif (addr(5 downto 0) = "000110") then
--        --addr=06
--        --set nz from bus, n=1
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '1';
--            stat_flg <= '0';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '0'; 
--            stat_alu_we_n <= '1';
--            status_reg <= (others => 'Z');
--            int_d_bus <= "10000000";
--
--        elsif (addr(5 downto 0) = "001000") then
--        --addr=08
--        --set nz from bus, z=1
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '1';
--            stat_flg <= '0';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '0'; 
--            stat_alu_we_n <= '1';
--            status_reg <= (others => 'Z');
--            int_d_bus <= "00000000";
--
--        else
--            stat_dec_oe_n <= '0';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '1';
--            stat_flg <= '1';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '1'; 
--            stat_alu_we_n <= '1';
--            status_reg <= (others => 'Z');
--            int_d_bus <= (others => 'Z');
--        end if;
--    end process;

end rtl;

