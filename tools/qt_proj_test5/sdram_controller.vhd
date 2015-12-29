------------------------------------------------------------------------------------------------
-- Model Name 	:	IS42S16400 SDRAM Controller
-- File Name	:	sdram_controller.vhd
-- Generated	:	September 2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This controller implements the IS42S16400 SDRAM Controller, with the
--				following characteristics:
-- 					1) Row width 12
-- 					2) Column width 8
-- 					3) Bank width 2
--					4) Address structure: 
--							Bank 	(21 downto 20)
--							Row		(19 downto 8 )
--							Column	(7  downto 0 )
-- 					5) CAS Delay = 3 (required for 133MHz clock. See timing, page 8)
--					6) Burst Length = Full Page (256 words - cyclic)
--
-- Refresh Cycle Time: Issued every 2083 cyles: 4096 (number of rows) refreshes per 64ms
--
-- Clock:	Use 133.333MHz clock for this controller (7.5 ns period time).
--			Make sure 'pll_locked' signal is available.
-- Reset:	Hold Reset for at least 1 clock.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		09/2010		Beeri Schreiber			Creation
--			1.10		27.3.2011	Beeri Schreiber			Adjustments to SDRAM simulation model
--			1.20		2.4.2011	Beeri Schreiber			Controller has been adjusted to support Wishbone standard
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) Remove SDRAM_MODEL Simulation lines after debug
--			(2) Add WBS_ERR_O for Write Burst OOR
------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sdram_controller is
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
end entity sdram_controller;

