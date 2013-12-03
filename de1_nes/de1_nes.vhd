library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity de1_nes is 
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
    signal dbg_wait_a58_branch_next     : out std_logic;
    
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

    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);

--    signal dbg_disp_nt, dbg_disp_attr : out std_logic_vector (7 downto 0);
--    signal dbg_disp_ptn_h, dbg_disp_ptn_l : out std_logic_vector (15 downto 0);
    signal dbg_ppu_addr_we_n    : out std_logic;
    signal dbg_ppu_clk_cnt          : out std_logic_vector(1 downto 0);
    
    
    
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
end de1_nes;

architecture rtl of de1_nes is
    component mos6502
        generic (   dsize : integer := 8;
                    asize : integer :=16
                );
        port (  
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : out std_logic_vector(7 downto 0);
    signal dbg_exec_cycle      : out std_logic_vector (5 downto 0);
    signal dbg_ea_carry     : out std_logic;
    signal dbg_wait_a58_branch_next     : out std_logic;
--    signal dbg_index_bus    : out std_logic_vector(7 downto 0);
--    signal dbg_acc_bus      : out std_logic_vector(7 downto 0);
    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;
    signal dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w    : out std_logic_vector (7 downto 0);
    
                input_clk   : in std_logic; --phi0 input pin.
                rdy         : in std_logic;
                rst_n       : in std_logic;
                irq_n       : in std_logic;
                nmi_n       : in std_logic;
                dbe         : in std_logic;
                r_nw        : out std_logic;
                phi1        : out std_logic;
                phi2        : out std_logic;
                addr        : out std_logic_vector ( asize - 1 downto 0);
                d_io        : inout std_logic_vector ( dsize - 1 downto 0)
        );
    end component;

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                mem_clk     : out std_logic;
                vga_clk     : out std_logic
            );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                mem_clk     : in std_logic;
                R_nW        : in std_logic; 
                addr        : in std_logic_vector (abus_size - 1 downto 0);
                d_io        : in std_logic_vector (dbus_size - 1 downto 0);
                rom_ce_n    : out std_logic;
                ram_ce_n    : out std_logic;
                ppu_ce_n    : out std_logic;
                apu_ce_n    : out std_logic
    );
    end component;

    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  
                clk               : in std_logic;
                ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr              : in std_logic_vector (abus_size - 1 downto 0);
                d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component prg_rom
        generic (abus_size : integer := 15; dbus_size : integer := 8);
        port (
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component ppu
    port (  
    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);
    signal dbg_disp_nt, dbg_disp_attr : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : out std_logic_vector (15 downto 0);
    signal dbg_ppu_addr_we_n    : out std_logic;
    signal dbg_ppu_clk_cnt          : out std_logic_vector(1 downto 0);
    
            clk         : in std_logic;
            mem_clk     : in std_logic;
            sdram_clk   : in std_logic;
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

    component v_address_decoder
    generic (abus_size : integer := 14; dbus_size : integer := 8);
        port (  clk         : in std_logic; 
                mem_clk     : in std_logic;
                rd_n        : in std_logic;
                wr_n        : in std_logic;
                ale         : in std_logic;
                v_addr      : in std_logic_vector (13 downto 0);
                v_data      : in std_logic_vector (7 downto 0);
                nt_v_mirror : in std_logic;
                pt_ce_n     : out std_logic;
                nt0_ce_n    : out std_logic;
                nt1_ce_n    : out std_logic
            );
    end component;

    component chr_rom
        generic (abus_size : integer := 13; dbus_size : integer := 8);
        port (  
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0);
                nt_v_mirror     : out std_logic
        );
    end component;

    component ls373
        generic (
            dsize : integer := 8
        );
        port (  c         : in std_logic;
                oc_n      : in std_logic;
                d         : in std_logic_vector(dsize - 1 downto 0);
                q         : out std_logic_vector(dsize - 1 downto 0)
        );
    end component;

    component apu
        port (  clk         : in std_logic;
                ce_n        : in std_logic;
                rst_n       : in std_logic;
                r_nw        : inout std_logic;
                cpu_addr    : inout std_logic_vector (15 downto 0);
                cpu_d       : inout std_logic_vector (7 downto 0);
                rdy         : out std_logic
        );
    end component;

    component pll_clk_gen
        PORT
        (
            inclk0		: IN STD_LOGIC  := '0';
            c0		    : OUT STD_LOGIC ;
            locked		: OUT STD_LOGIC 
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
    constant vram_size14    : integer := 14;

    constant ram_2k : integer := 11;      --2k = 11 bit width.
    constant rom_32k : integer := 15;     --32k = 15 bit width.
    constant rom_4k : integer := 12;     --4k = 12 bit width. (for test use)
    constant vram_1k : integer := 10;      --1k = 10 bit width.
    constant chr_rom_8k : integer := 13;     --32k = 15 bit width.

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal mem_clk  : std_logic;
    signal vga_out_clk   : std_logic;
    signal sdram_clk : std_logic;
    signal sdram_clk_locked : std_logic;

    signal rdy, irq_n, nmi_n, dbe, r_nw : std_logic;
    signal phi1, phi2 : std_logic;
    signal addr : std_logic_vector( addr_size - 1 downto 0);
    signal d_io : std_logic_vector( data_size - 1 downto 0);

    signal rom_ce_n : std_logic;
    signal ram_ce_n : std_logic;
    signal ram_oe_n : std_logic;
    signal ppu_ce_n : std_logic;
    signal apu_ce_n : std_logic;

    signal rd_n     : std_logic;
    signal wr_n     : std_logic;
    signal ale      : std_logic;
    signal vram_ad  : std_logic_vector (7 downto 0);
    signal vram_a   : std_logic_vector (13 downto 8);
    signal v_addr   : std_logic_vector (13 downto 0);
    signal nt_v_mirror  : std_logic;
    signal pt_ce_n  : std_logic;
    signal nt0_ce_n : std_logic;
    signal nt1_ce_n : std_logic;

    -- SDRAM signals to Read/Write interface
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

    signal dbg_disp_nt, dbg_disp_attr : std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : std_logic_vector (15 downto 0);
    signal dbg_pcl, dbg_pch : std_logic_vector(7 downto 0);
    signal dbg_stat_we_n    : std_logic;
    signal dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w    : std_logic_vector (7 downto 0);

begin

    irq_n <= '0';
    vga_clk <= vga_out_clk;

    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, mem_clk, vga_out_clk);

    --mos 6502 cpu instance
    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (
    dbg_instruction,
    dbg_int_d_bus,
    dbg_exec_cycle,
    dbg_ea_carry,
    dbg_wait_a58_branch_next,
 --   dbg_index_bus,
 --   dbg_acc_bus,
    dbg_status,
    dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc,
    dbg_dec_oe_n,
    dbg_dec_val,
    dbg_int_dbus,
--    dbg_status_val    ,
    dbg_stat_we_n    ,
    dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w,

                cpu_clk, '1', --rdy, -----for testing...
                rst_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, d_io);

    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
        port map (phi2, mem_clk, r_nw, addr, d_io, rom_ce_n, ram_ce_n, ppu_ce_n, apu_ce_n);

    --main ROM/RAM instance
