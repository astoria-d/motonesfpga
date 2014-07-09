--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

entity qt_proj_test5 is 
    port (

    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_mem_clk  : out std_logic;
    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : out std_logic_vector( 8 - 1 downto 0);

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
end qt_proj_test5;

architecture rtl of qt_proj_test5 is

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

    
    vga_ctl_inst : vga_ctl
    port map (  
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

            ppu_clk     ,
            --vga_clk_pll, 
            --ppu_clk ,
            vga_clk     ,
            mem_clk     ,
            rst_n       ,
            pos_x       ,
            pos_y       ,
            nes_r       ,
            nes_g       ,
            nes_b       ,
            h_sync_n    ,
            v_sync_n    ,
            r           ,
            g           ,
            b           ,
            
            --SDRAM Signals
            wbs_adr_i	,
            wbs_dat_i	,
            wbs_we_i	,
            wbs_tga_i	,
            wbs_cyc_i	,
            wbs_stb_i	,
            wbs_dat_o	,
            wbs_stall_o	,
            wbs_err_o	,
            wbs_ack_o	
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
        
end rtl;







---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-------------         SDRAM TEST IMAGE          ---------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

entity sdram_test is 
    port (

    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_mem_clk  : out std_logic;
    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : out std_logic_vector( 8 - 1 downto 0);

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
end sdram_test;

architecture rtl of sdram_test is

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
    dram_clk <= sdram_clk;
    dbg_mem_clk <= sdram_clk;
	
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
									
end architecture rtl;