architecture rtl_sdram_controller of sdram_controller is
  
  ---------------------------------  Constants	----------------------------------
  
	--Mode Register - Refer to page 16 on the SDRAM documentation.
	--Bit 6-->4: LTMode = 110	: CAS Latency = 3
	--Bit 3:	 WT				: Wrap Type: Sequential
	--Bit 2-->0: BL		= 11	: Burst Length = Full Page
	constant mode_register_c 		:	std_logic_vector (11 downto 0) := "000000110111";
  
	-- tRC: 9 cycles: Row Cycle Time: 
	--	(1) Time to wait after refresh, 67.5ns (67.5-->70), refer to page 39
	--	(2) Time to wait between two ACT commands, refer to page 29
	constant tRC_delay_c			:	natural := 9;	

	--	According to page 1, 4096 refreshes cycles per 64 ms are being done.
	-- The number of cycles between refreshes is calculated:
	-- 64,000,000ns / 4096 / 7.5ns = 2083
    constant refresh_cycles_c		:	natural := 2083; 

	-- Three times will use the same counter, to avoid using 3 counters:
	-- (1) tRCD - RAS to CAS delay is 20ns (3 * 7.5 = 22.5ns)
	-- (2) tRP (Row Precharge Time) is also 20ns, so we will use here the same counter.
	-- (3) tRSC (Mode register set time) is 10ns minimum, and must be at least two clock cycle
	--		after end of precharge (15 ns). Since it happens only at init, we will use here 
	--		the same counter (22.5ns instead of 15ns)
    constant tRCD_tRP_tRSC_delay_c	:	natural := 3;	
																									
    --Init time: 26667 * 7.5ns ~ 200us
	constant init_200us_delay_c 	:	natural := 26667;
	
	--Full page burst length: Number of words(16 bits) per row = colum addresses = 2^8=256
	constant blen_c					:	natural := 256;

  ---------------------------------  	Types	----------------------------------
	-- Init States
	type init_states is (	INIT_IDLE_ST,			-- Ready to start init / Init done
							INIT_WAIT_200us_ST,		-- Wait 200 us (NOP command)
							INIT_PRECHARGE_ST,		-- Precharge all banks
							INIT_WAIT_PRE_ST,		-- Wait to tRP
							INIT_AUTO_REF_ST,		-- Perform Auto Refresh (8 cycles)
							INIT_AUTO_REF_WAIT_ST,	-- Wait tRC
							INIT_MODE_REG_ST,		-- Mode Register
							INIT_WAIT_MODE_REG_ST	-- Wait tRSC (Mode Register set time)
						);       

	-- Main States
	type main_states is (	IDLE_ST,			-- Idle
							REFRESH_ST,			-- Refresh
							REFRESH_WAIT_ST,	-- Wait tRC (Time between two ACT commands)
							ACT_ST,				-- ACT Command (Read / Write)
							WAIT_ACT_ST,		-- Wait tRCD (RAS to CAS Delay)
							WRITE0_ST,			-- Write Burst : Chunk 1 to len-1 (16 bits)
							WRITE1_ST,			-- Write Last chunk, before precharge: chunk len (16 bits)
							WRITE_BST_STOP_ST,	-- Wait for tRC (in the precharge state)
												
											--* Read Command: Three clock cycles - nothing happens.
											--* 4th clock - Data should be read, according to timing diagrams, 
											--* though since 'dram_dq' come is some delay after clock's rising edge, data
											--* will arrive in the 5th and 6th cycle:
							READ0_ST,			-- Read command - Nothing happens (Time until command is being accepted by SDRAM)
							READ1_ST,			-- Nothing happens (1 of 3)
							READ2_ST,			-- Nothing happens (2 of 3)
							READ3_ST,			-- Nothing happens (3 of 3)
							READ4_ST,			-- Data delay, since 'dram_dq' data comes right after clock's rising edge
							READ5_ST,			-- Read Burst: Chunk 1 to len-1
							READ_BST_STOP_ST,	-- Read last Chunk, chunk 'len', and wait for tRC (in the precharge state)
							WAIT_PRE_ST);    	-- Wait tRC (Row Cycle Time) to seperate between two ACT commands

							
  ---------------------------------  Signals	----------------------------------

  signal address_r			:	std_logic_vector (21 downto 0);  

  signal dram_addr_r		:	std_logic_vector (11 downto 0);
  signal dram_bank_r		:	std_logic_vector (1 downto 0);
  signal dram_dq_r			:	std_logic_vector (15 downto 0);  
  signal dram_cas_n_r		:	std_logic;
  signal dram_ras_n_r		:	std_logic;
  signal dram_we_n_r		:	std_logic;


  signal dat_o_r			:	std_logic_vector (15 downto 0);
  signal cmd_ack_r			:	std_logic;
  signal cmd_r				:	std_logic;
  signal we_i_r				:	std_logic;
  signal oe_r				:	std_logic;
  signal oor_r				:	std_logic;

  signal rx_data_r			:	std_logic;
  signal data_valid_r		:	std_logic;

  signal current_state		:	main_states;
  signal next_state			:	main_states;
  signal current_init_state	:	init_states;
  signal next_init_state	:	init_states;
  
  
  signal init_done			:	std_logic;
  signal init_pre_cntr		:	natural;
  signal tRC_cntr			:	natural;
  signal rfsh_int_cntr		:	natural;      
  signal tRCD_tRP_tRSC_cntr	:	natural;
  signal wait_200us_cntr	:	natural;
  signal do_refresh			:	std_logic;
  signal blen_cnt			:	natural;
 