--    prg_rom_inst : prg_rom generic map (rom_32k, data_size)
--            port map (mem_clk, rom_ce_n, addr(rom_32k - 1 downto 0), d_io);

--    prg_rom_inst : prg_rom generic map (rom_4k, data_size)
--            port map (mem_clk, rom_ce_n, addr(rom_4k - 1 downto 0), d_io);
--
--    ram_oe_n <= not R_nW;
--    prg_ram_inst : ram generic map (ram_2k, data_size)
--            port map (mem_clk, ram_ce_n, ram_oe_n, R_nW, addr(ram_2k - 1 downto 0), d_io);

    --nes ppu instance
    ppu_inst : ppu 
        port map (
            dbg_ppu_ce_n    ,
            dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status, dbg_ppu_addr, 
            dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y,
            dbg_disp_nt, dbg_disp_attr, dbg_disp_ptn_h, dbg_disp_ptn_l ,
            dbg_ppu_addr_we_n    ,
            dbg_ppu_clk_cnt          ,
                
                ppu_clk, mem_clk, sdram_clk, ppu_ce_n, rst_n, r_nw, addr(2 downto 0), d_io, 
                nmi_n, rd_n, wr_n, ale, vram_ad, vram_a,
                vga_out_clk, h_sync_n, v_sync_n, r, g, b,
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

    ppu_addr_decoder : v_address_decoder generic map (vram_size14, data_size) 
        port map (ppu_clk, mem_clk, rd_n, wr_n, ale, v_addr, vram_ad, 
                nt_v_mirror, pt_ce_n, nt0_ce_n, nt1_ce_n);

    ---VRAM/CHR ROM instances
    v_addr (13 downto 8) <= vram_a;

    --transparent d-latch
    vram_latch : ls373 generic map (data_size)
                port map(ale, '0', vram_ad, v_addr(7 downto 0));

    vchr_rom : chr_rom generic map (chr_rom_8k, data_size)
            port map (mem_clk, pt_ce_n, v_addr(chr_rom_8k - 1 downto 0), vram_ad, nt_v_mirror);

    --name table/attr table
    vram_nt0 : ram generic map (vram_1k, data_size)
            port map (mem_clk, nt0_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    vram_nt1 : ram generic map (vram_1k, data_size)
            port map (mem_clk, nt1_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

--    --APU/DMA instance
--    apu_inst : apu
--        port map (cpu_clk, apu_ce_n, rst_n, r_nw, addr, d_io, rdy);

    pll_inst : pll_clk_gen
        PORT map (   base_clk, sdram_clk, sdram_clk_locked );

    dram_clk <= sdram_clk;
    sdram_ctl_inst : sdram_controller
    port map (
        --Clocks and Reset 
		sdram_clk, 
        rst_n, 
        sdram_clk_locked,
        
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

    dbg_cpu_clk <= cpu_clk;
    dbg_ppu_clk <= ppu_clk;
    dbg_mem_clk <= mem_clk;
    dbg_r_nw <= r_nw;
    dbg_addr <= addr;
    dbg_d_io <= d_io;
    dbg_vram_ad  <= vram_ad ;
    dbg_vram_a   <= vram_a  ;


end rtl;