begin
	--Connect internal signals to entity inputs and outputs
	dram_addr_proc:
	dram_addr	<= dram_addr_r;
	dram_bank_proc:
	dram_bank 	<= dram_bank_r;
	dram_cas_proc:
	dram_cas_n	<= dram_cas_n_r;
	dram_ras_proc:
	dram_ras_n 	<= dram_ras_n_r;
	dram_we_proc:
	dram_we_n 	<= dram_we_n_r;
	dram_dq_proc:
	dram_dq 	<= dram_dq_r when (oe_r = '1') else (others => 'Z');
	cmd_r_proc:
	cmd_r		<= wbs_cyc_i and wbs_stb_i;

	wbs_dato_proc:
	wbs_dat_o 	<= dat_o_r;
	wbs_acko_proc:
	wbs_ack_o	<= rx_data_r or data_valid_r;
	wbs_stallo_proc:
	wbs_stall_o	<= rx_data_r nor data_valid_r;
	wbs_cmdack_proc:
	cmd_ack 	<= cmd_ack_r;
	
	dram_cke_proc:
	dram_cke 	<= pll_locked;		-- When Pll Locked, clock is enabled
	dram_cs_proc:
	dram_cs_n 	<= not pll_locked;  -- Chip select is always active ('0') in normal operation
  
  --Counter process
  counter_proc : process(clk_i, rst) 
  begin
	if (rst = reset_polarity_g) then
	  wait_200us_cntr 	<= 0;	-- Wait 200us at init
	  rfsh_int_cntr 	<= 0;   -- Initiate a new refresh at reset
	  tRC_cntr 			<= 0;	-- tRC Delay (Row Cycle Time)
	  tRCD_tRP_tRSC_cntr<= 0;	-- tRCD Delay (RAS to CAS)
    elsif rising_edge(clk_i) then
		-- Wait 200us at init (Count 26667 clock cylces = 200 us)
		if (current_init_state = INIT_IDLE_ST) then
		  wait_200us_cntr <= init_200us_delay_c;
		elsif wait_200us_cntr > 0 then
		  wait_200us_cntr <= wait_200us_cntr - 1;
		end if;
		
		--  4096 refreshed per 64 ms = refresh every 2083 cycles
		if (current_state = REFRESH_WAIT_ST) then
		  do_refresh <= '0';
		  rfsh_int_cntr <= refresh_cycles_c;
		elsif (rfsh_int_cntr = 1) then
		  do_refresh <= '1'; --2083 cycles has been passed - issue refresh
		elsif rfsh_int_cntr > 0 then
		  rfsh_int_cntr <= rfsh_int_cntr - 1; 
		end if;
		
		--Time to wait after refresh
		if (current_state = REFRESH_ST or current_init_state = INIT_AUTO_REF_ST) then
		  tRC_cntr <= tRC_delay_c;
		elsif tRC_cntr > 0 then
		  tRC_cntr <= tRC_cntr - 1;
		end if;
		
		-- Time to wait after precharge / RAS to CAS delay / Mode Register
		if (current_state = ACT_ST or current_state = READ_BST_STOP_ST or current_state = WRITE_BST_STOP_ST 
			or current_init_state = INIT_PRECHARGE_ST or current_init_state = INIT_MODE_REG_ST) then
		  tRCD_tRP_tRSC_cntr <= tRCD_tRP_tRSC_delay_c;
		elsif tRCD_tRP_tRSC_cntr > 0 then
		  tRCD_tRP_tRSC_cntr <= tRCD_tRP_tRSC_cntr - 1;
		end if;
		
	end if;
  end process counter_proc;

  -- Init state change
  increment_init_state_proc : process (next_init_state, rst)
  begin
	if (rst = reset_polarity_g) then
		current_init_state <= INIT_IDLE_ST;
    else 
		current_init_state <= next_init_state;
    end if;
  end process increment_init_state_proc;


  -- Main state change
  increment_state_proc : process (next_state, rst)
  begin
	if (rst = reset_polarity_g) then
		current_state <= IDLE_ST;
    else 
		current_state <= next_state;
    end if;
  end process increment_state_proc;
  

  -- Init process: Page 15 on SDRam documentation.
  -- Refer to Simplified State Diagram, page 9, for better understanding
  -- 1) NOP input conditions for a minimum of 200us
  -- 2) Precharge command for all banks
  -- 3) After tRP (all banks become idle), issue 8 auto-refresh commands
  -- 4) Issue a mode register set commands
  init_state_proc : process (clk_i, rst) 
  begin
	if (rst = reset_polarity_g) then
		next_init_state		<= INIT_IDLE_ST;
		init_done 			<= '0';
		init_pre_cntr		<= 0;
    elsif rising_edge(clk_i) then
		case current_init_state is
		  when INIT_IDLE_ST =>		--Ready to start init / Init done
			if (init_done = '0') then
				next_init_state <= INIT_WAIT_200us_ST;
			else
				next_init_state <= INIT_IDLE_ST;
			end if;
		  
		  when INIT_WAIT_200us_ST => 	--Wait for 200us (step 1)
			if (wait_200us_cntr = conv_std_logic_vector(1,16)) then --200us has passed since init
				next_init_state <= INIT_PRECHARGE_ST;
			else 
				next_init_state <= INIT_WAIT_200us_ST;
			end if;
		  
		  when INIT_PRECHARGE_ST => 				--Precharge (Step 2)
			next_init_state <= INIT_WAIT_PRE_ST;
			
		  when INIT_WAIT_PRE_ST => 						--Wait 8 cycles (step 3)
			if (tRCD_tRP_tRSC_cntr = 1) then 			--tRP (Row Precharge Time)
				next_init_state <= INIT_AUTO_REF_ST; 	--Perform 8 auto refresh
			else
				next_init_state <= INIT_WAIT_PRE_ST; 	--Wait tRP
			end if;

		  when INIT_AUTO_REF_ST =>						--Auto Refresh
			next_init_state <= INIT_AUTO_REF_WAIT_ST;
			init_pre_cntr 	<= init_pre_cntr + 1; 		--Count 8 cycles for auto-refresh (step 3)
				
		  when INIT_AUTO_REF_WAIT_ST =>
			if (tRC_cntr = 1) then
				if (init_pre_cntr = 8) then 				--8 auto refresh has been issued
					next_init_state <= INIT_MODE_REG_ST;
				else                            
					next_init_state <= INIT_AUTO_REF_ST;	 --Another auto refresh cycle
				end if;
			else
				next_init_state <= INIT_AUTO_REF_WAIT_ST;
			end if;

		  when INIT_MODE_REG_ST => 					--initilize mode register
			next_init_state <= INIT_WAIT_MODE_REG_ST;
		  
		  when INIT_WAIT_MODE_REG_ST => 			--Issue mode register (Step 4)
			if (tRCD_tRP_tRSC_cntr = 1) then  		--tRSC
				next_init_state <= INIT_IDLE_ST; 	--Initilization has been done
				init_done 		<= '1';
			else
				next_init_state <= INIT_WAIT_MODE_REG_ST;
			end if;
		end case;
		init_st_o <= conv_std_logic_vector(init_states'pos(current_init_state), 4);
	end if;
  end process init_state_proc;


  -- Main controller:
  main_state_proc : process (clk_i, rst) 
  begin
	if (rst = reset_polarity_g) then
		next_state		<= IDLE_ST;
		oor_r 			<= '0';
	elsif rising_edge(clk_i) then
		case current_state is
		  when IDLE_ST =>
			if (init_done = '0') then 		--Init has not been done yet
				next_state <= IDLE_ST;
			elsif (do_refresh = '1') then 	--Refresh Command
				next_state <= REFRESH_ST;
			elsif (cmd_r = '1') then		--ACT command (Read / Write)
				address_r	<= wbs_adr_i; 	--Register start burst address
				we_i_r 		<= wbs_we_i;	--Register Write / Read command
				next_state 	<= ACT_ST;
				oor_r 		<= '0';			--Clear Out Of Range flag
			else                    
				next_state <= IDLE_ST;		--NOP
			end if;
		  
		  when REFRESH_ST =>				--Refresh diagram: Refer to page 40
			next_state <= REFRESH_WAIT_ST;	--Wait tRC

		  when REFRESH_WAIT_ST =>
			if (tRC_cntr = 1) then 			--Row Cycle Time: Time to wait between two ACT commands
				next_state <= IDLE_ST;
			else            
				next_state <= REFRESH_WAIT_ST;
			end if;

		  when ACT_ST =>					-- ACT Command, Negate RAS (RAS = '0')                         
			next_state 	<= WAIT_ACT_ST;
			if (blen_c-conv_integer(address_r(7 downto 0))) >= conv_integer(wbs_tga_i) + 1 then --Burst will not be cyclic (will not return to first colums)
				blen_cnt 	<= conv_integer(wbs_tga_i) + 1; --Burst length
				oor_r 		<= '0'; 										--In Range: column address
			else
				blen_cnt	<= blen_c-conv_integer(address_r(7 downto 0)); 	--Burst will be cut, and will be only untill end of line
				oor_r 		<= '1'; 										--Out Of Range: column address
			end if;
		  
		  when WAIT_ACT_ST =>
			if (tRCD_tRP_tRSC_cntr = 1) then		--RAS to CAS Delay has passed.
				if (we_i_r = '1') then 		
					next_state 	<= WRITE0_ST;		--Write Mode

				else                     	
					next_state 	<= READ0_ST;		--Read Mode
				end if;
			else                           
				next_state <= WAIT_ACT_ST;	--RAS to CAS delay has not passed yet
			end if;
		  
		  when WRITE0_ST =>					--Write State, Negate CAS (CAS = '0')
											--and start data burst
			if blen_cnt = 1 then 			--Only one data chunk
				next_state 	<= WRITE_BST_STOP_ST;
			else
				next_state 	<= WRITE1_ST;
			end if;
			blen_cnt 	<= blen_cnt - 1;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';

		  when WRITE1_ST =>					--Write state: Burst
			
			if blen_cnt = 1 then 			--Last data chunk
				next_state 	<= WRITE_BST_STOP_ST;
			else
				next_state	<= WRITE1_ST; 	--Continue Burst
			end if;
			blen_cnt 	<= blen_cnt - 1;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';
		  
		  when WRITE_BST_STOP_ST =>  		--Precharge (Also stops burst)
			wbs_err_o	<= oor_r;			--WISHBONE ERR_O flag will rise in case of OOR burst
			next_state 	<= WAIT_PRE_ST;
		  
		  when READ0_ST =>					--Command is being accepted by SDRAM
			next_state <= READ1_ST;

		  when READ1_ST =>					--Nothing happens (1 of 3)     
  			next_state <= READ2_ST;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';
		  
		  when READ2_ST =>					--Nothing happens (2 of 3)
			if blen_cnt <=1 then			--Only one data chunk are being read
				next_state <= READ_BST_STOP_ST;
			else
				next_state <= READ3_ST;
			end if;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';

		  when READ3_ST =>					--Nothing happens (3 of 3)
			if blen_cnt <=2 then			--Only two data chunks are being read
				next_State <= READ_BST_STOP_ST;
			else
				next_state <= READ4_ST;
			end if;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';

  		  when READ4_ST =>					--Data delay, since 'dram_dq' data comes right after clock's rising edge
			if blen_cnt <=3 then			--Only three data chunks are being read
				next_State <= READ_BST_STOP_ST;
			else
				next_state <= READ5_ST;
			end if;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';

		  when READ5_ST =>					--Read data (burst)
			if blen_cnt <= 4 then 			--Precharge Command (for Burst Stop and Precharge) is required
				next_state 	<= READ_BST_STOP_ST;
			else
				next_state 	<= READ5_ST; 	--Continue burst read
			end if;
			blen_cnt 	<= blen_cnt - 1;
			--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
			--address_r	<= address_r + '1';

		  when READ_BST_STOP_ST =>			--Precharge (Also stops burst)
			if blen_cnt > 0 then
				blen_cnt 	<= blen_cnt - 1;
				--REMOVE ME: (For SDRAM_MODEL Simulation only. This line does has no influence on the SDRAM itself)
				--address_r	<= address_r + '1';
			end if;
			
			next_state <= WAIT_PRE_ST;
		  
		  when WAIT_PRE_ST =>				--Wait tRP - Time after precharge.
											--Refer to Diagram at page 62 - tRP
			if blen_cnt > 0 then			
				blen_cnt 	<= blen_cnt - 1; --Relevant only after read command
			end if;
											
			if (tRCD_tRP_tRSC_cntr <= 1) then
				next_state <= IDLE_ST;
			else                          
				next_state <= WAIT_PRE_ST;
			end if;       

		end case;
		main_st_o <= conv_std_logic_vector(main_states'pos(current_state), 4);
	end if;
  end process main_state_proc;

  
  -- Command has been acknowledged / done
  cmd_ack_proc : process (clk_i, rst) 
  begin
	if (rst = reset_polarity_g) then
		cmd_done 	<= '0';
		cmd_ack_r 	<= '0';
	elsif rising_edge(clk_i) then
		--Read / Write command has been accomplished, and precharge is beginning.
		--Ready for next command.
		if (current_state = READ_BST_STOP_ST or current_state = WRITE_BST_STOP_ST) then 
			cmd_done <= '1';
		elsif (current_state = WAIT_PRE_ST) then
			cmd_done <= '0';
		end if;
	
		if (current_state = WAIT_ACT_ST) then
			cmd_ack_r <= '1';
		else
			cmd_ack_r <= '0';
		end if;
	end if;
  end process cmd_ack_proc;

  
  -- Transmit / Recieve data
  data_proc : process (clk_i, rst) 
  begin
	if (rst = reset_polarity_g) then
	  dat_o_r 		<= (others => '0');
	  dram_dq_r 	<= (others => '0');
	  oe_r			<= '0';
	  rx_data_r		<= '0';
   	  data_valid_r	<= '0';
	elsif rising_edge(clk_i) then
		if (current_state = WRITE0_ST or current_state = WRITE1_ST) then --Transmit data
		  dram_dq_r <= wbs_dat_i; 
		  oe_r 		<= '1';
		elsif (current_state = WAIT_ACT_ST) and (tRCD_tRP_tRSC_cntr = 1) and (we_i_r = '1') then	--Prepare to transmit data
		  rx_data_r	<= '1';
		elsif (current_state = READ5_ST
			or (current_state = READ_BST_STOP_ST and blen_cnt > 0)
			or (current_state = WAIT_PRE_ST and blen_cnt > 0 and we_i_r = '0')	) then
		  -- According to diagrams, data should be read in READ3_ST, though since
		  -- 'dram_dq' is valid AFTER clock's rising edge - data can be read in one state delay.
		  dat_o_r <= dram_dq;
		  dram_dq_r <= (others => 'Z'); --Switch output to HighZ, so data can be read through the bidirectional line
		  oe_r <= '0';
		  data_valid_r <= '1';
		elsif (current_state = READ_BST_STOP_ST or (current_state = WAIT_PRE_ST and we_i_r = '0')) and (blen_cnt = 1) then --No data is being read at the moment
 		  dat_o_r <= dram_dq;
		  dram_dq_r <= (others => 'Z');
		  oe_r <= '0';
		else 
		  data_valid_r 	<= '0';
		  rx_data_r		<= '0';
		  dram_dq_r 	<= (others => 'Z');
		  oe_r 			<= '0';
		end if;
	end if;
  end process data_proc;

  
  -- Address procedure
  addr_proc : process (clk_i, rst) 
  begin
	if (rst = reset_polarity_g) then
		dram_addr_r		<= (others => '0');
		dram_bank_r		<= (others => '0');
		
	elsif rising_edge(clk_i) then
		if (current_init_state = INIT_MODE_REG_ST) then	--Mode register
		  dram_addr_r <= mode_register_c;
		elsif (current_init_state = INIT_PRECHARGE_ST) then --Precharge all banks
		  dram_addr_r <= "010000000000";  -- precharge all, see page 18 in SDRAM documentation (A10 = '1', others = don't care)
		elsif (current_state = ACT_ST) then	--ACT command (Write / Read) - RAS strobe
		  dram_addr_r <= address_r(19 downto 8);
		  dram_bank_r <= address_r(21 downto 20);
		elsif (current_state = WRITE0_ST or current_state = READ0_ST) then
		  -- During CAS strobe, A10='1' indicates Auto Precharge.
		  -- Reminder: Column address width is 8 bits (7 downto 0).
		  -- Bits A11, A9, A8 values are irrelevant here.
		  dram_addr_r <= "0000" & address_r(7 downto 0); --Write /read without auto-precharge
		  dram_bank_r <= address_r(21 downto 20);
		else
		  --FOR SDRAM_MODEL Simulation only: 
		  --dram_addr_r <= "0000" & address_r(7 downto 0); --Write /read without auto-precharge
		  --dram_bank_r <= address_r(21 downto 20);
		  
		  --TODO: After removing SDRAM_MODEL Simulation lines, uncommand these two lines
		  dram_addr_r <= (others => '0');
		  dram_bank_r <= "00";
		end if;
	end if;
  end process addr_proc;

  
  -- RAS, CAS and WE signals
  sig_proc : process (clk_i, rst)
  begin
	if (rst = reset_polarity_g) then
		--NOP Command
		dram_ras_n_r	<= '1';
		dram_cas_n_r	<= '1';
		dram_we_n_r		<= '1';

		--Mask Data
		dram_ldqm		<= '1';
		dram_udqm		<= '1';
		
	elsif rising_edge(clk_i) then
		-- Refer to Page 10 in SDRAM Documentation for a table with all commands.
		
		--RAS strobes in the following cases:
		-- (1) Precharge
		-- (2) Mode Register
		-- (3) Auto Refresh
		-- (4) ACT command (Read / Write)
		if (current_init_state = INIT_PRECHARGE_ST or current_init_state = INIT_MODE_REG_ST 
			or current_state = REFRESH_ST or current_state = ACT_ST or current_init_state = INIT_AUTO_REF_ST
			or current_state = WRITE_BST_STOP_ST or current_state = READ_BST_STOP_ST) then
			dram_ras_n_r <= '0';
		else
			dram_ras_n_r <= '1';
		end if;
		
		--CAS strobes in the following cases:
		-- (1) Start of read cycle
		-- (2) Start of write cycle
		-- (3) Refresh / Auto refresh cycle
		-- (4) Mode Register
		if (current_state = READ0_ST or current_state = WRITE0_ST 
			or current_state = REFRESH_ST or current_init_state = INIT_MODE_REG_ST 
			or current_init_state = INIT_AUTO_REF_ST) then
			dram_cas_n_r <= '0';
		else
			dram_cas_n_r <= '1';
		end if;
		
		-- WE (Write Enable) strobes in the following cases:
		-- (1) Precharge
		-- (2) Mode Register
		-- (3) Write
		if (current_init_state = INIT_PRECHARGE_ST or current_state = WRITE0_ST 
			or current_init_state = INIT_MODE_REG_ST 
			or current_state = WRITE_BST_STOP_ST or current_state = READ_BST_STOP_ST) then
			dram_we_n_r <= '0';
		else
			dram_we_n_r <= '1';
		end if;

		--LDQM, UDQM strobes in the following cases:
		-- (1) Init
		-- (2) Write burst stop (BST command)
		if (current_init_state = INIT_IDLE_ST) then
			if (init_done = '0') then
				dram_ldqm	<= '1'; --Data masking is necessary during init (Refer to page 33)
				dram_udqm	<= '1'; --Data masking is necessary during init
			else
				dram_ldqm 	<= '0';	--Init is done - cancel data masking
				dram_udqm 	<= '0';	--Init is done - cancel data masking
			end if;
		end if;
		if (current_state = WRITE_BST_STOP_ST) then --Mask data for Burst Stop (PRE command for write burst termination)
			dram_ldqm		<= '1'; --Data masking is necessary during write burst stop
			dram_udqm		<= '1'; --Data masking is necessary during write burst stop
		elsif (current_state = WAIT_PRE_ST) then --Unmask data, after Precharge command of Write Burst Stop
			dram_ldqm <= '0';	--PRE command has ended - cancel data masking
			dram_udqm <= '0';	--PRE command has ended - cancel data masking
		end if;
	end if;
  end process sig_proc;

end architecture rtl_sdram_controller;